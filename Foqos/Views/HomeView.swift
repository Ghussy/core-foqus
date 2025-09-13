import FamilyControls
import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.openURL) var openURL

  @Environment(\.scenePhase) private var scenePhase

  @EnvironmentObject var requestAuthorizer: RequestAuthorizer
  @EnvironmentObject var strategyManager: StrategyManager
  @EnvironmentObject var navigationManager: NavigationManager
  @EnvironmentObject var ratingManager: RatingManager

  // Profile management
  @Query(sort: [
    SortDescriptor(\BlockedProfiles.order, order: .forward),
    SortDescriptor(\BlockedProfiles.createdAt, order: .reverse),
  ]) private
    var profiles: [BlockedProfiles]
  @State private var isProfileListPresent = false

  // New profile view
  @State private var showNewProfileView = false

  // Edit profile
  @State private var profileToEdit: BlockedProfiles? = nil

  // Profile View
  @State private var showUserProfileView = false

  // Emergency View
  @State private var showEmergencyView = false

  // Activity sessions
  @Query(sort: \BlockedProfileSession.startTime, order: .reverse) private
    var sessions: [BlockedProfileSession]
  @Query(
    filter: #Predicate<BlockedProfileSession> { $0.endTime != nil },
    sort: \BlockedProfileSession.endTime,
    order: .reverse
  ) private var recentCompletedSessions: [BlockedProfileSession]

  // Alerts
  @State private var showingAlert = false
  @State private var alertTitle = ""
  @State private var alertMessage = ""

  // Intro sheet
  @AppStorage("showIntroScreen") private var showIntroScreen = true

  // UI States
  @State private var opacityValue = 1.0
  @State private var showShopSheet = false

  var isBlocking: Bool {
    return strategyManager.isBlocking
  }

  var activeSessionProfileId: UUID? {
    return strategyManager.activeSession?.blockedProfile.id
  }

  var isBreakAvailable: Bool {
    return strategyManager.isBreakAvailable
  }

  var isBreakActive: Bool {
    return strategyManager.isBreakActive
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 30) {
        HStack(alignment: .center) {
          AppTitle()
          Spacer()
        }
        .padding(.trailing, 16)
        .padding(.top, 16)

        if profiles.isEmpty {
          Welcome(onTap: {
            showNewProfileView = true
          })
          .padding(.horizontal, 16)
        }

        if !profiles.isEmpty {
          // Top creature/score card first
          TopStarsHeader(
            recentCompletedSessions: recentCompletedSessions,
            onStarTapped: { showShopSheet = true }
          )

          // Profile carousel
          BlockedProfileCarousel(
            profiles: profiles,
            isBlocking: isBlocking,
            isBreakAvailable: isBreakAvailable,
            isBreakActive: isBreakActive,
            activeSessionProfileId: activeSessionProfileId,
            elapsedTime: strategyManager.elapsedTime,
            onStartTapped: { profile in
              strategyButtonPress(profile)
            },
            onStopTapped: { profile in
              strategyButtonPress(profile)
            },
            onEditTapped: { profile in
              profileToEdit = profile
            },
            onBreakTapped: { _ in
              strategyManager.toggleBreak()
            },
            onManageTapped: {
              isProfileListPresent = true
            },
            onEmergencyTapped: {
              showEmergencyView = true
            },
          )

          // Chat entry point between profile cards and 4 week activity
          NavigationLink(destination: ChatView()) {
            HStack(spacing: 12) {
              Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundColor(.white)
                .padding(8)
                .background(Color.blue)
                .clipShape(Circle())

              VStack(alignment: .leading, spacing: 2) {
                Text("Ask Foqus AI")
                  .font(.headline)
                Text("Get help, tips, and coaching in chat")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }

              Spacer()
              Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)
          }

          // Weekly activity now at the bottom
          BlockedSessionsHabitTracker(
            sessions: recentCompletedSessions
          )
          .padding(.horizontal, 16)
        }

        VersionFooter(
          authorizationStatus: requestAuthorizer.getAuthorizationStatus(),
          onAuthorizationHandler: {
            requestAuthorizer.requestAuthorization()
          }
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 15)
      }
    }
    .refreshable {
      loadApp()
    }
    .padding(.top, 1)
    .sheet(
      isPresented: $isProfileListPresent,
    ) {
      BlockedProfileListView()
    }
    .frame(
      minWidth: 0,
      maxWidth: .infinity,
      minHeight: 0,
      maxHeight: .infinity,
      alignment: .topLeading
    )
    .onChange(of: navigationManager.profileId) { _, newValue in
      if let profileId = newValue, let url = navigationManager.link {
        toggleSessionFromDeeplink(profileId, link: url)
        navigationManager.clearNavigation()
      }
    }
    .onChange(of: requestAuthorizer.isAuthorized) { _, newValue in
      if newValue {
        showIntroScreen = false
      } else {
        showIntroScreen = true
      }
    }
    .onChange(of: profiles) { oldValue, newValue in
      if !newValue.isEmpty {
        loadApp()
      }
    }
    .onChange(of: scenePhase) { oldPhase, newPhase in
      if newPhase == .active {
        loadApp()
      } else if newPhase == .background {
        unloadApp()
      }
    }
    .onReceive(strategyManager.$errorMessage) { errorMessage in
      if let message = errorMessage {
        showErrorAlert(message: message)
      }
    }
    .onAppear {
      onAppearApp()
    }
    .sheet(isPresented: $showIntroScreen) {
      IntroView {
        requestAuthorizer.requestAuthorization()
      }.interactiveDismissDisabled()
    }.sheet(item: $profileToEdit) { profile in
      BlockedProfileView(profile: profile)
    }
    .sheet(
      isPresented: $showNewProfileView,
    ) {
      BlockedProfileView(profile: nil)
    }
    .sheet(isPresented: $strategyManager.showCustomStrategyView) {
      BlockingStrategyActionView(
        customView: strategyManager.customStrategyView
      )
    }
    .sheet(isPresented: $showUserProfileView) {
      ProfileView()
    }
    .sheet(isPresented: $showShopSheet) {
      ShopView()
    }
    .sheet(isPresented: $showEmergencyView) {
      EmergencyView()
        .presentationDetents([.height(350)])
    }
    .alert(alertTitle, isPresented: $showingAlert) {
      Button("OK", role: .cancel) { dismissAlert() }
    } message: {
      Text(alertMessage)
    }
    .fullScreenCover(
      isPresented: Binding(
        get: { strategyManager.isBlocking },
        set: { presenting in
          if !presenting {
            strategyManager.toggleBlocking(context: context, activeProfile: nil)
          }
        }
      )
    ) {
      ActiveSessionView()
        .environmentObject(strategyManager)
        .interactiveDismissDisabled(true)
    }
  }

  private func toggleSessionFromDeeplink(_ profileId: String, link: URL) {
    strategyManager
      .toggleSessionFromDeeplink(profileId, url: link, context: context)
  }

  private func strategyButtonPress(_ profile: BlockedProfiles) {
    strategyManager
      .toggleBlocking(context: context, activeProfile: profile)

    ratingManager.incrementLaunchCount()
  }

  private func loadApp() {
    strategyManager.loadActiveSession(context: context)
  }

  private func onAppearApp() {
    strategyManager.loadActiveSession(context: context)
    strategyManager.cleanUpGhostSchedules(context: context)
  }

  private func unloadApp() {
    strategyManager.stopTimer()
  }

  private func showErrorAlert(message: String) {
    alertTitle = "Whoops"
    alertMessage = message
    showingAlert = true
  }

  private func dismissAlert() {
    showingAlert = false
  }
}

#Preview {
  HomeView()
    .environmentObject(RequestAuthorizer())
    .environmentObject(TipManager())
    .environmentObject(NavigationManager())
    .environmentObject(StrategyManager())
    .defaultAppStorage(UserDefaults(suiteName: "preview")!)
    .onAppear {
      UserDefaults(suiteName: "preview")!.set(
        false,
        forKey: "showIntroScreen"
      )
    }
}
