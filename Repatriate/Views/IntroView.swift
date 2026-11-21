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
    /// When true (Reduce Motion), words cross-dissolve instead of scrolling.
    var dissolve = false

    /// Clipped window onto the stacked words (or a cross-dissolve).
    var body: some View {
        if dissolve {
            ZStack(alignment: .leading) {
                // Invisible longest word keeps the width stable.
                Text(words.max(by: { $0.count < $1.count }) ?? "").font(font).hidden()
                Text(words[step]).font(font).id(step).transition(.opacity)
            }
            .frame(height: rowHeight)
        } else {
            scrolling
        }
    }

    /// The scrolling reel: stacked words offset so one row shows.
    private var scrolling: some View {
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

/// Opening animation shown before authentication (about 9 seconds).
///
/// 1. 0 to 7s: "RECYCLE" fades in, the reel cycles through REUSE, RECOVER,
///    RETURN and REFURB, then the whole word is erased right to left.
/// 2. 7 to 8.5s: the supplied Recipero logo replaces it and settles.
/// 3. Then the logo glides to the top of the screen as the ground fades
///    from brand red to white, landing exactly where `BrandBar` sits.
struct IntroView: View {
    /// Called once the animation has finished.
    let onFinished: () -> Void

    /// Suffixes that follow the fixed "RE": RECYCLE, REUSE, RECOVER, RETURN, REFURB.
    private let suffixes = ["CYCLE", "USE", "COVER", "TURN", "FURB"]
    /// Widest word; fixes the stage width so erasing stays left-anchored.
    private let widestWord = "RECYCLE"

    /// Reel position (index into `suffixes`).
    @State private var step = 0
    /// Opacity of the word stage.
    @State private var wordOpacity = 0.0
    /// True while the word is being erased (reel swapped for plain text).
    @State private var erasing = false
    /// How many letters have been erased from the right.
    @State private var erased = 0
    /// 0 = logo hidden, 1 = shown.
    @State private var logoShown = 0.0
    /// 0 = white logo (on red), 1 = colour logo (on white).
    @State private var colourMix = 0.0
    /// Rendered height of the logo (shrinks as it moves up).
    @State private var logoHeight: CGFloat = 56
    /// Whether the logo has moved to the top bar position.
    @State private var atTop = false
    /// Opacity of the red ground over the white one.
    @State private var redOpacity = 1.0
    /// Honour the system "Reduce Motion" setting.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Type style for the words.
    private let font = Font.system(size: 44, weight: .semibold)

    /// Red-over-white ground, the word stage and the logo.
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white
                Theme.red.opacity(redOpacity)

                // The word stage: fixed "RE" plus the reel, or erasing text.
                ZStack(alignment: .leading) {
                    Text(widestWord).font(font).hidden()
                    if erasing {
                        Text(String(("RE" + suffixes[suffixes.count - 1]).dropLast(erased)))
                            .font(font)
                    } else {
                        HStack(spacing: 0) {
                            Text("RE").font(font)
                            SlotReel(words: suffixes, step: step, font: font,
                                     rowHeight: 54, dissolve: reduceMotion)
                        }
                    }
                }
                .foregroundStyle(.white)
                .opacity(wordOpacity)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                // The supplied logo, white on red then colour on white.
                ZStack {
                    ReciperoLogo(style: .white, height: logoHeight)
                        .opacity(logoShown * (1 - colourMix))
                    ReciperoLogo(style: .colour, height: logoHeight)
                        .opacity(logoShown * colourMix)
                }
                .position(x: proxy.size.width / 2,
                          y: atTop ? proxy.safeAreaInsets.top + BrandBar.height / 2
                                   : proxy.size.height / 2)
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recipero")
        .task { await play() }
    }

    /// Runs the whole timeline.
    private func play() async {
        // Reduce Motion swaps scrolling for dissolves, with the same timing.
        let move: Animation = reduceMotion ? .easeInOut(duration: 0.3)
                                           : .timingCurve(0.2, 0, 0, 1, duration: 0.35)

        // Word phase (0 to 7s): fade in RECYCLE, cycle the reel, erase.
        withAnimation(.easeOut(duration: 0.4)) { wordOpacity = 1 }
        try? await Task.sleep(for: .seconds(1.25))
        for index in 1..<suffixes.count {
            withAnimation(move) { step = index }
            // The last word (REFURB) gets a slightly shorter dwell so the erase ends at 7s.
            try? await Task.sleep(for: .seconds(index == suffixes.count - 1 ? 1.2 : 1.25))
        }
        erasing = true
        let letters = ("RE" + suffixes[suffixes.count - 1]).count
        for count in 1...letters {
            erased = count
            try? await Task.sleep(for: .seconds(0.13))
        }
        wordOpacity = 0

        // Logo phase (7 to 8.5s): the supplied logo replaces the word and settles.
        withAnimation(.easeOut(duration: 0.4)) { logoShown = 1 }
        try? await Task.sleep(for: .seconds(1.5))

        // Glide to the top bar while the ground fades from red to white.
        withAnimation(.timingCurve(0.2, 0, 0, 1, duration: 0.9)) {
            atTop = true
            logoHeight = BrandBar.logoHeight
            redOpacity = 0
            colourMix = 1
        }
        try? await Task.sleep(for: .seconds(1.0))
        onFinished()
    }
}

#Preview {
    IntroView(onFinished: {})
}
