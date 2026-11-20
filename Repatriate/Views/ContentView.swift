import SwiftUI

/// Root view: intro animation -> Face ID gate -> SIM lookup flow.
struct ContentView: View {
    /// Owns the flow state for the lifetime of the app.
    @StateObject private var model = LookupViewModel()
    /// Face ID gate; the lookup flow is hidden until it unlocks.
    @StateObject private var auth = AuthViewModel()
    /// Whether the opening animation has finished (plays once per launch).
    @State private var introFinished = false
    /// Used to re-lock the app when it goes to the background.
    @Environment(\.scenePhase) private var scenePhase

    /// Intro first, then either the lock screen or the lookup flow.
    var body: some View {
        Group {
            if !introFinished {
                IntroView {
                    introFinished = true
                    // Prompt for Face ID as soon as the intro ends.
                    Task { await auth.authenticate() }
                }
            } else if auth.state == .unlocked {
                lookupFlow
            } else {
                LockView(state: auth.state) { Task { await auth.authenticate() } }
            }
        }
        // Re-lock on background; prompt again when returning to the app.
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: auth.lock()
            case .active where introFinished: Task { await auth.authenticate() }
            default: break
            }
        }
    }

    /// The SIM lookup flow, shown once authenticated.
    private var lookupFlow: some View {
        NavigationStack {
            Group {
                switch model.phase {
                case .selecting:
                    SIMPickerView(onSelect: model.select)
                case .waitingForNetwork(let sim):
                    InstructionsView(sim: sim,
                                     onConfirm: { Task { await model.networkSymbolAppeared(for: sim) } },
                                     onCancel: model.reset)
                case .searching(let sim):
                    ProgressView("Looking up \(sim.title)…")
                case .result(let sim, let text):
                    ResultView(sim: sim, text: text, onDone: model.reset)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // The supplied colour logo on the light navigation bar.
            .toolbar { ToolbarItem(placement: .principal) { ReciperoLogo(style: .colour, height: 30) } }
        }
        .tint(Theme.red)
    }
}

#Preview {
    ContentView()
}
