//
//  CaptureApp.swift
//  Capturr
//
//  Created by Paul Griffiths on 6/8/25.
//

import SwiftUI
import SwiftData

@main
struct CaptureApp: App {
    private let container: ModelContainer = {
        do { return try ModelContainer(for: OutboxItem.self, UserProfile.self) }
        catch { fatalError("Failed to create ModelContainer: \(error)") }
    }()
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var profileViewModel = ProfileViewModel()

    // Strong reference so the worker lives for the session
    @State private var syncManager: SyncManager?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileViewModel)
                .task {
                    if syncManager == nil {
                        syncManager = SyncManager(modelContext: container.mainContext)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        syncManager?.kickQueue()
                    }
                }
        }
        .modelContainer(container)
    }
}
