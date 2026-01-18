# Swift macOS Starter Kit

## Architecture
- Three layers: Xcode + SPM + KMP (xcframework)
- Package.swift for AI editing, Xcode for signing/release
- Always use `.xcframework`, never `.framework`

## File Structure
```
MyApp/
├── Package.swift              # SPM layer
├── MyApp.xcodeproj/           # Xcode layer
├── Frameworks/*.xcframework   # Dependencies
├── MyApp/
│   ├── App/                   # AppDelegate
│   ├── Views/                 # UI
│   ├── Services/              # Logic
│   └── Resources/             # Info.plist, assets
├── scripts/
└── .github/workflows/
```

## Versioning
- Version from git tag: `v1.2.3` → `1.2.3`
- Build number: `git rev-list --count HEAD`
- Release: `git tag v1.0.0 && git push --tags`

## GitHub Actions
- `build.yml` — CI, unsigned
- `release.yml` — Sign, notarize, DMG, release, update Homebrew

## Secrets
- `APPLE_CERTIFICATE_BASE64` — P12 base64
- `APPLE_CERTIFICATE_PASSWORD` — P12 password
- `APPLE_TEAM_ID` — Team ID
- `APPLE_ID` — Apple ID email
- `APPLE_APP_PASSWORD` — App-specific password
- `HOMEBREW_TAP_TOKEN` — PAT for tap repo

## SPM Pattern
```swift
.binaryTarget(name: "X", path: "Frameworks/X.xcframework")
```

## Convert .framework
```bash
xcodebuild -create-xcframework -framework X.framework -output X.xcframework
```

## Menu Bar App
- `LSUIElement: true` — No dock icon
- SF Symbol with `isTemplate = true`
- Sign frameworks first (inside-out)

## Entitlements
- Audio: `com.apple.security.device.audio-input`
- Accessibility: `com.apple.security.automation.apple-events`
- Network: `com.apple.security.network.client`

## Distribution
- DMG: `brew install create-dmg`
- Homebrew: separate tap repo
- Landing page: `index.html` + `CNAME`

## Gotchas
- Xcode ignores SPM `unsafeFlags` — use xcframework
- Notarize .app before creating DMG
- Hardened runtime required for notarization
- App-specific password for notarytool

## Commands
```bash
swift build                              # Local build
git tag v1.0.0 && git push --tags        # Release
./scripts/setup-secrets.sh               # Upload certs
swift scripts/generate-icon.swift        # Generate icon
iconutil -c icns AppIcon.iconset         # Convert to icns
```
