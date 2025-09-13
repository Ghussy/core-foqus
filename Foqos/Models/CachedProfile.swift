import Foundation
import SwiftData

@Model
final class CachedProfile {
  @Attribute(.unique) var id: UUID
  var username: String?
  var fullName: String?
  var website: String?
  var updatedAt: Date

  init(id: UUID, username: String?, fullName: String?, website: String?, updatedAt: Date) {
    self.id = id
    self.username = username
    self.fullName = fullName
    self.website = website
    self.updatedAt = updatedAt
  }
}


