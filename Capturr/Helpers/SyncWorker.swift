//
//  SyncWorker.swift
//  Capturr
//
//  Created by Paul Griffiths on 7/8/25.
//

import Foundation
import SwiftData

class SyncWorker {
    private let modelContext: ModelContext
    private static var inFlight: Set<UUID> = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

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
        if let page = profile.customLocation?.trimmingCharacters(in: .whitespacesAndNewlines), !page.isEmpty {
            return .page(page)
        }
        // Fallback to Daily Notes if custom is missing
        return .dailyNote
    }

    private func decoratedContent(for item: OutboxItem, using profile: UserProfile) -> String {
        var suffixParts: [String] = []

        if profile.addTimestamp {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "HH:mm" // 24-hour format
            let ts = item.stampAt ?? Date()
            suffixParts.append(df.string(from: ts))
        }

        if let tagRaw = profile.defaultTag?.trimmingCharacters(in: .whitespacesAndNewlines), !tagRaw.isEmpty {
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

    func syncPendingItems() {
        guard let ctx = configuredContext() else {
            print("[SyncWorker] Skipping sync: graphName/apiToken not configured")
            return
        }

        let pendingStatus = SyncStatus.pending.rawValue
        let descriptor = FetchDescriptor<OutboxItem>(
            predicate: #Predicate<OutboxItem> { item in
                item.status == pendingStatus
            }
        )

        guard let items = try? modelContext.fetch(descriptor) else {
            print("Failed to fetch pending items")
            return
        }

        let location = resolveLocation(from: ctx.profile)
        let now = Date()
        let filtered = items.filter { item in
            let status = SyncStatus(rawValue: item.status)
            let hard = item.hardError ?? false
            if hard { return false }
            if status == .inProgress || status == .success { return false }
            if let next = item.nextAttemptAt, next > now { return false }
            if Self.inFlight.contains(item.id) { return false }
            return true
        }
        for item in filtered {
            sync(item, using: ctx.api, profile: ctx.profile, location: location)
        }
    }

    func sync(_ item: OutboxItem) {
        guard let ctx = configuredContext() else {
            print("[SyncWorker] Skipping single-item sync: graphName/apiToken not configured")
            return
        }
        let status = SyncStatus(rawValue: item.status)
        if status == .success || status == .inProgress { return }
        if Self.inFlight.contains(item.id) { return }
        let location = resolveLocation(from: ctx.profile)
        sync(item, using: ctx.api, profile: ctx.profile, location: location)
    }

    private func sync(_ item: OutboxItem, using api: RoamAPI, profile: UserProfile, location: RoamLocation) {
        print("[SyncWorker] Starting sync for item:", item.id)

        // Prevent double-send and mark in-progress
        if Self.inFlight.contains(item.id) { return }
        Self.inFlight.insert(item.id)

        item.status = SyncStatus.inProgress.rawValue
        item.lastAttemptAt = Date()
        if profile.addTimestamp && item.stampAt == nil {
            item.stampAt = item.lastAttemptAt
        }
        try? modelContext.save()

        let send = (item.type == .todo) ? api.sendTodoBlock : api.sendNoteBlock

        let prepared = decoratedContent(for: item, using: profile)

        item.attemptCount += 1
        try? modelContext.save()

        send(prepared, location) { [weak self] result in
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
            }
        }
    }
}
