import SwiftUI

/// Application entry point.
///
/// Repatriate identifies the MSISDN of a SIM by looking it up against the
/// NMPR v2 `/search` endpoint once the user has confirmed the SIM has
/// registered on a network.
@main
struct RepatriateApp: App {
    /// The root scene: a single window hosting the SIM selection flow.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
