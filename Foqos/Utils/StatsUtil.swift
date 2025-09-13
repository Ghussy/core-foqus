import Foundation

enum StatsUtil {
  /// Calculates the current consecutive-day streak.
  /// - If there is at least one session today, count back from today.
  /// - Else, if there is at least one session yesterday, count back from yesterday.
  /// - Else, streak is 0 (you already missed the window).
  static func consecutiveDayStreak(from sessions: [BlockedProfileSession], now: Date = Date()) -> Int {
    guard !sessions.isEmpty else { return 0 }

    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: now)
    guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else { return 0 }

    // Build a set of days that have at least one session
    var activeDays: Set<Date> = []
    for s in sessions {
      activeDays.insert(calendar.startOfDay(for: s.startTime))
    }

    // Choose anchor: today if active, else yesterday if active, else no streak
    let anchor: Date
    if activeDays.contains(startOfToday) {
      anchor = startOfToday
    } else if activeDays.contains(startOfYesterday) {
      anchor = startOfYesterday
    } else {
      return 0
    }

    // Count consecutive days backwards from the anchor
    var streak = 0
    var dayCursor = anchor
    while activeDays.contains(dayCursor) {
      streak += 1
      guard let previous = calendar.date(byAdding: .day, value: -1, to: dayCursor) else { break }
      dayCursor = previous
    }
    return streak
  }
}