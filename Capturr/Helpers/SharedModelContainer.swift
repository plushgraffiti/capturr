//
//  SharedModelContainer.swift
//  Capturr
//
//  Created by Paul Griffiths on 20/9/25.
//

import Foundation
import SwiftData

public func SharedModelContainer() -> ModelContainer {
    let schema = Schema([
        OutboxItem.self,
        UserProfile.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError(error.localizedDescription)
    }
}

