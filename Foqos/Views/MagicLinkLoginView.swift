import SwiftUI

struct MagicLinkLoginView: View {
  @State private var email: String = ""
  @State private var isPerforming: Bool = false
  @State private var alert: AlertModal = .init(message: "")
  @FocusState private var emailFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Welcome")
          .font(.largeTitle)
        Text("Enter your email to continue.")
          .font(.callout)
      }
      .fontWeight(.medium)
      .padding(.top, 5)

      IconTextField(hint: "Email Address", symbol: "envelope", value: $email)
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.top, 15)
        .disabled(alert.show)

      TaskButton(title: "Send Magic Link") {
        emailFocused = false
        await sendMagicLink()
      } onStatusChange: { loading in
        isPerforming = loading
      }
      .disabled(email.isEmpty)
      .padding(.top, 15)

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding([.horizontal, .top], 20)
    .padding(.bottom, isiOS26 ? 0 : 10)
    .allowsHitTesting(!isPerforming)
    .opacity(isPerforming ? 0.7 : 1)
    .customAlert($alert)
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onChange(of: alert.show) { _, showing in
      if showing { emailFocused = false }
    }
  }

  private func sendMagicLink() async {
    do {
      try await supabase.auth.signInWithOTP(
        email: email,
        redirectTo: URL(string: "c0re://login-callback")
      )
      alert = .init(icon: "envelope.badge", title: "Check Your Inbox", message: "We sent a login link to \(email).", show: true, action: { alert.show = false })
    } catch {
      alert = .init(message: error.localizedDescription, show: true)
    }
  }
}


