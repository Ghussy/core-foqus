import SwiftUI

let THREADS_URL = "https://www.threads.com/@softwarecuddler"
let TWITTER_URL = "https://x.com/softwarecuddler"
let DONATE_URL = "https://buymeacoffee.com/softwarecuddler"  // You can replace this with your actual donation URL

struct SupportView: View {
  @EnvironmentObject var donationManager: TipManager
  @Environment(\.openURL) private var openURL
  @State private var stampScale: CGFloat = 0.1
  @State private var stampRotation: Double = 0
  @State private var stampOpacity: Double = 0.0

  var body: some View {
    // Thank you stamp image and header
    VStack(alignment: .center, spacing: 30) {
      Spacer()

      Image("ThankYouStamp")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 300, height: 300)
        .scaleEffect(stampScale)
        .rotationEffect(.degrees(stampRotation))
        .opacity(stampOpacity)
        .onAppear {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
            stampScale = 1
            stampRotation = 8
            stampOpacity = 1
          }
        }
        .padding(.bottom, 20)

      Text(
        "Thank you for your support! I created Foqos because I believe everyone deserves tools to live with more focus and intention. Your support, whether through reviews, shares, or donations helps keep this dream alive and accessible to everyone who needs it"
      )
      .font(.body)
      .multilineTextAlignment(.center)
      .foregroundColor(.secondary)
      .fadeInSlide(delay: 0.3)

      Text(
        "Questions? Reach out to me."
      )
      .font(.body)
      .multilineTextAlignment(.center)
      .foregroundColor(.secondary)
      .fadeInSlide(delay: 0.4)

      HStack(alignment: .center, spacing: 20) {
        Link(destination: URL(string: THREADS_URL)!) {
          Image("Threads")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 30, height: 30)
        }

        Link(destination: URL(string: TWITTER_URL)!) {
          Image("Twitter")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 30, height: 30)
        }
      }
      .fadeInSlide(delay: 0.5)

      Spacer()

      ActionButton(
        title: donationManager.hasPurchasedTip ? "Thank you for the donation" : "Donate",
        backgroundColor: donationManager.hasPurchasedTip ? .gray : .green,
        iconName: "heart.fill",
        iconColor: donationManager.hasPurchasedTip ? .red : nil,
        isLoading: donationManager.loadingTip,
        action: {
          if !donationManager.hasPurchasedTip {
            donationManager.tip()
          }
        }
      )
      .fadeInSlide(delay: 0.6)

      // Test Gospel Library Deeplink
      ActionButton(
        title: "Test Gospel Library Link",
        backgroundColor: .blue,
        iconName: "book.fill",
        isLoading: false,
        action: {
          // Example: Matthew 5:16 in English
          let deeplink = URL(string: "gospellibrary://content/scriptures/nt/matt/5?id=p16&lang=eng#p16")!

          if UIApplication.shared.canOpenURL(deeplink) {
            UIApplication.shared.open(deeplink)
          } else {
            // HTTPS universal link fallback (will open in app if installed)
            if let httpsURL = URL(string: "https://www.churchofjesuschrist.org/study/scriptures/nt/matt/5?lang=eng#p16") {
              openURL(httpsURL)
            }
          }
        }
      )
      .fadeInSlide(delay: 0.65)
    }
    .padding(.horizontal, 20)
  }
}

#Preview {
  NavigationView {
    SupportView()
      .environmentObject(TipManager())
  }
}
