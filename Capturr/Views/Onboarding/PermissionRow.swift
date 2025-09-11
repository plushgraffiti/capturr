//
//  PermissionRow.swift
//  Capturr
//
//  Created by Paul Griffiths on 11/9/25.
//

import SwiftUI

struct PermissionRow: View {
    let icon: String
    let title: String
    let state: DisplayState
    let onEnable: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                switch state {
                case .authorized:
                    Label("Enabled", systemImage: "checkmark.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.callout)
                        .foregroundStyle(.green)
                        .contentTransition(.opacity)
                        .padding(.top, 4)
                case .notDetermined:
                    Label("Not Enabled", systemImage: "questionmark.circle.dashed")
                        .labelStyle(.titleAndIcon)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                        .padding(.top, 4)
                case .denied, .restricted:
                    Label("Enable via Settings", systemImage: "exclamationmark.triangle")
                        .labelStyle(.titleAndIcon)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .contentTransition(.opacity)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 10)
        
    }
}
