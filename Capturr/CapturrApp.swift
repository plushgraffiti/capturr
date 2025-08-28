//
//  CapturrApp.swift
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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileViewModel)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active,
                       let g = profileViewModel.graphName, !g.isEmpty,
                       let t = profileViewModel.apiToken, !t.isEmpty {
                        let worker = SyncWorker(modelContext: modelContext)
                        worker.syncPendingItems()
                    }
                }
        }
        .modelContainer(for: [OutboxItem.self, UserProfile.self])
        
    }
}
