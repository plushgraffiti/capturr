//
//  SettingAppearance.swift
//  Capturr
//
//  Created by Paul Griffiths on 8/8/25.
//

import SwiftUI

struct SettingAppearance: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            List {
                Section(
                    header: Text("Choose Appearance"),
                    footer: Text("Select your preferred app appearance: Light, Dark, or System (follows your device setting).")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                ) {
                    ForEach(Appearance.allCases) { mode in
                        Button(action: {
                            profileViewModel.appAppearance = mode
                        }) {
                            HStack {
                                Image(systemName: iconName(for: mode))
                                Text(mode.title)
                                Spacer()
                                if profileViewModel.appAppearance == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Appearance")
                        .font(.headline)
                }
            }
            .listStyle(.insetGrouped)
            .onChange(of: profileViewModel.appAppearance) { oldValue, newValue in
                // Save changes when toggle changes
                do {
                    try profileViewModel.saveChanges(context: context)
                } catch {
                    print("Failed to save profile changes: \(error)")
                }
            }
        }
    }

    // Helper to map each tab to its SF Symbol
    private func iconName(for tab: Appearance) -> String {
        switch tab {
        case .light: return "lightbulb"
        case .dark: return "lightbulb.fill"
        case .system: return "gear"
        }
    }
}

#Preview {
    let mockViewModel = ProfileViewModel()
    return SettingAppearance()
        .environmentObject(mockViewModel)
}
