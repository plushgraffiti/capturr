//
//  SyncManager.swift
//  Capturr
//
//  Created by Paul Griffiths on 7/8/25.
//

import Foundation
import SwiftData

class SyncManager {
    let modelContext: ModelContext
    let syncWorker: SyncWorker

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.syncWorker = SyncWorker(modelContext: modelContext)
    }

    func capture(_ content: String, type: OutboxItemType = .note) {
        let item = OutboxItem(content: content, type: type)
        modelContext.insert(item)
        syncWorker.sync(item)
    }

    func captureNote(_ content: String) {
        capture(content, type: .note)
    }

    func captureTodo(_ content: String) {
        capture(content, type: .todo)
    }
}
