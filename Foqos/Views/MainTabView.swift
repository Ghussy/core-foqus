import SwiftUI

struct MainTabView: View {
  enum AppTab: Hashable { case feed, main, profile }
  @State private var selectedTab: AppTab = .main


  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Feed", systemImage: "newspaper", value: AppTab.feed) {
        NavigationStack { FeedView().navigationTitle("Feed") }
      }
      Tab("Main", systemImage: "house.fill", value: AppTab.main) {
        NavigationStack { HomeView() }
      }
      Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
        NavigationStack { ProfileView().navigationTitle("Profile") }
      }
    }
  }
}


