//
//  ProfileManager.swift
//  Capturr
//
//  Created by Paul Griffiths on 8/8/25.
//

import Foundation
import SwiftData

/// Manages user profile data and interactions with SwiftData
class ProfileManager {
    private let modelContext: ModelContext
    
    // Device UUID storage for consistent user identification
    static var deviceUUID: String {
        if let storedUUID = UserDefaults.standard.string(forKey: "capture.deviceUUID") {
            return storedUUID
        } else {
            let newUUID = UUID().uuidString
            UserDefaults.standard.set(newUUID, forKey: "capture.deviceUUID")
            return newUUID
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Returns the current user profile, creating one if it doesn't exist
    func getCurrentProfile() throws -> UserProfile {
        // Try to fetch existing profile
        let deviceID = ProfileManager.deviceUUID
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { profile in
                profile.id == deviceID
            }
        )
        
        let existingProfiles = try modelContext.fetch(descriptor)
        
        // If profile exists, return it
        if let profile = existingProfiles.first {
            return profile
        }
        
        // Otherwise create new profile
        let newProfile = UserProfile(
            id: ProfileManager.deviceUUID,
            appAppearance: Appearance.dark,
        )
        modelContext.insert(newProfile)
        try modelContext.save()
        
        return newProfile
    }
    
    /// Updates the user profile with given settings
    func updateProfile(_ profile: UserProfile) throws {
        try modelContext.save()
    }
}
