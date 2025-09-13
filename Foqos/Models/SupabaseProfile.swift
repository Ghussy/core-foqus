import Foundation
import SwiftData

struct Profile: Decodable {
  let username: String?
  let fullName: String?
  let website: String?

  enum CodingKeys: String, CodingKey {
    case username
    case fullName = "full_name"
    case website
  }
}

struct UpdateProfileParams: Encodable {
  let username: String
  let fullName: String
  let website: String

  enum CodingKeys: String, CodingKey {
    case username
    case fullName = "full_name"
    case website
  }
}

// Payload used for upserting the row (needs id and updated_at)
struct UpsertProfilePayload: Encodable {
  let id: UUID
  let username: String
  let fullName: String
  let website: String
  let updatedAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case username
    case fullName = "full_name"
    case website
    case updatedAt = "updated_at"
  }
}