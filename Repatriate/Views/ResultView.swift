import SwiftUI

/// Displays the raw API output (or error text) for a lookup.
struct ResultView: View {
    /// The SIM that was looked up.
    let sim: SpecialSIM
    /// Raw response text to show verbatim.
    let text: String
    /// Return to the SIM chooser.
    let onDone: () -> Void

    /// Monospaced, selectable raw output with a Done button.
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(sim.title) — \(sim.msisdn)")
                .font(.headline)
            ScrollView {
                Text(text)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}
