import SwiftUI
import UIKit

struct ShopView: View {
  // All available creatures (names should match files in Resources/GIFS without .gif)
  private let items = [
    "Eevee", "Espeon", "Glaceon", "Haunter", "Houndour",
    "Leafeon", "Mantine", "Mew", "Umbreon", "Vaporeon", "Weezing"
  ]
  @AppStorage("selectedCreatureName") private var selectedCreatureName: String = "Leafeon"
  @AppStorage("gradientR") private var gradientR: Double = 0.5
  @AppStorage("gradientG") private var gradientG: Double = 0.0
  @AppStorage("gradientB") private var gradientB: Double = 0.8
  @State private var pickColor: Color = .purple
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section("Gradient") {
          ColorPicker("Background Color", selection: $pickColor)
            .onChange(of: pickColor) { _, newValue in
              if let comps = UIColor(newValue).cgColor.components, comps.count >= 3 {
                gradientR = Double(comps[0])
                gradientG = Double(comps[1])
                gradientB = Double(comps[2])
              }
            }
        }
        Section("Creatures") {
          ForEach(items, id: \.self) { name in
            HStack(spacing: 16) {
              GIFView(gifName: name, subdirectory: "Resources/GIFS")
                .id(name)
                .frame(width: 64, height: 64)
                .cornerRadius(8)
              Text(name)
              Spacer()
              if selectedCreatureName == name {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
              } else {
                Button("Select") { selectedCreatureName = name }
                  .buttonStyle(.bordered)
              }
            }
            .padding(.vertical, 6)
          }
        }
      }
      .navigationTitle("Creatures Shop")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") { dismiss() }
        }
      }
    }
    .onAppear {
      pickColor = Color(red: gradientR, green: gradientG, blue: gradientB)
    }
  }
}


