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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var profileViewModel = ProfileViewModel()
    @Environment(\.modelContext) private var modelContext

    // Strong reference so the worker lives for the session
    @State private var syncManager: SyncManager?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileViewModel)
                .task {
                    if syncManager == nil {
                        syncManager = SyncManager(modelContext: modelContext)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        syncManager?.kickQueue()
                    }
                }
        }
        .modelContainer(for: [OutboxItem.self, UserProfile.self])
    }
}
