import SwiftUI
import Supabase

struct AppView: View {
  @EnvironmentObject private var requestAuthorizer: RequestAuthorizer
  @EnvironmentObject private var donationManager: TipManager
  @EnvironmentObject private var navigationManager: NavigationManager
  @EnvironmentObject private var nfcWriter: NFCWriter
  @EnvironmentObject private var ratingManager: RatingManager
  @EnvironmentObject private var liveActivityManager: LiveActivityManager
  @EnvironmentObject private var strategyManager: StrategyManager

  @State private var isAuthenticated = false

  var body: some View {
    Group {
      if isAuthenticated {
        MainTabView()
      } else {
        AuthView()
      }
    }
    .environmentObject(requestAuthorizer)
    .environmentObject(donationManager)
    .environmentObject(strategyManager)
    .environmentObject(navigationManager)
    .environmentObject(nfcWriter)
    .environmentObject(ratingManager)
    .environmentObject(liveActivityManager)
    .task {
      // Initial session + live stream of changes
      if let session = try? await supabase.auth.session {
        isAuthenticated = session.user.id != nil
      } else {
        isAuthenticated = false
      }
      for await state in supabase.auth.authStateChanges {
        if [.initialSession, .signedIn, .signedOut].contains(state.event) {
          isAuthenticated = state.session != nil
        }
      }
    }
    .onOpenURL { url in
      // Complete magic link and continue existing universal link handling
      Task { try? await supabase.auth.session(from: url) }
      navigationManager.handleLink(url)
    }
  }
}