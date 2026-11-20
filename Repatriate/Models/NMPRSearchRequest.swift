import Foundation

/// Request body for `POST /search` (schema `NMPR_Search_Request`).
///
/// Only the properties this app needs are modelled. Optional properties are
/// omitted from the JSON when `nil` because `JSONEncoder` skips nil optionals.
struct NMPRSearchRequest: Encodable {
    /// The identifier to search; here, the SIM's MSISDN.
    let identifier: String

    /// ID / Personal Access Token of the agent performing the search.
    let agentId: String

    /// Reason for the search (one of the API's `reasonCode` enum values).
    let reasonCode: String

    /// Refresh current/origin network, SIM/device swap and IMEI for an MSISDN.
    let updateMobileNetworkStatus: Bool?

    /// Include events for identifiers related to the one searched.
    let includeRelatedEvents: Bool?
}
