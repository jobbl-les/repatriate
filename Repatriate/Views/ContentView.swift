import SwiftUI

/// Root view: switches between the flow's steps based on the view model phase.
struct ContentView: View {
    /// Owns the flow state for the lifetime of the app.
    @StateObject private var model = LookupViewModel()

    /// The step currently on screen.
    var body: some View {
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
            .navigationTitle("Repatriate")
        }
    }
}

#Preview {
    ContentView()
}
