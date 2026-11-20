import SwiftUI

/// Tells the user to insert the SIM and wait for the network symbol.
struct InstructionsView: View {
    /// The SIM being used.
    let sim: SpecialSIM
    /// User says the network symbol has appeared; triggers the API search.
    let onConfirm: () -> Void
    /// User wants to go back and pick a different SIM.
    let onCancel: () -> Void

    /// Instruction text plus confirm / cancel buttons.
    var body: some View {
        VStack(spacing: 24) {
            Text(sim.title)
                .font(.largeTitle.bold())
            Text("Insert this SIM into the phone to be identified, then wait for the network symbol to appear in the top corner of its screen.")
                .multilineTextAlignment(.center)
            Button("The network symbol has appeared", action: onConfirm)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Button("Choose a different SIM", role: .cancel, action: onCancel)
        }
        .padding()
    }
}
