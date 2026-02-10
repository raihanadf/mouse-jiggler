#!/bin/bash
# Build Mouse Mover for release

set -e

echo "🔨 Building Mouse Mover Release..."

# Clean
rm -rf .build/release
rm -rf MouseMover.app

# Build release
echo "📦 Building..."
swift build -c release

# Create app bundle
echo "📁 Creating app bundle..."
mkdir -p MouseMover.app/Contents/MacOS
mkdir -p MouseMover.app/Contents/Resources

# Copy binary
cp .build/release/MouseMover MouseMover.app/Contents/MacOS/

# Create Info.plist
cat > MouseMover.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MouseMover</string>
    <key>CFBundleIdentifier</key>
    <string>com.raihan.mousemover</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Mouse Mover</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# Try to create icon
echo "🎨 Creating icon..."
if [ -f "create-icon.sh" ]; then
    ./create-icon.sh 2>/dev/null || echo "⚠️  Icon generation failed, using default"
fi

# Copy icon if exists
if [ -f "Assets/AppIcon.icns" ]; then
    cp Assets/AppIcon.icns MouseMover.app/Contents/Resources/
elif [ -f "Assets/AppIcon.png" ]; then
    cp Assets/AppIcon.png MouseMover.app/Contents/Resources/
fi

# Sign the app
echo "🔏 Signing..."
codesign --force --deep --sign - MouseMover.app 2>/dev/null || true

echo ""
echo "✅ Build complete!"
echo ""
echo "📍 Location: $(pwd)/MouseMover.app"
echo ""
echo "To install:"
echo "  cp -r MouseMover.app /Applications/"
echo ""
echo "To run:"
echo "  open MouseMover.app"
