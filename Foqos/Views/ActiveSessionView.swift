import SwiftUI
import SwiftData

struct ActiveSessionView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.openURL) private var openURL
  @EnvironmentObject var strategyManager: StrategyManager

  @State private var showEndBurst = false
  @State private var starsPulse = false

  private let starsPerMinute: Int = 10

  private func timeString(_ t: TimeInterval) -> String {
    let h = Int(t) / 3600, m = Int(t) / 60 % 60, s = Int(t) % 60
    return String(format: "%02d:%02d:%02d", h, m, s)
  }

  private var minutesElapsed: Int {
    max(0, Int(strategyManager.elapsedTime / 60))
  }

  private var starsEarned: Int {
    minutesElapsed * starsPerMinute
  }

  var body: some View {
    let session = strategyManager.activeSession
    let profile = session?.blockedProfile

    ZStack {
      VStack(spacing: 24) {
        Text(profile?.name ?? "Session")
          .font(.title2).bold()

        // Timer
        Text(timeString(strategyManager.elapsedTime))
          .font(.system(size: 44, weight: .bold, design: .rounded))
          .monospacedDigit()

        // Stars earned
        HStack(spacing: 8) {
          Image(systemName: "star.fill")
            .foregroundColor(.yellow)
            .shadow(color: .yellow.opacity(0.5), radius: 8, x: 0, y: 0)
            .scaleEffect(starsPulse ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: starsPulse)
          Text("\(starsEarned) stars")
            .font(.system(size: 24, weight: .semibold))
            .contentTransition(.numericText())
            .animation(.easeOut(duration: 0.25), value: starsEarned)
        }

        Text("+\(starsPerMinute) ★ per minute")
          .font(.footnote)
          .foregroundColor(.secondary)

        if let urlString = profile?.deeplinkURL, let url = URL(string: urlString) {
          Button {
            openURL(url)
          } label: {
            Label("Open Allowed App", systemImage: "link")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
        }

        Button {
          withAnimation(.easeOut(duration: 0.6)) { showEndBurst = true }
          // finish the session slightly after the animation kicks in
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            strategyManager.toggleBlocking(context: context, activeProfile: nil)
            showEndBurst = false
          }
        } label: {
          Label("End Session", systemImage: "stop.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        Spacer()
      }
      .padding(20)
      .onAppear { starsPulse = true }

      // Simple end-session star burst
      if showEndBurst {
        Image(systemName: "star.fill")
          .font(.system(size: 140))
          .foregroundColor(.yellow)
          .scaleEffect(showEndBurst ? 1.2 : 0.1)
          .opacity(showEndBurst ? 0.0 : 0.9)
          .transition(.scale.combined(with: .opacity))
          .allowsHitTesting(false)
      }
    }
    .interactiveDismissDisabled(true)
  }
}