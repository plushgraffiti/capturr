//
//  VoiceInput.swift
//  Capturr
//
//  Created by Paul Griffiths on 13/8/25.
//

import Foundation

public final class VoiceInput: CaptureInput {
    private let settings: VoiceCaptureSettings
    private let audio: AudioSessionManaging
    private let speech: SpeechRecognizing
    private let sanitize: TranscriptSanitizing

    public init(settings: VoiceCaptureSettings = .init(),
                audio: AudioSessionManaging = AudioSessionManager(),
                speech: SpeechRecognizing = VoiceSpeechService(),
                sanitize: TranscriptSanitizing = TranscriptSanitizer()) {
        self.settings = settings
        self.audio = audio
        self.speech = speech
        self.sanitize = sanitize
    }

    public func begin() throws {
        // Permissions first
        Task {
            try? await speech.requestPermissions()
        }
        try audio.activate()
        try speech.start(localeIdentifier: settings.localeIdentifier,
                         requireOnDevice: settings.requireOnDevice)
    }

    public func end() async throws -> String {
        let raw = try await speech.finishAndGetTranscript(timeoutSeconds: 6)
        let cleaned = sanitize.clean(raw)
        guard !cleaned.isEmpty else { throw VoiceCaptureError.noSpeechDetected }
        audio.deactivate()
        return cleaned
    }

    public func cancel() {
        speech.cancel()
        audio.deactivate()
    }
}
