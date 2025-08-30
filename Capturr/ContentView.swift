//
//  ContentView.swift
//  Capturr
//
//  Created by Paul Griffiths on 6/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.modelContext) private var modelContext
    
    private var resolvedScheme: ColorScheme? {
        guard profileViewModel.isProfileReady else { return nil }
        switch profileViewModel.appAppearance {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
        }
    }
    
    var body: some View {
        TabView() {
            CaptureHome()
                .tabItem { Label("Capture", systemImage: "plus.app") }

            HistoryHome()
                .tabItem { Label("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90") }
            
           

            SettingsHome()
                .tabItem { Label("Settings", systemImage: "gear") }

        }
        .onAppear {
            profileViewModel.modelContext = modelContext
            initializeProfile(using: modelContext)
        }
        .preferredColorScheme(resolvedScheme)
    }

    private func initializeProfile(using modelContext: ModelContext) {
        guard profileViewModel.profileManager == nil else { return }

        let manager = ProfileManager(modelContext: modelContext)
        profileViewModel.profileManager = manager

        do {
            let deviceID = ProfileManager.deviceUUID
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { $0.id == deviceID }
            )

            let profiles = try modelContext.fetch(descriptor)

            if let profile = profiles.first {
                profileViewModel.updateViewModel(with: profile)
            } else {
                let newProfile = UserProfile(id: deviceID)
                modelContext.insert(newProfile)
                profileViewModel.updateViewModel(with: newProfile)
                try modelContext.save()
                print("🆕 Created new profile")
            }
        } catch {
            print("❌ Failed to initialize profile: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .environment(\.locale, .init(identifier: "en"))
        .environmentObject(ProfileViewModel())
}
