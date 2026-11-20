import SwiftUI

/// A single slot-machine style reel that scrolls vertically through words.
///
/// The reel is as wide as its longest word and one row tall; the words
/// are stacked and the stack is offset so only the current row is visible.
struct SlotReel: View {
    /// Words on the reel, top to bottom.
    let words: [String]
    /// Index of the word currently in the window.
    let step: Int
    /// Font used for every word.
    let font: Font
    /// Height of one row (and of the visible window).
    let rowHeight: CGFloat

    /// Clipped window onto the stacked words.
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Invisible copy of the longest word fixes the window width.
            Text(words.max(by: { $0.count < $1.count }) ?? "")
                .font(font)
                .hidden()
            VStack(alignment: .leading, spacing: 0) {
                ForEach(words.indices, id: \.self) { index in
                    Text(words[index])
                        .font(font)
                        .frame(height: rowHeight, alignment: .leading)
                }
            }
            .offset(y: -CGFloat(step) * rowHeight)
        }
        .frame(height: rowHeight, alignment: .top)
        .clipped()
    }
}

/// Opening animation shown before authentication.
///
/// Starts on the supplied Recipero logo, dissolves to "RECIPERO" set in
/// type, spins the "CIPERO" reel through a series of RE- words like a slot
/// machine, and lands on the app name, REPATRIATE. Runs a few seconds.
struct IntroView: View {
    /// Called once the animation has finished.
    let onFinished: () -> Void

    /// Suffixes that follow the fixed "RE"; the first reads "RECIPERO",
    /// the last is the app name.
    private let suffixes = ["CIPERO", "COVERY", "UNITE", "COVER", "TURN", "CYCLE", "PATRIATE"]

    /// Reel position (index into `suffixes`).
    @State private var step = 0
    /// Whether the supplied logo (rather than the set type) is showing.
    @State private var showLogo = true
    /// Honour the system "Reduce Motion" setting.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Type style for the wordmark-like text.
    private let font = Font.system(size: 44, weight: .semibold)

    /// Brand red ground with the logo / reel centred.
    var body: some View {
        ZStack {
            Theme.red.ignoresSafeArea()

            // Set type: fixed "RE" followed by the spinning reel.
            HStack(spacing: 0) {
                Text("RE").font(font)
                SlotReel(words: suffixes, step: step, font: font, rowHeight: 54)
            }
            .foregroundStyle(.white)
            .opacity(showLogo ? 0 : 1)

            // The supplied logo file opens the sequence.
            ReciperoLogo(style: .white, height: 44)
                .opacity(showLogo ? 1 : 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recipero Repatriate")
        .task { await play() }
    }

    /// Runs the timeline: logo hold, dissolve, spin, land, hold.
    private func play() async {
        // Reduced motion: show the app name briefly with no spinning.
        if reduceMotion {
            step = suffixes.count - 1
            showLogo = false
            try? await Task.sleep(for: .seconds(1.2))
            onFinished()
            return
        }

        // 1. Hold on the official logo.
        try? await Task.sleep(for: .seconds(0.7))
        // 2. Dissolve to the set type reading RECIPERO.
        withAnimation(.easeOut(duration: 0.25)) { showLogo = false }
        try? await Task.sleep(for: .seconds(0.6))
        // 3. Spin through the intermediate RE- words (smooth ease-out, no bounce).
        let move = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.24)
        for index in 1..<(suffixes.count - 1) {
            withAnimation(move) { step = index }
            try? await Task.sleep(for: .seconds(0.32))
        }
        // 4. Land on the app name with a slower final settle.
        withAnimation(.timingCurve(0.2, 0, 0, 1, duration: 0.6)) { step = suffixes.count - 1 }
        try? await Task.sleep(for: .seconds(1.3))
        onFinished()
    }
}

#Preview {
    IntroView(onFinished: {})
}
