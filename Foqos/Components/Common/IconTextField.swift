import SwiftUI

struct IconTextField: View {
  var hint: String
  var symbol: String
  var isPassword: Bool = false
  @Binding var value: String
  var focus: FocusState<Bool>.Binding? = nil

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: symbol)
        .font(.callout)
        .foregroundStyle(.gray)
        .frame(width: 30)

      Group {
        if isPassword {
          if let focus {
            SecureField(hint, text: $value).focused(focus)
          } else {
            SecureField(hint, text: $value)
          }
        } else {
          if let focus {
            TextField(hint, text: $value).focused(focus)
          } else {
            TextField(hint, text: $value)
          }
        }
      }
    }
    .padding(.horizontal, 15)
    .padding(.vertical, 12)
    .background(.ultraThinMaterial)
    .clipShape(.capsule)
  }
}