//
//  SettingsHome.swift
//  Capturr
//
//  Created by Paul Griffiths on 6/8/25.
//

import SwiftUI
import SwiftData

struct SettingsHome: View {
    @Environment(\.modelContext) private var context
    @Environment(\.locale) private var locale
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.openURL) private var openURL
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showResetOnboardingAlert: Bool = false
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    
                    NavigationLink {
                        SettingGraph(viewModel: profileViewModel)
                    } label: {
                        HStack {
                            Label("Graph Name", systemImage: "chart.bar.xaxis").foregroundColor(.primary)
                            Spacer()
                            Text("\(profileViewModel.graphName ?? "Not set")").foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        SettingApiToken(viewModel: profileViewModel)
                    } label: {
                        HStack {
                            Label("API Token", systemImage: "key").foregroundColor(.primary)
                            Spacer()
                            Text(profileViewModel.apiToken?.isEmpty == false ? "Saved" : "Not set")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                } header: {
                    Text("Roam Research")
                }
                
                Section {
                    
                    NavigationLink {
                        SettingLocation(viewModel: profileViewModel)
                    } label: {
                        HStack {
                            Label("Default Location", systemImage: "list.bullet.rectangle.portrait").foregroundColor(.primary)
                            Spacer()
                            Text(
                                profileViewModel.useDailyNotes
                                ? "Daily Notes"
                                : (profileViewModel.customLocation?.isEmpty == false ? profileViewModel.customLocation! : "Daily Notes")
                            )
                            .foregroundColor(.secondary)
                                
                        }
                    }
                    
                    NavigationLink {
                        SettingBlock(viewModel: profileViewModel)
                    } label: {
                        HStack {
                            Label("Default Block", systemImage: "list.bullet.indent").foregroundColor(.primary)
                            Spacer()
                            Text(profileViewModel.customBlock?.isEmpty == false ? "Set" : "Not set")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        SettingTag(viewModel: profileViewModel)
                    } label: {
                        HStack {
                            Label("Default Tag", systemImage: "tag").foregroundColor(.primary)
                            Spacer()
                            Text(profileViewModel.defaultTag?.isEmpty == false ? "Set" : "Not set")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $profileViewModel.addTimestamp) {
                        Label("Append Time", systemImage: "clock")
                            .foregroundColor(.primary)
                    }
                    .onChange(of: profileViewModel.addTimestamp) {
                        try? profileViewModel.saveChanges(context: context)
                    }
                    
                } header: {
                    Text("Capture Preferences")
                }
             
                Section {
                    
                    Toggle(isOn: $profileViewModel.shareFormatLinks) {
                        Label("Format URLs for Roam", systemImage: "link")
                            .foregroundColor(.primary)
                    }
                    .onChange(of: profileViewModel.shareFormatLinks) {
                        try? profileViewModel.saveChanges(context: context)
                    }
                    
                } header: {
                    Text("Share Preferences")
                }
                
                Section {
                    NavigationLink {
                        SettingAppearance()
                    } label: {
                        HStack {
                            Label("Appearance", systemImage: "sun.max").foregroundColor(.primary)
                            Spacer()
                            Text("\(profileViewModel.appAppearance.title)").foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        // Reset onboarding flag and inform the user
                        hasSeenOnboarding = false
                        showResetOnboardingAlert = true
                    } label: {
                        HStack {
                            Label("Reset Onboarding", systemImage: "arrowshape.turn.up.backward.badge.clock").foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        let buttonURL = "https://github.com/plushgraffiti/capturr/issues"
                        openURL(URL(string: buttonURL)!)
                    } label: {
                        HStack {
                            Label("Report Issue", systemImage: "ladybug").foregroundColor(.primary)
                            Spacer()
                            
                        }
                    }
                    .buttonStyle(.plain)
                    
                    HStack{
                        Label("Version", systemImage: "info.circle").foregroundColor(.primary)
                        Spacer()
                        Text("\(version) (\(build))")
                            .foregroundStyle(.secondary)
                    }
                    
                } header: {
                    Text("CAPTURR")
                }
                
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .alert("Onboarding reset. Close the app, reopen and you will see onboarding again.", isPresented: $showResetOnboardingAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

#Preview {
    let mockViewModel = ProfileViewModel()
    mockViewModel.defaultTag = "#capture"
    return SettingsHome()
        .environmentObject(mockViewModel)
        .environment(\.locale, .init(identifier: "en"))
}
