#!/usr/bin/env swift
//
//  make_sim_labels.swift
//
//  Generates a full-page A4 PDF of nano-SIM labels. Printed at 100% (actual
//  size, no "fit to page") each label is exactly the size of a physical
//  nano-SIM (12.3 x 8.8 mm, 4FF), with the diagonal cut-off at lower right.
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
/// Size of the diagonal cut at lower right (each leg of the cut).
/// Matches the nano-SIM buttons in the app.
let chamferMM: CGFloat = 2.6
/// Corner rounding, matching the app's nano-SIM shape.
let cornerRadiusMM: CGFloat = 0.8
/// Gap between labels, horizontally and vertically, for manual cutting.
let gapMM: CGFloat = 4.0
/// Minimum margin kept clear around the grid on the page edge.
let pageMarginMM: CGFloat = 8.0
/// Space kept between the digits and the label edge.
let textInsetMM: CGFloat = 0.7
/// Extra clearance kept between the digits and the diagonal cut.
let notchClearanceMM: CGFloat = 0.5
/// A4 page size.
let pageWidthMM: CGFloat = 210
let pageHeightMM: CGFloat = 297

/// Brand red #db052c (same value as `Theme.red` in the app).
let brandRed = CGColor(red: 219 / 255, green: 5 / 255, blue: 44 / 255, alpha: 1)
/// PostScript name of the label font (ships with macOS).
let fontName = "ArialRoundedMTBold"

// MARK: - Helpers

/// Converts millimetres to PDF points (1/72 inch).
/// - Parameter mm: Length in millimetres.
/// - Returns: The same length in points.
func pt(_ mm: CGFloat) -> CGFloat { mm * 72 / 25.4 }

/// Builds the nano-SIM outline with its origin at the lower-left corner.
/// The PDF coordinate system has y pointing up, so the cut is at lower right.
/// - Returns: A rounded path of size `simWidthMM` x `simHeightMM` (in points).
func nanoSIMPath() -> CGPath {
    let w = pt(simWidthMM), h = pt(simHeightMM), cut = pt(chamferMM)
    // Corners clockwise from top-left; the lower-right corner is clipped.
    let corners = [
        CGPoint(x: 0, y: h), CGPoint(x: w, y: h),
        CGPoint(x: w, y: cut), CGPoint(x: w - cut, y: 0), CGPoint(x: 0, y: 0)
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

// MARK: - Font size

// One font size for every label so they match. Find the widest ink among
// all the numbers (at a reference size) and scale it to the label width
// minus the inset on both sides.
let numbers = (0..<count).map { String(firstNumber + $0) }
let refSize: CGFloat = 100
let widestInk = numbers.map { inkBounds(makeLine($0, size: refSize)).width }.max() ?? 1
let fontSize = refSize * (labelW - 2 * pt(textInsetMM)) / widestInk

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

    // Centre the digits' ink in the label.
    let line = makeLine(number, size: fontSize)
    let ink = inkBounds(line)
    let textX = (labelW - ink.width) / 2 - ink.minX
    var textY = (labelH - ink.height) / 2 - ink.minY

    // Keep the digits clear of the diagonal cut: the line runs from
    // (w, cut) to (w - cut, 0), i.e. y = x - (w - cut). Raise the text if
    // its lower-right ink corner would come too close.
    let cut = pt(chamferMM)
    let inkRight = textX + ink.minX + ink.width
    let inkBottom = { textY + ink.minY }
    let required = (inkRight - (labelW - cut)) + pt(notchClearanceMM)
    if inkBottom() < required { textY += required - inkBottom() }
    worstClearance = min(worstClearance, inkBottom() - (inkRight - (labelW - cut)))

    // Draw the digits.
    context.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, context)
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
print("Closest digit-to-cut clearance: \(mm(worstClearance)) mm")
