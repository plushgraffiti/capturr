//
//  OnboardingPermissions.swift
//  Capturr
//
//  Created by Paul Griffiths on 3/9/25.
//  Updated: Hybrid permissions flow with live status + one-tap enable
//

import SwiftUI
import AVFAudio
import Speech
import UIKit

struct OnboardingPermissions: View {
    let onNext: () -> Void
    @StateObject private var vm = PermissionsViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                    Image(systemName: "hand.raised")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                        .offset(x: 1, y: -1)
                }
                .padding(.top)

                Text("Setup: Permissions")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                Text("In order to send **Voice** notes to your Graph we will need to enable some permissions. **This step is optional.**")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    PermissionRow(
                        icon: "mic.fill",
                        title: "Microphone",
                        state: vm.micDisplayState,
                        onEnable: { vm.requestMic() },
                        onOpenSettings: openSettings
                    )

                    PermissionRow(
                        icon: "speaker.wave.2.bubble",
                        title: "Speech Recognition",
                        state: vm.speechDisplayState,
                        onEnable: { vm.requestSpeech() },
                        onOpenSettings: openSettings
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("**We Respect Your Privacy:** Outside of what is sent to your Roam Research graph all data remains on this device. **No tracking, no targeting, no ads.**")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            Spacer()

            VStack(spacing: 12) {
                Button {
                    if vm.allGranted {
                        onNext()
                    } else if vm.isAnyRestricted {
                        openSettings()
                    } else {
                        vm.requestBoth {
                            if vm.allGranted { onNext() }
                        }
                    }
                } label: {
                    Text(vm.allGranted ? "Finish" : (vm.isAnyRestricted ? "Open Settings" : "Enable Permissions"))
                        .frame(maxWidth: .infinity)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)
                .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }

                if !vm.allGranted {
                    Button {
                        onNext()
                    } label: {
                        Text("Skip This Step")
                            .frame(maxWidth: .infinity)
                            .font(.callout)
                            .padding(8)
                    }
                    .buttonStyle(.bordered)
                    .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }
                }
            }
            .padding(.bottom, 60)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .task { vm.refresh() }
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            openURL(settingsURL)
        }
    }
}

#Preview {
    OnboardingPermissions(onNext: { })
        .padding()
}
