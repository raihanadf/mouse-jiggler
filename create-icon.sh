#!/bin/bash
# Create app icon from SF Symbol

set -e

ICON_NAME="cursorarrow.click.2"
ICON_COLOR="1a237e"  # Green color
ASSETS_DIR="Assets"
ICONSET_DIR="$ASSETS_DIR/Icon.iconset"

echo "🎨 Creating app icon..."

# Create iconset directory
mkdir -p "$ICONSET_DIR"

# Generate different sizes using Swift script
cat > /tmp/gen_icon.swift << 'EOF'
import Cocoa

let iconName = CommandLine.arguments[1]
let colorHex = CommandLine.arguments[2]
let outputPath = CommandLine.arguments[3]
let size = Double(CommandLine.arguments[4])!

// Parse hex color
let scanner = Scanner(string: colorHex)
var hex: UInt64 = 0
scanner.scanHexInt64(&hex)
let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
let b = CGFloat(hex & 0x0000FF) / 255.0
let color = NSColor(red: r, green: g, blue: b, alpha: 1.0)

// Create image
let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)!
let config = NSImage.SymbolConfiguration(pointSize: size * 0.7, weight: .regular)
let configuredImage = image.withSymbolConfiguration(config)!

// Create colored version
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let coloredImage = NSImage(size: rect.size)
coloredImage.lockFocus()

// Fill background
color.setFill()
NSBezierPath(roundedRect: rect, xRadius: size * 0.2, yRadius: size * 0.2).fill()

// Draw symbol in white
let symbolRect = NSRect(
    x: (size - configuredImage.size.width) / 2,
    y: (size - configuredImage.size.height) / 2,
    width: configuredImage.size.width,
    height: configuredImage.size.height
)
NSColor.white.setFill()
configuredImage.draw(in: symbolRect)

coloredImage.unlockFocus()

// Save as PNG
if let tiffData = coloredImage.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try! pngData.write(to: URL(fileURLWithPath: outputPath))
}
EOF

# Generate icons at different sizes
sizes=(16 32 64 128 256 512)
for size in "${sizes[@]}"; do
    echo "  Generating ${size}x${size}..."
    swift /tmp/gen_icon.swift "$ICON_NAME" "$ICON_COLOR" "$ICONSET_DIR/icon_${size}x${size}.png" "$size"
    
    # Create @2x versions
    if [ $size -lt 512 ]; then
        double_size=$((size * 2))
        cp "$ICONSET_DIR/icon_${size}x${size}.png" "$ICONSET_DIR/icon_${size}x${size}@2x.png"
    fi
done

# Create ICNS file
echo "📦 Creating .icns file..."
icnstool="/usr/bin/iconutil"
if command -v "$icnstool" &> /dev/null; then
    "$icnstool" -c icns "$ICONSET_DIR" -o "$ASSETS_DIR/AppIcon.icns"
    echo "✅ Icon created: $ASSETS_DIR/AppIcon.icns"
else
    echo "⚠️  iconutil not found, copying largest PNG as fallback"
    cp "$ICONSET_DIR/icon_512x512.png" "$ASSETS_DIR/AppIcon.png"
fi

echo "✅ Done!"
