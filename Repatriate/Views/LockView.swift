import SwiftUI

/// Sign-in screen shown while waiting for (or after a failed) Face ID check.
///
/// The Recipero logo is supplied by the surrounding `BrandBar`, so this view
/// only carries the Face ID prompt, any error message and a retry button.
struct LockView: View {
    /// Gate state to display (idle, in progress, or an error message).
    let state: AuthViewModel.State
    /// Start (or retry) Face ID authentication.
    let onAuthenticate: () -> Void

    /// Face ID glyph, status text and a sign-in button on a white ground.
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "faceid")
                .font(.system(size: 64))
                .foregroundStyle(Theme.red)
            // Show a failure reason when authentication did not succeed.
            if case .failed(let message) = state {
                Text(message)
                    .font(.footnote.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            Button(action: onAuthenticate) {
                Label("Sign in with Face ID", systemImage: "faceid")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.red)
            .controlSize(.large)
            .disabled(state == .authenticating)
            Spacer()
        }
        .padding(32)
    }
}
