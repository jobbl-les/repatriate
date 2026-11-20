import SwiftUI

/// Lists the special SIM cards (1...6) for the user to choose from.
struct SIMPickerView: View {
    /// Called with the SIM the user tapped.
    let onSelect: (SpecialSIM) -> Void

    /// Two-column grid of large numbered buttons.
    var body: some View {
        ScrollView {
            Text("Which special SIM card are you using?")
                .font(.headline)
                .padding(.top)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                ForEach(SpecialSIM.all) { sim in
                    Button { onSelect(sim) } label: {
                        Text("\(sim.id)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 100)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(sim.title)
                }
            }
            .padding()
        }
    }
}
