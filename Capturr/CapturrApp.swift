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
    private let container: ModelContainer = SharedModelContainer()
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var profileViewModel = ProfileViewModel()
    // Strong reference so the worker lives for the session
    @State private var syncManager: SyncManager?
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showingOnboarding: Bool = false

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
            .onAppear {
                if !hasSeenOnboarding {
                    showingOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView(viewModel: profileViewModel)
                    .onDisappear {
                        hasSeenOnboarding = true
                    }
            }
        }
        .modelContainer(container)
    }
}
