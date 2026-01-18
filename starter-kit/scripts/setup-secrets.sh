#!/bin/bash
set -e

echo "=== GitHub Secrets Setup for macOS Code Signing ==="
echo ""

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is required. Install with: brew install gh"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI. Run: gh auth login"
    exit 1
fi

# Detect repository
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
if [ -z "$REPO" ]; then
    echo "Error: Not in a GitHub repository directory"
    exit 1
fi
echo "Repository: $REPO"
echo ""

# Collect credentials
read -p "Apple ID (email): " APPLE_ID
read -s -p "App-specific password: " APPLE_APP_PASSWORD
echo ""
read -s -p "Certificate export password: " CERT_PASSWORD
echo ""
read -p "Apple Team ID: " TEAM_ID

# Find Developer ID certificate
echo ""
echo "Finding Developer ID Application certificate..."
CERT_NAME=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ -z "$CERT_NAME" ]; then
    echo "Error: No Developer ID Application certificate found in keychain"
    exit 1
fi
echo "Found: $CERT_NAME"

# Export certificate
CERT_FILE=$(mktemp).p12
security export -k login.keychain-db -t identities -f pkcs12 -P "$CERT_PASSWORD" -o "$CERT_FILE" || {
    echo "Error: Failed to export certificate."
    rm -f "$CERT_FILE"
    exit 1
}

# Base64 encode
CERT_BASE64=$(base64 -i "$CERT_FILE")
rm -f "$CERT_FILE"

# Upload secrets
echo ""
echo "Uploading secrets to GitHub..."
gh secret set APPLE_ID --body "$APPLE_ID" --repo "$REPO"
gh secret set APPLE_APP_PASSWORD --body "$APPLE_APP_PASSWORD" --repo "$REPO"
gh secret set APPLE_CERTIFICATE_PASSWORD --body "$CERT_PASSWORD" --repo "$REPO"
gh secret set APPLE_CERTIFICATE_BASE64 --body "$CERT_BASE64" --repo "$REPO"
gh secret set APPLE_TEAM_ID --body "$TEAM_ID" --repo "$REPO"

echo ""
echo "Done! Secrets uploaded:"
echo "  - APPLE_ID"
echo "  - APPLE_APP_PASSWORD"
echo "  - APPLE_CERTIFICATE_PASSWORD"
echo "  - APPLE_CERTIFICATE_BASE64"
echo "  - APPLE_TEAM_ID"
echo ""
echo "Don't forget to add HOMEBREW_TAP_TOKEN if using Homebrew distribution."
