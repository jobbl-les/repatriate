#!/usr/bin/env swift
//
//  make_sim_labels.swift
//
//  Generates a full-page A4 PDF of nano-SIM labels. Printed at 100% (actual
//  size, no "fit to page") each label is exactly the size of a physical
//  nano-SIM (12.3 x 8.8 mm, 4FF), with the diagonal cut-off at lower left.
//  Each label carries a tiny pure-white Recipero logo along its top long edge
//  (the supplied logo file, never redrawn) with the number set below it.
//
//  This is a development utility. It is NOT part of the app and is not
//  compiled into it (it lives outside the Repatriate/ source folder).
//
//  Usage:   swift make_sim_labels.swift [output.pdf] [first-number]
//  Default: sim-labels.pdf, numbers starting at 100.
//
import CoreGraphics
import CoreText
import Foundation

// MARK: - Configuration (all lengths in millimetres)

/// Nano-SIM (4FF) width.
let simWidthMM: CGFloat = 12.3
/// Nano-SIM (4FF) height.
let simHeightMM: CGFloat = 8.8
/// Size of the diagonal cut at lower left (each leg of the cut).
/// Matches the nano-SIM buttons in the app.
let chamferMM: CGFloat = 2.6
/// Corner rounding, matching the app's nano-SIM shape.
let cornerRadiusMM: CGFloat = 0.8
/// Gap between labels, horizontally and vertically, for manual cutting.
let gapMM: CGFloat = 4.0
/// Minimum margin kept clear around the grid on the page edge.
let pageMarginMM: CGFloat = 8.0
/// Space kept between the digits and the left/right label edges.
let textInsetMM: CGFloat = 0.9
/// Width of the logo along the top edge (the supplied logo scaled to fit).
let logoWidthMM: CGFloat = 9.9
/// Gap between the top edge of the label and the logo.
let logoTopGapMM: CGFloat = 1.0
/// Gap between the bottom of the logo and the top of the digits.
let logoToDigitsGapMM: CGFloat = 0.8
/// Gap between the bottom edge of the label and the digits.
let digitsBottomGapMM: CGFloat = 0.9
/// Extra clearance kept between the digits and the diagonal cut.
let notchClearanceMM: CGFloat = 0.5
/// A4 page size.
let pageWidthMM: CGFloat = 210
let pageHeightMM: CGFloat = 297

/// Brand red #db052c (same value as `Theme.red` in the app).
let brandRed = CGColor(red: 219 / 255, green: 5 / 255, blue: 44 / 255, alpha: 1)
/// PostScript name of the label font (ships with macOS).
let fontName = "ArialRoundedMTBold"
/// The supplied pure-white Recipero logo (transparent PNG), as used by the app.
let logoURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Repatriate/Assets.xcassets/ReciperoLogoWhite.imageset/ReciperoLogoWhite.png")

// MARK: - Helpers

/// Converts millimetres to PDF points (1/72 inch).
/// - Parameter mm: Length in millimetres.
/// - Returns: The same length in points.
func pt(_ mm: CGFloat) -> CGFloat { mm * 72 / 25.4 }

/// Builds the nano-SIM outline with its origin at the lower-left corner.
/// The PDF coordinate system has y pointing up, so the cut is at lower left.
/// - Returns: A rounded path of size `simWidthMM` x `simHeightMM` (in points).
func nanoSIMPath() -> CGPath {
    let w = pt(simWidthMM), h = pt(simHeightMM), cut = pt(chamferMM)
    // Corners clockwise from top-left; the lower-left corner is clipped.
    let corners = [
        CGPoint(x: 0, y: h), CGPoint(x: w, y: h),
        CGPoint(x: w, y: 0), CGPoint(x: cut, y: 0), CGPoint(x: 0, y: cut)
    ]
    let path = CGMutablePath()
    // Start mid-way along the first edge, then round every corner.
    path.move(to: CGPoint(x: (corners[0].x + corners[1].x) / 2, y: (corners[0].y + corners[1].y) / 2))
    for i in 1...corners.count {
        path.addArc(tangent1End: corners[i % corners.count],
                    tangent2End: corners[(i + 1) % corners.count],
                    radius: pt(cornerRadiusMM))
    }
    path.closeSubpath()
    return path
}

/// Loads the supplied white logo PNG; stops with a message if it is missing.
/// - Returns: The logo image.
func loadLogo() -> CGImage {
    guard let provider = CGDataProvider(url: logoURL as CFURL),
          let image = CGImage(pngDataProviderSource: provider, decode: nil,
                              shouldInterpolate: true, intent: .defaultIntent) else {
        fatalError("Could not load the logo at \(logoURL.path)")
    }
    return image
}

/// Makes a CoreText line for a label number at the given font size.
/// - Parameters:
///   - text: The digits to set.
///   - size: Font size in points.
/// - Returns: The typeset line, set in white.
func makeLine(_ text: String, size: CGFloat) -> CTLine {
    let font = CTFontCreateWithName(fontName as CFString, size, nil)
    let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    let attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): white
    ]
    return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
}

/// Glyph-outline bounds of a line (the ink, not the typographic box).
/// - Parameter line: A typeset line.
/// - Returns: Tight bounds of the drawn glyphs relative to the text origin.
func inkBounds(_ line: CTLine) -> CGRect {
    CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
}

// MARK: - Layout

let args = CommandLine.arguments
let outputPath = args.count > 1 ? args[1] : "sim-labels.pdf"
let firstNumber = args.count > 2 ? Int(args[2]) ?? 100 : 100

let labelW = pt(simWidthMM), labelH = pt(simHeightMM)
let gap = pt(gapMM)
let pageW = pt(pageWidthMM), pageH = pt(pageHeightMM)

// How many labels fit, keeping at least the page margin clear.
let usableW = pageW - 2 * pt(pageMarginMM)
let usableH = pageH - 2 * pt(pageMarginMM)
let columns = Int(floor((usableW + gap) / (labelW + gap)))
let rows = Int(floor((usableH + gap) / (labelH + gap)))
let count = columns * rows

// Centre the grid on the page.
let gridW = CGFloat(columns) * labelW + CGFloat(columns - 1) * gap
let gridH = CGFloat(rows) * labelH + CGFloat(rows - 1) * gap
let originX = (pageW - gridW) / 2
let originY = (pageH - gridH) / 2

// MARK: - Font size and vertical placement

// The logo sits at the top; the digits get the space below it. One font size
// and one baseline are used for every label so they all match.
let logo = loadLogo()
let logoW = pt(logoWidthMM)
let logoH = logoW * CGFloat(logo.height) / CGFloat(logo.width)
let logoX = (labelW - logoW) / 2
let logoY = labelH - pt(logoTopGapMM) - logoH
/// Highest point the digits may reach (below the logo).
let digitsTop = logoY - pt(logoToDigitsGapMM)
/// Lowest point the digits may reach (above the bottom edge).
let digitsBottomLimit = pt(digitsBottomGapMM)

let numbers = (0..<count).map { String(firstNumber + $0) }
let refSize: CGFloat = 100
let refInks = numbers.map { inkBounds(makeLine($0, size: refSize)) }
let widestInk = refInks.map { $0.width }.max() ?? 1      // at refSize
let tallestInk = refInks.map { $0.maxY }.max() ?? 1      // highest point above baseline
let lowestInk = refInks.map { $0.minY }.min() ?? 0       // lowest point (overshoot), <= 0

// Start from the widest size that fits between the side insets, then shrink
// until the digits fit between the logo and the diagonal cut.
var fontSize = refSize * (labelW - 2 * pt(textInsetMM)) / widestInk
var digitsBottom = digitsBottomLimit   // bottom of the digits' ink box (points)
let cutLen = pt(chamferMM)
while fontSize > 1 {
    let k = fontSize / refSize
    let inkWidth = widestInk * k
    let inkHeight = (tallestInk - lowestInk) * k
    // The cut runs from (0, cut) to (cut, 0): y = cut - x. Keep the
    // lower-left of the widest number above that line plus the clearance.
    let inkLeft = (labelW - inkWidth) / 2
    let notchBottom = (cutLen - inkLeft) + pt(notchClearanceMM)
    digitsBottom = max(digitsBottomLimit, notchBottom)
    if digitsBottom + inkHeight <= digitsTop { break }
    fontSize *= 0.99
}
/// Shared baseline: puts the lowest ink of any label at `digitsBottom`.
let baselineY = digitsBottom - lowestInk * (fontSize / refSize)

// MARK: - Draw

var mediaBox = CGRect(x: 0, y: 0, width: pageW, height: pageH)
let info = [kCGPDFContextTitle as String: "Nano SIM labels",
            kCGPDFContextCreator as String: "make_sim_labels.swift"] as CFDictionary
guard let context = CGContext(URL.init(fileURLWithPath: outputPath) as CFURL, mediaBox: &mediaBox, info) else {
    fatalError("Could not create PDF at \(outputPath)")
}
context.beginPDFPage(nil)

let outline = nanoSIMPath()
var worstClearance = CGFloat.greatestFiniteMagnitude   // tightest gap to the cut (points)
let cut = cutLen

for (index, number) in numbers.enumerated() {
    // Row 0 is the top row; PDF y grows upwards.
    let col = index % columns, row = index / columns
    let x = originX + CGFloat(col) * (labelW + gap)
    let y = originY + gridH - CGFloat(row + 1) * labelH - CGFloat(row) * gap

    context.saveGState()
    context.translateBy(x: x, y: y)

    // Red nano-SIM background.
    context.setFillColor(brandRed)
    context.addPath(outline)
    context.fillPath()

    // Pure-white logo along the top long edge.
    context.draw(logo, in: CGRect(x: logoX, y: logoY, width: logoW, height: logoH))

    // Digits: centred horizontally on their own ink, common baseline.
    let line = makeLine(number, size: fontSize)
    let ink = inkBounds(line)
    let textX = (labelW - ink.width) / 2 - ink.minX
    context.textPosition = CGPoint(x: textX, y: baselineY)
    CTLineDraw(line, context)

    // Track the tightest gap between the digits and the diagonal cut.
    let inkLeft = textX + ink.minX
    let inkBottom = baselineY + ink.minY
    worstClearance = min(worstClearance, inkBottom - (cutLen - inkLeft))
    context.restoreGState()
}

context.endPDFPage()
context.closePDF()

// MARK: - Report

func mm(_ points: CGFloat) -> String { String(format: "%.2f", points * 25.4 / 72) }
print("Wrote \(outputPath)")
print("Page: A4 (\(pageWidthMM) x \(pageHeightMM) mm); label \(simWidthMM) x \(simHeightMM) mm, gap \(gapMM) mm")
print("Grid: \(columns) columns x \(rows) rows = \(count) labels, numbers \(firstNumber)-\(firstNumber + count - 1)")
print("Font: \(fontName) at \(mm(fontSize)) mm (\(String(format: "%.1f", fontSize)) pt)")
print("Logo: \(mm(logoW)) x \(mm(logoH)) mm along the top edge")
print("Closest digit-to-cut clearance: \(mm(worstClearance)) mm")
