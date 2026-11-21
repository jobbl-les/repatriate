#!/usr/bin/env swift
//
//  make_app_icon.swift
//
//  Builds the 1024 x 1024 app icon: the three-box 'r' symbol cropped from the
//  supplied white Recipero logo (never redrawn), centred on the brand red.
//
//  This is a development utility; it is not compiled into the app.
//
//  Usage: swift make_app_icon.swift
//  Writes Repatriate/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Icon edge length in pixels (the single size iOS needs).
let iconSize = 1024
/// Share of the icon width taken up by the symbol.
let symbolWidthFraction: CGFloat = 0.56
/// Brand red #db052c (same value as `Theme.red` in the app).
let brandRed = CGColor(red: 219 / 255, green: 5 / 255, blue: 44 / 255, alpha: 1)

/// Project root: three folders above this script (tools/app-icon/<script>).
let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let logoURL = root.appendingPathComponent("Repatriate/Assets.xcassets/ReciperoLogoWhite.imageset/ReciperoLogoWhite.png")
let outDir = root.appendingPathComponent("Repatriate/Assets.xcassets/AppIcon.appiconset")

// Load the supplied white logo.
guard let provider = CGDataProvider(url: logoURL as CFURL),
      let logo = CGImage(pngDataProviderSource: provider, decode: nil,
                         shouldInterpolate: true, intent: .defaultIntent) else {
    fatalError("Could not load \(logoURL.path)")
}

// Read the logo's alpha so we can find where the symbol ends and the word begins.
let lw = logo.width, lh = logo.height
var pixels = [UInt8](repeating: 0, count: lw * lh * 4)
let readCtx = CGContext(data: &pixels, width: lw, height: lh, bitsPerComponent: 8, bytesPerRow: lw * 4,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
readCtx.draw(logo, in: CGRect(x: 0, y: 0, width: lw, height: lh))

/// Whether any pixel in a column is visibly opaque.
func columnHasInk(_ x: Int) -> Bool {
    (0..<lh).contains { pixels[($0 * lw + x) * 4 + 3] > 16 }
}
/// Whether any pixel in a row (within columns) is visibly opaque.
func rowHasInk(_ y: Int, _ cols: Range<Int>) -> Bool {
    cols.contains { pixels[(y * lw + $0) * 4 + 3] > 16 }
}

// The symbol is made of three shapes with narrow gaps between them; it ends
// at the first empty run wide enough (60 px) to be the gap before the "R".
var left = 0
while left < lw && !columnHasInk(left) { left += 1 }
var right = left
var emptyRun = 0
var lastInk = left
while right < lw && emptyRun < 60 {
    if columnHasInk(right) { lastInk = right; emptyRun = 0 } else { emptyRun += 1 }
    right += 1
}
right = lastInk + 1
let cols = left..<right
var top = 0
while top < lh && !rowHasInk(top, cols) { top += 1 }
var bottom = lh - 1
while bottom > top && !rowHasInk(bottom, cols) { bottom -= 1 }
// CGImage rows run top to bottom, so these are already in image space.
let cropRect = CGRect(x: left, y: top, width: right - left, height: bottom - top + 1)
guard let symbol = logo.cropping(to: cropRect) else { fatalError("Crop failed") }
print("Symbol crop: \(Int(cropRect.width)) x \(Int(cropRect.height)) px at x=\(left), y=\(top)")

// Compose: opaque brand-red square with the symbol centred.
let ctx = CGContext(data: nil, width: iconSize, height: iconSize, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(brandRed)
ctx.fill(CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
let drawW = CGFloat(iconSize) * symbolWidthFraction
let drawH = drawW * cropRect.height / cropRect.width
ctx.interpolationQuality = .high
ctx.draw(symbol, in: CGRect(x: (CGFloat(iconSize) - drawW) / 2, y: (CGFloat(iconSize) - drawH) / 2,
                            width: drawW, height: drawH))

// Write the PNG and the asset catalog manifest.
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let pngURL = outDir.appendingPathComponent("AppIcon.png")
guard let dest = CGImageDestinationCreateWithURL(pngURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Could not create \(pngURL.path)")
}
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("PNG write failed") }

let manifest = """
{
  "images" : [
    { "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}

"""
try manifest.write(to: outDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Wrote \(pngURL.path)")
