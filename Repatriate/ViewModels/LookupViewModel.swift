import Foundation

/// Drives the SIM lookup flow: pick SIM -> insert & wait -> search -> result.
@MainActor
final class LookupViewModel: ObservableObject {
    /// Where the user currently is in the flow.
    enum Phase: Equatable {
        /// Choosing which numbered SIM is being used.
        case selecting
        /// Instructed to insert the SIM and wait for the network symbol.
        case waitingForNetwork(SpecialSIM)
        /// API call in flight.
        case searching(SpecialSIM)
        /// API call finished (successfully or not); raw text to display.
        case result(SpecialSIM, String)
    }

    /// Current step of the flow; the views switch on this.
    @Published private(set) var phase: Phase = .selecting

    /// Client used for the search call.
    private let client: NMPRClient

    /// - Parameter client: The NMPR client (injectable for tests/previews).
    init(client: NMPRClient = NMPRClient()) {
        self.client = client
    }

    /// The user picked a numbered SIM; show the insert-and-wait instructions.
    /// - Parameter sim: The selected special SIM.
    func select(_ sim: SpecialSIM) {
        phase = .waitingForNetwork(sim)
    }

    /// The user confirms the network symbol is showing; run the search.
    /// - Parameter sim: The SIM whose MSISDN should be looked up.
    func networkSymbolAppeared(for sim: SpecialSIM) async {
        phase = .searching(sim)
        do {
            let result = try await client.search(msisdn: sim.msisdn)
            phase = .result(sim, "HTTP \(result.statusCode)\n\n\(result.body)")
        } catch {
            phase = .result(sim, error.localizedDescription)
        }
    }

    /// Return to the SIM chooser to identify another phone.
    func reset() {
        phase = .selecting
    }
}
