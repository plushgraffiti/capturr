//
//  VoiceCaptureError.swift
//  Capturr
//
//  Created by Paul Griffiths on 13/8/25.
//

import Foundation

public enum VoiceCaptureError: LocalizedError {
    case speechPermissionDenied
    case microphonePermissionDenied
    case engineUnavailable
    case onDeviceNotAvailable
    case noSpeechDetected
    case timedOut
    case internalFailure(String)

    public var errorDescription: String? {
        switch self {
        case .speechPermissionDenied:   return "Speech recognition permission is required."
        case .microphonePermissionDenied: return "Microphone access is required."
        case .engineUnavailable:        return "Speech engine is currently unavailable."
        case .onDeviceNotAvailable:     return "On‑device speech is not available on this device."
        case .noSpeechDetected:         return "No transcribable speech was detected."
        case .timedOut:                 return "Transcription timed out."
        case .internalFailure(let msg): return msg
        }
    }
}
