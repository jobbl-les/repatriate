import SwiftUI

/// A nano-SIM outline: 12.3 x 8.8 mm with one clipped (chamfered) corner.
///
/// Dimensions follow the 4FF nano-SIM standard and scale with the rect given,
/// so the shape keeps true proportions whenever it is drawn at an aspect
/// ratio of `NanoSIMShape.aspectRatio`. The clipped corner is top-right, the
/// usual orientation when the contacts face up.
struct NanoSIMShape: Shape {
    /// Width divided by height of a real nano-SIM (12.3 / 8.8).
    static let aspectRatio: CGFloat = 12.3 / 8.8

    /// Card width in millimetres, used to convert the other measurements.
    private static let widthMM: CGFloat = 12.3
    /// Size of the clipped corner in millimetres (each leg of the cut).
    private static let chamferMM: CGFloat = 2.6
    /// Corner rounding in millimetres.
    private static let radiusMM: CGFloat = 0.8

    /// Builds the outline: a rectangle with the top-right corner cut off and
    /// every corner slightly rounded.
    /// - Parameter rect: The rectangle to draw into.
    /// - Returns: The nano-SIM outline path.
    func path(in rect: CGRect) -> Path {
        // Points per millimetre at the size we are drawing.
        let scale = rect.width / Self.widthMM
        let cut = Self.chamferMM * scale
        let radius = Self.radiusMM * scale

        // Corners, clockwise from top-left; the top-right corner is clipped.
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX - cut, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY + cut),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]

        // Rounded polygon: start mid-way along the first edge, then round
        // each corner with a tangent arc.
        var path = Path()
        let start = CGPoint(x: (corners[0].x + corners[1].x) / 2,
                            y: (corners[0].y + corners[1].y) / 2)
        path.move(to: start)
        for index in 1...corners.count {
            path.addArc(tangent1End: corners[index % corners.count],
                        tangent2End: corners[(index + 1) % corners.count],
                        radius: radius)
        }
        path.closeSubpath()
        return path
    }
}
