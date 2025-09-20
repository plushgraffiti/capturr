//
//  VoiceSpeechService.swift
//  Capturr
//
//  Created by Paul Griffiths on 13/8/25.
//

import AVFoundation
import Speech
import UIKit

public protocol SpeechRecognizing {
    func requestPermissions() async throws
    func start(localeIdentifier: String, requireOnDevice: Bool) throws
    func finishAndGetTranscript(timeoutSeconds: TimeInterval) async throws -> String
    func cancel()
}

public final class VoiceSpeechService: NSObject, SpeechRecognizing {
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var startedAt: Date?
    private var resultHandlerContinuation: CheckedContinuation<SFSpeechRecognitionResult, Error>?
    private var timeoutTimer: Timer?

    public override init() { super.init() }

    public func requestPermissions() async throws {
        let speechAuth = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechAuth == .authorized else { throw VoiceCaptureError.speechPermissionDenied }

        let micGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
        }
        guard micGranted else { throw VoiceCaptureError.microphonePermissionDenied }
    }

    public func start(localeIdentifier: String, requireOnDevice: Bool) throws {
        // Build recognizer
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        speechRecognizer = recognizer
        guard let recognizer else { throw VoiceCaptureError.engineUnavailable }
        guard recognizer.isAvailable else { throw VoiceCaptureError.engineUnavailable }
        if #available(iOS 13.0, *), requireOnDevice, !recognizer.supportsOnDeviceRecognition {
            throw VoiceCaptureError.onDeviceNotAvailable
        }

        // Configure audio
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        if #available(iOS 13.0, *), requireOnDevice {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do { try audioEngine.start() } catch {
            inputNode.removeTap(onBus: 0)
            throw VoiceCaptureError.internalFailure("Failed to start audio engine: \(error.localizedDescription)")
        }

        // Start task (we don’t expose partials)
        recognitionTask?.cancel()
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let error {
                if let cont = self.resultHandlerContinuation {
                    self.resultHandlerContinuation = nil
                    cont.resume(throwing: error)
                }
                return
            }
            if let result, result.isFinal {
                if let cont = self.resultHandlerContinuation {
                    self.resultHandlerContinuation = nil
                    cont.resume(returning: result)
                }
            }
        }

        startedAt = Date()
    }

    public func finishAndGetTranscript(timeoutSeconds: TimeInterval) async throws -> String {
        // Stop audio, signal end, and await final result via a continuation
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()

        let result: SFSpeechRecognitionResult = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<SFSpeechRecognitionResult, Error>) in
            // store continuation to be resumed by the recognition task handler
            self.resultHandlerContinuation = cont
            // timeout guard without capturing self in a sendable closure
            self.timeoutTimer?.invalidate()
            self.timeoutTimer = Timer.scheduledTimer(timeInterval: timeoutSeconds,
                                                     target: self,
                                                     selector: #selector(self.timeoutFired),
                                                     userInfo: nil,
                                                     repeats: false)
        }

        timeoutTimer?.invalidate(); timeoutTimer = nil

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        // By the time we reach here, `result` is final
        let text = result.bestTranscription.formattedString
        // Protect against very short captures with no speech
        if let startedAt, Date().timeIntervalSince(startedAt) < 0.7, text.isEmpty {
            throw VoiceCaptureError.noSpeechDetected
        }
        return text
    }

    @objc private func timeoutFired() {
        if let cont = resultHandlerContinuation {
            resultHandlerContinuation = nil
            recognitionTask?.cancel()
            cont.resume(throwing: VoiceCaptureError.timedOut)
        }
    }

    public func cancel() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}
