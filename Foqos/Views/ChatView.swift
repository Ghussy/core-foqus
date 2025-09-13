import SwiftUI
import RealtimeAPI
import Supabase
import SwiftData

struct ChatView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var newMessage: String = ""
  @State private var conversation = try! Conversation()
  @State private var isConnecting: Bool = false
  @State private var isConnected: Bool = false
  @State private var connectionError: String? = nil

  private var messages: [Item.Message] { conversation.messages }

  var body: some View {
    VStack(spacing: 0) {
      // Controls
      HStack(spacing: 12) {
        Button(isConnected ? "Connected" : (isConnecting ? "Connecting..." : "Start")) {
          guard !isConnecting && !isConnected else { return }
          Task { await connectRealtime() }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isConnecting || isConnected)

        Button("Stop") { stopRealtime() }
        .buttonStyle(.bordered)
        .disabled(!isConnected && !isConnecting)

        if let error = connectionError {
          Text(error)
            .font(.footnote)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
      .padding([.top, .horizontal])

      ScrollView {
        VStack(spacing: 12) {
          ForEach(messages, id: \.id) { message in
            MessageBubble(message: message)
          }
        }
        .padding()
      }

      HStack(spacing: 12) {
        HStack {
          TextField("Chat", text: $newMessage, onCommit: { sendMessage() })
            .frame(height: 40)
            .submitLabel(.send)
            .disabled(!isConnected)

          if newMessage != "" {
            Button(action: sendMessage) {
              Image(systemName: "arrow.up.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 28, height: 28)
                .foregroundStyle(.white, .blue)
            }
            .accessibilityLabel("Send message")
            .disabled(!isConnected)
          }
        }
        .padding(.leading)
        .padding(.trailing, 6)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 1))
      }
      .padding()
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
    .overlay(alignment: .top) {
      if isConnecting { ProgressView().padding() }
    }
  }

  private func sendMessage() {
    guard newMessage != "", isConnected else { return }

    let text = newMessage
    newMessage = ""
    Task { try? await conversation.send(from: .user, text: text) }
  }
}

struct MessageBubble: View {
  let message: Item.Message
  
  private var isFromUser: Bool {
    message.role == .user
  }
  
  var body: some View {
    HStack {
      if isFromUser {
        Spacer()
      }
      
      VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
        Text(verbatim: String(describing: message))
          .font(.body)
          .foregroundColor(isFromUser ? .white : .primary)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 18)
              .fill(isFromUser ? Color.blue : Color(UIColor.systemGray5))
          )
      }
      
      if !isFromUser {
        Spacer()
      }
    }
    .padding(.horizontal, 16)
  }
}

enum EphemeralKeyProvider {
  struct FunctionResponse: Codable {
    struct ClientSecret: Codable { let value: String? }
    let ephemeralKey: String?
    let client_secret: ClientSecret?
    let value: String?
    let expires_at: Int?
    let id: String?
  }

  static func fetch() async throws -> String {
    let resp: FunctionResponse = try await supabase.functions.invoke(
      "realtime-eph-key",
      options: FunctionInvokeOptions()
    )
    if let key = resp.ephemeralKey, !key.isEmpty { return key }
    if let key = resp.client_secret?.value, !key.isEmpty { return key }
    if let key = resp.value, !key.isEmpty { return key }

    throw NSError(
      domain: "EphemeralKeyProvider",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: "Invalid ephemeral key response from function"]
    )
  }
}

private extension ChatView {
  func connectRealtime() async {
    isConnecting = true
    connectionError = nil
    do {
      let key = try await EphemeralKeyProvider.fetch()
      try await conversation.connect(ephemeralKey: key)

      // Customize session (greeting + respond in text)
      if let name = await fetchDisplayName() {
        try? await conversation.updateSession { session in
          session.instructions = "You are a little bear. Greet the user by name (\(name)). You say things in the style of a little bear."
        }
      } else {
        try? await conversation.updateSession { session in
          session.instructions = "You are a helpful assistant."
        }
      }

      isConnecting = false
      isConnected = true
    } catch {
      isConnecting = false
      isConnected = false
      connectionError = error.localizedDescription
    }
  }

  func stopRealtime() {
    conversation = try! Conversation()
    isConnected = false
  }

  func fetchDisplayName() async -> String? {
    // Prefer cached profile via SwiftData if available
    let repo = ProfilesRepository(context: modelContext)
    if let profile = try? await repo.fetchProfile() {
      if let full = profile.fullName, !full.isEmpty { return full }
      if let user = profile.username, !user.isEmpty { return user }
    }
    // Fallback to auth session (local values)
    if let session = try? await supabase.auth.session {
      if let email = session.user.email, !email.isEmpty {
        return String(email.split(separator: "@").first ?? "User")
      }
    }
    return nil
  }
}


