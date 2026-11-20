import Foundation
import LocalAuthentication

/// Mock sign-in gate backed by Face ID.
///
/// This stands in for a real authentication flow: it behaves as though the
/// user had already signed in and opted into Face ID, so launching the app
/// (or returning to it after it was backgrounded) just asks for Face ID.
/// No credentials are collected or stored.
@MainActor
final class AuthViewModel: ObservableObject {
    /// Where the gate currently is.
    enum State: Equatable {
        /// App is locked and waiting for the user to authenticate.
        case locked
        /// The Face ID prompt is on screen.
        case authenticating
        /// Authentication succeeded; app content is available.
        case unlocked
        /// Authentication failed or is unavailable; message explains why.
        case failed(String)
    }

    /// Current gate state; the views switch on this.
    @Published private(set) var state: State = .locked

    /// Prompt Face ID and unlock on success.
    ///
    /// Uses the biometrics-only policy so a passcode is not offered as an
    /// alternative; failures leave the app locked with a retry option.
    func authenticate() async {
        // Ignore taps while a prompt is already showing or when unlocked.
        guard state != .authenticating, state != .unlocked else { return }
        state = .authenticating

        let context = LAContext()
        context.localizedFallbackTitle = "" // hide the passcode fallback button
        var policyError: NSError?

        // Bail out early if biometrics are unavailable (e.g. none enrolled).
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                        error: &policyError) else {
            state = .failed(policyError?.localizedDescription ?? "Face ID is not available.")
            return
        }

        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Sign in to Repatriate")
            state = ok ? .unlocked : .failed("Authentication failed.")
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Lock the app again, e.g. when it moves to the background.
    func lock() {
        // Don't interrupt an in-flight prompt; the system backgrounds the app
        // while the Face ID sheet is up on some OS versions.
        switch state {
        case .unlocked, .failed: state = .locked
        case .locked, .authenticating: break
        }
    }
}
