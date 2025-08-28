//
//  TranscriptSanitizer.swift
//  Capturr
//
//  Created by Paul Griffiths on 13/8/25.
//

import Foundation

public protocol TranscriptSanitizing {
    func clean(_ raw: String) -> String
}

public struct TranscriptSanitizer: TranscriptSanitizing {
    public init() {}
    public func clean(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        let punctuationSet = CharacterSet(charactersIn: ".,;:!?…—-•··")
        if trimmed.unicodeScalars.allSatisfy({ punctuationSet.contains($0) || CharacterSet.whitespacesAndNewlines.contains($0) }) {
            return ""
        }
        return trimmed
    }
}
