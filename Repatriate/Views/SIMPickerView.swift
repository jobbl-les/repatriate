import SwiftUI

/// Button style that draws its label on a nano-SIM shaped red card.
struct SIMCardButtonStyle: ButtonStyle {
    /// Renders the label in white on the card, dimming slightly while pressed.
    /// - Parameter configuration: The button's label and pressed state.
    /// - Returns: The styled button.
    func makeBody(configuration: Configuration) -> some View {
        // The shape fills the column width; the aspect ratio then sets its
        // height to true nano-SIM proportions, and the label sits on top.
        NanoSIMShape()
            .fill(Theme.red)
            .aspectRatio(NanoSIMShape.aspectRatio, contentMode: .fit)
            .overlay(configuration.label.foregroundStyle(.white))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Lists the special SIM cards (1...6) for the user to choose from.
struct SIMPickerView: View {
    /// Called with the SIM the user tapped.
    let onSelect: (SpecialSIM) -> Void

    /// Two-column grid of nano-SIM shaped numbered cards.
    var body: some View {
        ScrollView {
            Text("Which special SIM card are you using?")
                .font(.headline)
                .padding(.top)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                      spacing: 16) {
                ForEach(SpecialSIM.all) { sim in
                    Button { onSelect(sim) } label: {
                        Text("\(sim.id)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                    }
                    .buttonStyle(SIMCardButtonStyle())
                    .accessibilityLabel(sim.title)
                }
            }
            .padding()
        }
    }
}
