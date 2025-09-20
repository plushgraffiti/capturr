//
//  AudioSessionManager.swift
//  Capturr
//
//  Created by Paul Griffiths on 13/8/25.
//

import AVFoundation

public protocol AudioSessionManaging {
    func activate() throws
    func deactivate()
}

public final class AudioSessionManager: AudioSessionManaging {
    public init() {}
    public func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
    public func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
