#!/usr/bin/env swift
import Cocoa

let iconName = "cursorarrow.click.2"
let colorHex = "1a237e" // Deep blue
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Assets"

try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let scanner = Scanner(string: colorHex)
var hex: UInt64 = 0
scanner.scanHexInt64(&hex)
let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
let b = CGFloat(hex & 0x0000FF) / 255.0
let color = NSColor(red: r, green: g, blue: b, alpha: 1.0)

let sizes = [16, 32, 64, 128, 256, 512]

for size in sizes {
    let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)!
    let config = NSImage.SymbolConfiguration(pointSize: Double(size) * 0.5, weight: .medium)
    let configuredImage = image.withSymbolConfiguration(config)!

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let finalImage = NSImage(size: rect.size)

    finalImage.lockFocus()

    // Blue background
    color.setFill()
    let path = NSBezierPath(roundedRect: rect, xRadius: Double(size) * 0.22, yRadius: Double(size) * 0.22)
    path.fill()

    // White symbol
    NSColor.white.setFill()
    let symbolRect = NSRect(
        x: (CGFloat(size) - configuredImage.size.width) / 2,
        y: (CGFloat(size) - configuredImage.size.height) / 2,
        width: configuredImage.size.width,
        height: configuredImage.size.height
    )
    configuredImage.draw(in: symbolRect)

    finalImage.unlockFocus()

    if let tiff = finalImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:])
    {
        let path = "\(outputDir)/icon_\(size)x\(size).png"
        try? png.write(to: URL(fileURLWithPath: path))

        if size < 512 {
            let path2x = "\(outputDir)/icon_\(size)x\(size)@2x.png"
            try? png.write(to: URL(fileURLWithPath: path2x))
        }
    }
}

print("✅ Icons generated in \(outputDir)/")
