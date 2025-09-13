import SwiftUI
import SwiftData
import Supabase

final class ProfileViewModel: ObservableObject {
  @Published var username = ""
  @Published var fullName = ""
  @Published var website = ""
  @Published var email = ""
  @Published var isLoading = false

  private let repository: ProfilesRepositoryType

  init(repository: ProfilesRepositoryType = ProfilesRepository()) {
    self.repository = repository
  }

  @MainActor
  func load() async {
    do {
      if let session = try? await supabase.auth.session {
        email = session.user.email ?? ""
      }
      let profile = try await repository.fetchProfile()
      username = profile.username ?? ""
      fullName = profile.fullName ?? ""
      website = profile.website ?? ""
    } catch {
      // OK if not found
    }
  }

  func save() async {
    await MainActor.run { isLoading = true }
    defer { Task { await MainActor.run { self.isLoading = false } } }
    do {
      try await repository.upsertProfile(
        .init(username: username, fullName: fullName, website: website)
      )
    } catch {
      // surface error later
    }
  }
}

struct ProfileView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var vm: ProfileViewModel

  init(context: ModelContext? = nil) {
    _vm = StateObject(wrappedValue: ProfileViewModel(repository: ProfilesRepository(context: context)))
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        VStack(spacing: 8) {
          ZStack {
            Circle().fill(Color.blue.opacity(0.15)).frame(width: 72, height: 72)
            Text(avatarInitials())
              .font(.system(size: 28, weight: .bold))
              .foregroundColor(.blue.opacity(0.9))
          }
          .padding(.top, 12)

          if !vm.fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            Text(vm.fullName).font(.headline)
          }
          if !vm.email.isEmpty {
            Text(vm.email).font(.subheadline).foregroundColor(.secondary)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)

        Form {
          Section {
            TextField("Username", text: $vm.username)
              .textContentType(.username)
              .textInputAutocapitalization(.never)
            TextField("Full name", text: $vm.fullName)
              .textContentType(.name)
            TextField("Website", text: $vm.website)
              .textContentType(.URL)
              .textInputAutocapitalization(.never)
          }
          Section("Account") {
            HStack {
              Label("Email", systemImage: "envelope.fill")
              Spacer()
              Text(vm.email.isEmpty ? "—" : vm.email).foregroundColor(.secondary)
            }
          }
          Section {
            Button("Update profile") { Task { await vm.save() } }
              .bold()
            if vm.isLoading { ProgressView() }
          }
        }
      }
      .navigationTitle("Profile")
      .toolbar(content: {
        ToolbarItem(placement: .topBarLeading){
          Button("Sign out", role: .destructive) {
            Task { try? await supabase.auth.signOut() }
          }
        }
      })
    }
    .task { await vm.load() }
  }

  private func avatarInitials() -> String {
    let source = vm.fullName.isEmpty ? (vm.email.split(separator: "@").first.map(String.init) ?? "?") : vm.fullName
    let comps = source.split(separator: " ")
    if comps.count >= 2 { return String(comps[0].prefix(1) + comps[1].prefix(1)).uppercased() }
    return String(source.prefix(2)).uppercased()
  }
}