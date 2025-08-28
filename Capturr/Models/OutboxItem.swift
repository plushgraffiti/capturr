//
//  OutboxItem.swift
//  Capturr
//
//  Created by Paul Griffiths on 7/8/25.
//

import Foundation
import SwiftData

@objc enum SyncStatus: Int, Codable {
    case pending = 0
    case success = 1
    case failed = 2
    case inProgress = 3
    
    var description: String {
            switch self {
            case .pending: return "Pending"
            case .success: return "Success"
            case .failed: return "Failed"
            case .inProgress: return "In Progress"
            }
        }
}

@objc enum OutboxItemType: Int, Codable {
  case note = 0
  case todo = 1
}

@Model
class OutboxItem {
    @Attribute(.unique) var id: UUID
    var content: String
    var type: OutboxItemType
    var createdAt: Date
    var sentAt: Date?
    var status: Int
    var lastError: String?
    var attemptCount: Int

    // Additional optional fields for robust syncing (lightweight additive schema change)
    var stampAt: Date?          // first-attempt timestamp used for deterministic retries
    var lastAttemptAt: Date?    // last time we tried to sync
    var nextAttemptAt: Date?    // when we should try again (for backoff)
    var hardError: Bool?        // treat nil as false; set for 401/403 to pause until creds change

    init(content: String, type: OutboxItemType = .note) {
        self.id = UUID()
        self.content = content
        self.type = type
        self.createdAt = Date()
        self.sentAt = nil
        self.status = SyncStatus.pending.rawValue
        self.lastError = nil
        self.attemptCount = 0
    }
}
