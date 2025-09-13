import SwiftUI
import UIKit

struct TopStreakCard: View {
  let totalStars: Int
  let title: String?
  let subtitle: String?
  let gifName: String?
  let gradientColor: Color
  let onStarTapped: (() -> Void)?

  init(
    totalStars: Int,
    gifName: String? = nil,
    title: String? = nil,
    subtitle: String? = nil,
    gradientColor: Color = .purple,
    onStarTapped: (() -> Void)? = nil
  ) {
    self.totalStars = totalStars
    self.gifName = gifName
    self.title = title
    self.subtitle = subtitle
    self.gradientColor = gradientColor
    self.onStarTapped = onStarTapped
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      // Animated gradient-style background
      CardBackground(isActive: true, customColor: gradientColor, centered: true, blurRadius: 30)

      // Center GIF/image
      if let gifName {
        GIFView(gifName: gifName, subdirectory: "Resources/GIFS")
          .id(gifName)
          .frame(height: 320)
      } else {
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.purple.opacity(0.15))
          .frame(width: 320, height: 320)
          .overlay(Text("GIF").font(.headline).foregroundColor(.purple))
      }

      // Star count badge in corner
      Button(action: { onStarTapped?() }) {
        HStack(spacing: 6) {
          Image(systemName: "star.fill").foregroundColor(.yellow)
          Text("\(totalStars)")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
      }
      .padding(10)
      .background(.ultraThinMaterial)
      .clipShape(Capsule())
      .padding(16)
    }
    .frame(height: 360)
    .padding(.horizontal, 16)
  }
}

//#Preview {
//    TopStreakCard(totalStars: 120)
//}


