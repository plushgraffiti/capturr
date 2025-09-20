//
//  CaptureSession.swift
//  Capturr
//
//  Created by Paul Griffiths on 13/8/25.
//

import Foundation

protocol CaptureSession {
    /// Prepare resources and begin capturing.
    func begin() throws
    /// Finish capture and return a final transcript (single paragraph).
    func end() async throws -> String
    /// Abort capture (e.g., on view disappear).
    func cancel()
}
