import SwiftUI

/// Branded sign-in screen shown until Face ID succeeds.
struct LockView: View {
    /// Gate state to display (idle, in progress, or an error message).
    let state: AuthViewModel.State
    /// Start (or retry) Face ID authentication.
    let onAuthenticate: () -> Void

    /// Red ground, white logo, app name, status text and a sign-in button.
    var body: some View {
        ZStack {
            Theme.red.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                ReciperoLogo(style: .white, height: 36)
                Text("Repatriate")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                Image(systemName: "faceid")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                // Show a failure reason when authentication did not succeed.
                if case .failed(let message) = state {
                    Text(message)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                Button(action: onAuthenticate) {
                    Label("Sign in with Face ID", systemImage: "faceid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Theme.red) // red label on the white button (5.2:1)
                .controlSize(.large)
                .disabled(state == .authenticating)
                Spacer()
            }
            .padding(32)
        }
    }
}
