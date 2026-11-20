import Foundation

/// Static configuration for talking to the NMPR web service.
///
/// Values here are scaffolding only. No API key has been issued yet, so
/// `agentId` is a placeholder and `isConfigured` reports `false` until it is
/// replaced. Later this should move to the Keychain or a build-time secret
/// rather than living in source control.
enum AppConfig {
    /// Base URL of the NMPR API (from the `servers` block of nmpr-v2.yaml).
    static let baseURL = URL(string: "https://api.recipero.com/nmpr/v2")!

    /// Marker value meaning "no real credential has been supplied yet".
    static let placeholderAgentId = "REPLACE_WITH_NMPR_PERSONAL_ACCESS_TOKEN"

    /// The NMPR Personal Access Token / agent id sent as `agentId`.
    /// TODO: load from the Keychain once a key has been issued.
    static let agentId = placeholderAgentId

    /// Reason code recorded against each search. Must be one of the enum
    /// values accepted by the API (`training` is the safest default while
    /// the app is being developed).
    static let reasonCode = "training"

    /// Ask the API to refresh network / SIM-swap / IMEI data for the MSISDN.
    /// Requires Number Intel permission on the account.
    static let updateMobileNetworkStatus = true

    /// Also return events for identifiers related to the MSISDN (e.g. IMEIs).
    static let includeRelatedEvents = false

    /// Whether a real credential has been supplied.
    static var isConfigured: Bool { agentId != placeholderAgentId }
}
