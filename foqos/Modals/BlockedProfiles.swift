
import Foundation
import SwiftData
import FamilyControls
import ManagedSettings

@Model
class BlockedProfiles {
    @Attribute(.unique) var id: UUID
    var name: String
    var selectedActivity: FamilyActivitySelection
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(),
         name: String,
         selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.selectedActivity = selectedActivity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func fetchProfiles(in context: ModelContext) throws -> [BlockedProfiles] {
        let descriptor = FetchDescriptor<BlockedProfiles>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    static func findProfile(byID id: UUID, in context: ModelContext) throws -> BlockedProfiles? {
        let descriptor = FetchDescriptor<BlockedProfiles>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    static func fetchMostRecentlyUpdatedProfile(in context: ModelContext) throws -> BlockedProfiles? {
        let descriptor = FetchDescriptor<BlockedProfiles>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }
    
    static func updateProfile(_ profile: BlockedProfiles,
                            in context: ModelContext,
                            name: String? = nil,
                            selection: FamilyActivitySelection? = nil) throws {
        if let newName = name {
            profile.name = newName
        }
        
        if let newSelection = selection {
            profile.selectedActivity = newSelection
        }
        
        profile.updatedAt = Date()
        try context.save()
    }
    
    static func deleteProfile(_ profile: BlockedProfiles, in context: ModelContext) throws {
        context.delete(profile)
        try context.save()
    }
    
    static func countSelectedActivities(_ selection: FamilyActivitySelection) -> Int {
        return selection.categories.count + selection.applications.count
    }
}
