//
//  UserProfile.swift
//  Capturr
//
//  Created by Paul Griffiths on 8/8/25.
//

import Foundation
import SwiftData

@Model
class UserProfile {
    var id: String
    
    var appAppearanceRaw: String = Appearance.system.rawValue
    var appAppearance: Appearance {
        get { Appearance(rawValue: appAppearanceRaw) ?? .system }
        set { appAppearanceRaw = newValue.rawValue }
    }
    var graphName: String?
    var apiToken: String?
    var defaultTag: String?
    var addTimestamp: Bool = false
    var useDailyNotes: Bool = true
    var customLocation: String?
    var customBlock: String?
    var shareFormatLinks: Bool = false
    
    init(
        id: String = UUID().uuidString,
        appAppearance: Appearance = .dark
    ) {
        self.id = id
        self.appAppearanceRaw = appAppearance.rawValue
    }
}

// Used in Profile to allow user to set Appearance mode
enum Appearance: String, Codable, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            let message = NSLocalizedString("Light", comment: "Light mode for app appearance")
            return message
            
        case .dark:
            let message = NSLocalizedString("Dark", comment: "Dark mode for app appearance")
            return message
            
        case .system:
            let message = NSLocalizedString("System", comment: "System mode for app appearance")
            return message
            
        }
    }
}
