import SwiftUI

struct FeedView: View {
  var body: some View {
    VStack(spacing: 12) {
      Text("Feed coming soon")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(Color(.systemBackground))
  }
}


