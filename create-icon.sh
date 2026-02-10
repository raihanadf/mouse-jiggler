#!/bin/bash
# Create app icon from SF Symbol - uses gen-icon.swift

set -e

echo "🎨 Creating app icons..."

# Generate PNGs using the fixed gen-icon.swift
swift gen-icon.swift Assets/

# Create Icon.iconset folder
mkdir -p Assets/Icon.iconset
cp Assets/icon_*.png Assets/Icon.iconset/

# Create ICNS file
echo "📦 Creating .icns file..."
iconutil -c icns Assets/Icon.iconset -o Assets/AppIcon.icns

echo "✅ Done!"
