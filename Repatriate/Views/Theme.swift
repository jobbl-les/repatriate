import SwiftUI

/// Recipero brand tokens and reusable branded components.
///
/// Values come from the Recipero Brand Identity Guide (design-system
/// artifact, tokens.json). Red and white lead; black is for text.
enum Theme {
    /// Brand red #db052c (always used at 100% strength).
    static let red = Color(red: 219 / 255, green: 5 / 255, blue: 44 / 255)

    /// 5% tint of black #f2f2f2, the standard light panel ground.
    static let grey05 = Color(red: 242 / 255, green: 242 / 255, blue: 242 / 255)
}

/// Which supplied logo colourway to show.
enum LogoStyle {
    /// Red symbol, black wordmark: for white / light-grey grounds.
    case colour
    /// All white: for the brand red ground.
    case white

    /// Name of the image set in Assets.xcassets.
    var assetName: String {
        switch self {
        case .colour: return "ReciperoLogoColour"
        case .white: return "ReciperoLogoWhite"
        }
    }
}

/// The supplied Recipero logo file, unmodified (never redrawn or recoloured).
struct ReciperoLogo: View {
    /// Colourway matching the ground the logo sits on.
    let style: LogoStyle
    /// Rendered height in points. The brand minimum is about 20pt on screen.
    var height: CGFloat = 28

    /// The logo image, scaled proportionally to the requested height.
    var body: some View {
        Image(style.assetName)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("Recipero")
    }
}
