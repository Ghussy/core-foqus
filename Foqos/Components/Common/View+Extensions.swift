import SwiftUI

extension View {
  var isiOS26: Bool {
    if #available(iOS 26, *) {
      return true
    }
    return false
  }

  @ViewBuilder
  func sheetAlert(
    isPresented: Binding<Bool>,
    prominentSymbol: String,
    title: String,
    message: String,
    buttonTitle: String,
    buttonAction: @escaping () async -> ()
  ) -> some View {
    self
      .sheet(isPresented: isPresented) {
        VStack(spacing: 15) {
          Image(systemName: prominentSymbol)
            .font(.system(size: 100))

          VStack(alignment: .center, spacing: 6) {
            Text(title)
              .lineLimit(1)

            Text(message)
              .font(.caption)
              .lineLimit(2)
              .foregroundStyle(.gray)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

          TaskButton(title: buttonTitle) {
            await buttonAction()
          }
        }
        .padding([.horizontal, .top], 20)
        .padding(.bottom, isiOS26 ? 20 : 10)
        .presentationBackground(.background)
        .presentationDetents([.height(270)])
        .presentationCornerRadius(isiOS26 ? nil : 30)
        .ignoresSafeArea(isiOS26 ? .all : [])
        .interactiveDismissDisabled()
      }
  }

  @ViewBuilder
  func customAlert(_ modal: Binding<AlertModal>) -> some View {
    self.sheetAlert(
      isPresented: modal.show,
      prominentSymbol: modal.wrappedValue.icon,
      title: modal.wrappedValue.title,
      message: modal.wrappedValue.message,
      buttonTitle: "Done"
    ) {
      if let action = modal.wrappedValue.action {
        action()
      } else {
        modal.wrappedValue.show = false
      }
    }
  }
}

struct AlertModal {
  var icon: String = "exclamationmark.triangle.fill"
  var title: String = "Something Went Wrong!"
  var message: String
  var show: Bool = false
  var action: (() -> ())? = nil
}


