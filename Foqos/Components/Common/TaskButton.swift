import SwiftUI

struct TaskButton: View {
  var title: String
  var task: () async -> ()
  var onStatusChange: (Bool) -> () = { _ in }
  @State private var isLoading: Bool = false
  var body: some View {
    Button {
      Task {
        isLoading = true
        await task()
        try? await Task.sleep(for: .seconds(0.1))
        isLoading = false
      }
    } label: {
      Text(title)
        .font(.callout)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .opacity(isLoading ? 0 : 1)
        .overlay {
          ProgressView()
            .tint(.white)
            .opacity(isLoading ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
    .tint(.accentColor)
    .buttonStyle(.borderedProminent)
    .buttonBorderShape(.capsule)
    .animation(.easeInOut(duration: 0.25), value: isLoading)
    .disabled(isLoading)
    .onChange(of: isLoading) { oldValue, newValue in
      withAnimation(.easeInOut(duration: 0.25)) {
        onStatusChange(newValue)
      }
    }
  }
}


