import Foundation
import Supabase
import SwiftData

protocol ProfilesRepositoryType {
  func fetchProfile() async throws -> Profile
  func upsertProfile(_ params: UpdateProfileParams) async throws
}

final class ProfilesRepository: ProfilesRepositoryType {
  private let table = "profiles"
  private let context: ModelContext?

  init(context: ModelContext? = nil) {
    self.context = context
  }

  func fetchProfile() async throws -> Profile {
    let user = try await supabase.auth.session.user
    // If we have a cache context, try cache first
    if let ctx = context {
      if let cached = try? fetchCached(ctx: ctx, id: user.id) {
        // kick off background refresh
        Task { try? await self.refreshRemoteIntoCache(userId: user.id) }
        return Profile(username: cached.username, fullName: cached.fullName, website: cached.website)
      }
    }
    // Network fallback
    let profile = try await fetchRemote(userId: user.id)
    if let ctx = context {
      try? cache(ctx: ctx, id: user.id, profile: profile)
    }
    return profile
  }

  func upsertProfile(_ params: UpdateProfileParams) async throws {
    let user = try await supabase.auth.session.user
    let payload = UpsertProfilePayload(
      id: user.id,
      username: params.username,
      fullName: params.fullName,
      website: params.website,
      updatedAt: ISO8601DateFormatter().string(from: Date())
    )
    _ = try await supabase
      .from(table)
      .upsert(payload, onConflict: "id")
      .execute()
    if let ctx = context {
      try? cache(ctx: ctx, id: user.id, profile: Profile(username: params.username, fullName: params.fullName, website: params.website))
    }
  }

  // MARK: - Private helpers (cache + network)
  private func fetchRemote(userId: UUID) async throws -> Profile {
    try await supabase
      .from(table)
      .select()
      .eq("id", value: userId)
      .single()
      .execute()
      .value
  }

  private func fetchCached(ctx: ModelContext, id: UUID) throws -> CachedProfile? {
    let descriptor = FetchDescriptor<CachedProfile>(predicate: #Predicate { $0.id == id })
    return try ctx.fetch(descriptor).first
  }

  private func cache(ctx: ModelContext, id: UUID, profile: Profile) throws {
    if let existing = try fetchCached(ctx: ctx, id: id) {
      existing.username = profile.username
      existing.fullName = profile.fullName
      existing.website = profile.website
      existing.updatedAt = Date()
    } else {
      let cached = CachedProfile(
        id: id,
        username: profile.username,
        fullName: profile.fullName,
        website: profile.website,
        updatedAt: Date()
      )
      ctx.insert(cached)
    }
    try? ctx.save()
  }

  private func refreshRemoteIntoCache(userId: UUID) async throws {
    let profile = try await fetchRemote(userId: userId)
    if let ctx = context {
      try? cache(ctx: ctx, id: userId, profile: profile)
    }
  }
}


