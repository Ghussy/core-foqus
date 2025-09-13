import SwiftUI

struct TopStarsHeader: View {
  let recentCompletedSessions: [BlockedProfileSession]
  @AppStorage("gradientR") private var gradientR: Double = 0.5
  @AppStorage("gradientG") private var gradientG: Double = 0.0
  @AppStorage("gradientB") private var gradientB: Double = 0.8
  var gradientColor: Color { Color(red: gradientR, green: gradientG, blue: gradientB) }
  var onStarTapped: (() -> Void)? = nil

  private var totalStars: Int {
    let minutes = recentCompletedSessions.map { Int($0.duration / 60) }.reduce(0, +)
    return minutes * 10
  }

  @AppStorage("selectedCreatureName") private var selectedCreatureName: String = "Leafeon"

  var body: some View {
    TopStreakCard(
      totalStars: totalStars,
      gifName: selectedCreatureName,
      gradientColor: gradientColor,
      onStarTapped: onStarTapped
    )
  }
}


