import SwiftUI

struct ProfileStreakRow: View {
  let sessions: [BlockedProfileSession]

  var streak: Int {
    StatsUtil.consecutiveDayStreak(from: sessions)
  }

  var body: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Streak")
          .font(.caption)
          .foregroundColor(.secondary)
        HStack(spacing: 6) {
          Image(systemName: "flame.fill").foregroundColor(.orange)
          Text("\(streak) day\(streak == 1 ? "" : "s")")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
      }

      Divider().frame(height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text("Completed Sessions")
          .font(.caption)
          .foregroundColor(.secondary)
        Text("\(sessions.count)")
          .font(.subheadline)
          .fontWeight(.semibold)
      }
    }
  }
}

#Preview {
  ProfileStreakRow(sessions: [])
    .padding()
    .background(Color(.systemGroupedBackground))
}


