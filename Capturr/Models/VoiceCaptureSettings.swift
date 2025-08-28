//
//  VoiceCaptureSettings.swift
//  Capturr
//
//  Created by Paul Griffiths on 13/8/25.
//

import Foundation

public struct VoiceCaptureSettings {
    public var localeIdentifier: String = "en"   // fixed per your spec
    public var requireOnDevice: Bool = true
    public init() {}
}
