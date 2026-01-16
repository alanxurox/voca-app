#!/bin/bash
# Bundle Voca as a macOS .app from Swift Package Manager build
# Usage: ./scripts/bundle-app.sh [version] [build_number]

set -e

VERSION="${1:-1.0.0}"
BUILD_NUMBER="${2:-1}"

APP_NAME="Voca"
BUNDLE_ID="com.zhengyishen.voca"
EXECUTABLE=".build/release/Voca"
DIST_DIR="dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"

echo "Bundling $APP_NAME.app v$VERSION (build $BUILD_NUMBER)"

# Clean and create directories
rm -rf "$DIST_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$FRAMEWORKS_DIR"

# Copy executable
cp "$EXECUTABLE" "$MACOS_DIR/"

# Copy framework
cp -R "Frameworks/VoicePipeline.framework" "$FRAMEWORKS_DIR/"

# Copy resources (assets folder)
if [ -d ".build/release/Voca_Voca.bundle/Resources" ]; then
    cp -R ".build/release/Voca_Voca.bundle/Resources/"* "$RESOURCES_DIR/"
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Voca needs microphone access to record your voice for transcription.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Voca needs accessibility access to detect the double-tap hotkey and paste transcriptions.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Fix framework rpath
install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/$APP_NAME" 2>/dev/null || true

echo "Created $APP_DIR"
echo "Version: $VERSION"
echo "Build: $BUILD_NUMBER"

# Verify
if [ -f "$MACOS_DIR/$APP_NAME" ]; then
    echo "Bundle created successfully!"
    ls -la "$APP_DIR"
else
    echo "ERROR: Bundle creation failed"
    exit 1
fi
