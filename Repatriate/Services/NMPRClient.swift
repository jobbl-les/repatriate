import Foundation

/// Errors surfaced by `NMPRClient`.
enum NMPRError: LocalizedError {
    /// No API credential has been configured yet (scaffold state).
    case notConfigured
    /// The server answered with something that is not an HTTP response.
    case invalidResponse
    /// Transport-level failure (offline, TLS, timeout...).
    case transport(Error)

    /// Message suitable for showing to the user.
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "No NMPR API key has been configured yet. Set AppConfig.agentId."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .transport(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// The raw outcome of a search call: status code plus unparsed body text.
struct NMPRRawResult {
    /// HTTP status code returned by the service.
    let statusCode: Int
    /// Response body, pretty-printed if it was valid JSON, else verbatim.
    let body: String
}

/// Thin client for the NMPR v2 web service.
///
/// For now it returns the raw response so the UI can display it unparsed.
struct NMPRClient {
    /// Session used for requests; injectable so tests can stub the network.
    var session: URLSession = .shared

    /// Perform `POST /search` for the given MSISDN.
    ///
    /// - Parameter msisdn: The identifier to search (international format).
    /// - Returns: The HTTP status code and body text, whatever they are
    ///   (non-2xx responses are returned, not thrown, so they can be shown).
    /// - Throws: `NMPRError` if unconfigured or the request cannot complete.
    func search(msisdn: String) async throws -> NMPRRawResult {
        // Refuse to call out with the placeholder credential.
        guard AppConfig.isConfigured else { throw NMPRError.notConfigured }

        // Build the request from the YAML's /search definition.
        var request = URLRequest(url: AppConfig.baseURL.appendingPathComponent("search"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // TODO: confirm with Recipero whether an additional auth header
        // (e.g. a subscription key) is required beyond `agentId` in the body.

        let payload = NMPRSearchRequest(
            identifier: msisdn,
            agentId: AppConfig.agentId,
            reasonCode: AppConfig.reasonCode,
            updateMobileNetworkStatus: AppConfig.updateMobileNetworkStatus,
            includeRelatedEvents: AppConfig.includeRelatedEvents
        )
        request.httpBody = try JSONEncoder().encode(payload)

        // Send it, mapping transport failures into our error type.
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NMPRError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else { throw NMPRError.invalidResponse }

        return NMPRRawResult(statusCode: http.statusCode, body: Self.prettyPrint(data))
    }

    /// Pretty-print JSON data for display; fall back to the raw text.
    ///
    /// - Parameter data: Response body bytes.
    /// - Returns: Indented JSON if parseable, otherwise the UTF-8 string.
    static func prettyPrint(_ data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(
               withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
           let text = String(data: pretty, encoding: .utf8) {
            return text
        }
        return String(data: data, encoding: .utf8) ?? "<\(data.count) bytes, not UTF-8>"
    }
}
