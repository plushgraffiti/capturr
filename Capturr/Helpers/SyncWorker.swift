//
//  SyncWorker.swift
//  Capturr
//
//  Created by Paul Griffiths on 7/8/25.
//

import Foundation
import SwiftData
import Network
import OSLog

final class SyncWorker {
    // MARK: - State
    private let modelContext: ModelContext
    private static var inFlight: Set<UUID> = []

    // MARK: - Logging / Networking
    private let logger = Logger(subsystem: "com.capturr.app", category: "SyncWorker")
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "SyncWorker.Network")

    // MARK: - Loop
    private var retryLoop: Task<Void, Never>?
    private let tickIntervalSeconds: UInt64 = 10
    private let maxConcurrentSends: Int = 1
    private var monitorStarted = false
    private let minRetryGapSeconds: TimeInterval = 5 // Short-gap retry for .inProgress

    // MARK: - Date Formatting (cached)
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "HH:mm"
        return df
    }()

    // MARK: - Init / Deinit
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        start()
    }

    deinit {
        logger.info("SyncWorker deinit — stopping monitors")
        retryLoop?.cancel()
        pathMonitor.cancel()
    }

    // MARK: - Startup
    private func start() {
        if !monitorStarted {
            pathMonitor.pathUpdateHandler = { [weak self] path in
                guard let self else { return }
                if path.status == .satisfied {
                    self.logger.info("NWPathMonitor: online — kicking queue")
                    self.kick()
                } else {
                    self.logger.info("NWPathMonitor: offline")
                }
            }
            pathMonitor.start(queue: pathQueue)
            monitorStarted = true
        }
        startRetryLoop()
    }

    private func startRetryLoop() {
        retryLoop?.cancel()
        retryLoop = Task { [weak self] in
            guard let self else { return }
            self.logger.info("Retry loop started (every \(self.tickIntervalSeconds)s)")
            while !Task.isCancelled {
                await MainActor.run { [weak self] in
                    self?.syncPendingItems()
                }
                try? await Task.sleep(nanoseconds: tickIntervalSeconds * 1_000_000_000)
            }
        }
    }

    private func kick() {
        Task { [weak self] in
            await MainActor.run { [weak self] in
                self?.syncPendingItems()
            }
        }
    }

    // MARK: - Configuration helpers
    private func configuredContext() -> (api: RoamAPI, profile: UserProfile)? {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first,
              let graph = profile.graphName, !graph.isEmpty,
              let token = profile.apiToken, !token.isEmpty else {
            return nil
        }
        return (RoamAPI(graphName: graph, apiToken: token), profile)
    }

    private func resolveLocation(from profile: UserProfile) -> RoamLocation {
        if profile.useDailyNotes { return .dailyNote }
        if let page = profile.customLocation?.trimmingCharacters(in: .whitespacesAndNewlines),
           !page.isEmpty {
            return .page(page)
        }
        return .dailyNote
    }

    private func decoratedContent(for item: OutboxItem, using profile: UserProfile) -> String {
        var suffixParts: [String] = []

        if profile.addTimestamp {
            let ts = item.stampAt ?? Date()
            suffixParts.append(Self.timeFormatter.string(from: ts))
        }
        if let tagRaw = profile.defaultTag?.trimmingCharacters(in: .whitespacesAndNewlines),
           !tagRaw.isEmpty {
            suffixParts.append(tagRaw)
        }

        guard !suffixParts.isEmpty else { return item.content }
        return item.content + " " + suffixParts.joined(separator: " ")
    }

    private func backoffDelay(for attempt: Int, statusCode: Int?) -> TimeInterval {
        // Hard failures: short-circuit; actual stop handled separately
        if let code = statusCode, code == 401 || code == 403 { return 60 } // 1 min placeholder
        // Exponential backoff capped at ~64s with jitter
        let capped = min(attempt, 6)
        let base = pow(2.0, Double(capped)) // 2,4,8,16,32,64
        let jitter = Double.random(in: 0...1)
        return (base + jitter)
    }

    // MARK: - Queue processing
    @MainActor
    func syncPendingItems() {
        if pathMonitor.currentPath.status != .satisfied {
            logger.debug("syncPendingItems: skip (offline)")
            return
        }
        guard let ctx = configuredContext() else {
            logger.debug("syncPendingItems: skip (not configured)")
            return
        }

        // Fetch PENDING + IN_PROGRESS to allow self-healing of stuck items
        let pending = SyncStatus.pending.rawValue
        let inProgress = SyncStatus.inProgress.rawValue
        let descriptor = FetchDescriptor<OutboxItem>(
            predicate: #Predicate<OutboxItem> { item in
                item.status == pending || item.status == inProgress
            }
        )

        guard let items = try? modelContext.fetch(descriptor) else { return }
        logger.debug("syncPendingItems: fetched=\(items.count)")

        let location = resolveLocation(from: ctx.profile)
        let now = Date()

        let filtered = items.filter { item in
            // Never pick up items that are currently being sent
            if Self.inFlight.contains(item.id) { return false }

            // Skip hard errors until credentials/settings change
            if item.hardError ?? false { return false }

            // Pending items: send if due (or no schedule)
            if item.status == pending {
                if let next = item.nextAttemptAt { return next <= now }
                return true
            }

            // In-progress items: retry after a small gap since last attempt
            if item.status == inProgress {
                let last = item.lastAttemptAt ?? .distantPast
                return last <= now.addingTimeInterval(-minRetryGapSeconds)
            }

            return false
        }

        logger.debug("syncPendingItems: candidates=\(filtered.count)")

        for item in filtered.prefix(maxConcurrentSends) {
            // Safety valve: clear stale in-flight marker before retry
            Self.inFlight.remove(item.id)
            sync(item, using: ctx.api, profile: ctx.profile, location: location)
        }
    }

    @MainActor
    func sync(_ item: OutboxItem) {
        guard let ctx = configuredContext() else { return }
        let status = SyncStatus(rawValue: item.status)
        if status == .success || status == .inProgress { return }
        if Self.inFlight.contains(item.id) { return }
        let location = resolveLocation(from: ctx.profile)
        sync(item, using: ctx.api, profile: ctx.profile, location: location)
    }

    private func sync(_ item: OutboxItem, using api: RoamAPI, profile: UserProfile, location: RoamLocation) {
        // Prevent double-send and mark in-progress
        if Self.inFlight.contains(item.id) { return }
        Self.inFlight.insert(item.id)

        item.status = SyncStatus.inProgress.rawValue
        item.lastAttemptAt = Date()
        if profile.addTimestamp && item.stampAt == nil {
            item.stampAt = item.lastAttemptAt
        }
        try? modelContext.save()

        let rawNest = profile.customBlock?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nestUnderArg: String? = {
            guard let s = rawNest, !s.isEmpty else { return nil }
            return s
        }()

        let prepared = decoratedContent(for: item, using: profile)

        item.attemptCount += 1
        try? modelContext.save()

        let handle: (Result<Void, Error>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    item.status = SyncStatus.success.rawValue
                    item.sentAt = Date()
                    item.lastError = "OK"
                    item.nextAttemptAt = nil
                    item.hardError = false
                case .failure(let error):
                    item.status = SyncStatus.pending.rawValue
                    item.lastError = error.localizedDescription
                    var statusCode: Int? = nil
                    if let apiErr = error as? RoamAPIError { statusCode = apiErr.statusCode }
                    if let code = statusCode, code == 401 || code == 403 {
                        // Treat as hard error until credentials change
                        item.hardError = true
                        item.nextAttemptAt = nil
                    } else {
                        let delay = self?.backoffDelay(for: item.attemptCount, statusCode: statusCode) ?? 0
                        item.nextAttemptAt = Date().addingTimeInterval(delay)
                    }
                }
                Self.inFlight.remove(item.id)
                try? self?.modelContext.save()
                self?.kick()
            }
        }

        if item.type == .todo {
            api.sendTodoBlock(prepared, location, nestUnder: nestUnderArg, completion: handle)
        } else {
            api.sendNoteBlock(prepared, location, nestUnder: nestUnderArg, completion: handle)
        }
    }
}
