//
//  ProfileViewModel.swift
//  Capturr
//
//  Created by Paul Griffiths on 8/8/25.
//

import Foundation
import SwiftUI
import SwiftData

/// ViewModel that provides profile data to views
class ProfileViewModel: ObservableObject {
    @Published var appAppearance: Appearance = .system
    @Published var isProfileReady: Bool = false
    @Published var graphName: String?
    @Published var apiToken: String?
    @Published var defaultTag: String?
    @Published var addTimestamp: Bool = false
    @Published var useDailyNotes: Bool = true
    @Published var customLocation: String?
    @Published var customBlock: String?
    
    var modelContext: ModelContext!
    var profileManager: ProfileManager?
    
    // Reference to the actual profile model
    private var profileModel: UserProfile?
    
    // Updates view model with data from the profile
    func updateViewModel(with profile: UserProfile) {
        self.profileModel = profile
        self.appAppearance = profile.appAppearance
        self.graphName = profile.graphName
        self.apiToken = profile.apiToken
        self.defaultTag = profile.defaultTag
        self.addTimestamp = profile.addTimestamp
        self.useDailyNotes = profile.useDailyNotes
        self.customLocation = profile.customLocation
        self.customBlock = profile.customBlock
        self.isProfileReady = true
    }
    
    // Updates the profile model with current view model data
    func saveChanges(context: ModelContext) throws {
        guard let profile = profileModel else {
            print("Cannot save: No profile model available")
            return
        }
        
        // Update and save regardless to ensure consistency
        profile.appAppearance = appAppearance
        profile.graphName = graphName
        profile.apiToken = apiToken
        profile.defaultTag = defaultTag
        profile.addTimestamp = addTimestamp
        profile.useDailyNotes = useDailyNotes
        profile.customLocation = customLocation
        profile.customBlock = customBlock
        try context.save()
        print("Profile saved with appAppearance: \(appAppearance)")
    }
}
