//
//  CaptureVoice.swift
//  Capturr
//
//  Created by Paul Griffiths on 12/8/25.
//

import SwiftUI
import SwiftData

struct CaptureVoice: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isRecording = false
    @State private var message: String? = "Ready"

    // Injected for testability; default uses our concrete VoiceInput
    let input: CaptureInput = VoiceInput()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Button(action: toggle) {
                ZStack {
                    Circle()
                        .frame(width: 96, height: 96)
                        .shadow(radius: isRecording ? 8 : 2)
                        .overlay(Circle().strokeBorder(.secondary.opacity(0.25), lineWidth: 1))
                        .foregroundStyle(isRecording ? .red.opacity(0.8) : .accentColor)
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
            }
            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
            Text("Single-shot voice capture. Tap to start, tap to stop. Transcript is created after recording.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .onDisappear { if isRecording { input.cancel() } }
    }

    private func toggle() {
        if isRecording {
            Task { @MainActor in
                message = "Processing…"
                do {
                    let text = try await input.end()
                    message = "Saving…"
                    let manager = SyncManager(modelContext: modelContext)
                    manager.captureNote(text)
                    let worker = SyncWorker(modelContext: modelContext)
                    worker.syncPendingItems()
                    message = "Saved"
                    dismiss()
                } catch {
                    message = error.localizedDescription
                }
                isRecording = false
            }
        } else {
            do {
                try input.begin()
                message = "Recording…"
                isRecording = true
            } catch {
                message = error.localizedDescription
                isRecording = false
            }
        }
    }
}
