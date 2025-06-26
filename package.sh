#!/bin/bash

# Local packaging script for Home Assistant Plasmoid
# This script mirrors what the GitHub Action does for local testing

set -e

VERSION=${1:-"dev"}
PACKAGE_NAME="home-assistant-plasmoid"

echo "🚀 Packaging $PACKAGE_NAME version $VERSION"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/$PACKAGE_NAME"

echo "📁 Creating package directory: $PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy files (excluding development files)
echo "📋 Copying files..."
rsync -av \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='*.swp' \
  --exclude='*~' \
  --exclude='*.kate-swp' \
  --exclude='package.sh' \
  --exclude='node_modules' \
  --exclude='*.log' \
  . "$PACKAGE_DIR/"

# Update version in metadata.json if not "dev"
if [[ "$VERSION" != "dev" ]]; then
  echo "🔢 Updating version to $VERSION"
  sed -i "s/\"Version\": \"[^\"]*\"/\"Version\": \"$VERSION\"/" "$PACKAGE_DIR/metadata.json"
fi

# Create packages
cd "$TEMP_DIR"

echo "📦 Creating tar.gz package..."
tar -czf "${PACKAGE_NAME}-${VERSION}.tar.gz" "$PACKAGE_NAME/"

echo "📦 Creating zip package..."
if command -v zip >/dev/null 2>&1; then
  zip -r "${PACKAGE_NAME}-${VERSION}.zip" "$PACKAGE_NAME/"
  CREATED_ZIP=true
else
  echo "⚠️  zip command not found, skipping zip package creation"
  CREATED_ZIP=false
fi

# Move to current directory
mv "${PACKAGE_NAME}-${VERSION}.tar.gz" "$OLDPWD/"
if [[ "$CREATED_ZIP" == "true" ]]; then
  mv "${PACKAGE_NAME}-${VERSION}.zip" "$OLDPWD/"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ Packages created:"
echo "  - ${PACKAGE_NAME}-${VERSION}.tar.gz"
if [[ "$CREATED_ZIP" == "true" ]]; then
  echo "  - ${PACKAGE_NAME}-${VERSION}.zip"
fi

# Display package info
echo ""
echo "📊 Package information:"
if [[ "$CREATED_ZIP" == "true" ]]; then
  ls -lh "${PACKAGE_NAME}-${VERSION}".{tar.gz,zip}
else
  ls -lh "${PACKAGE_NAME}-${VERSION}.tar.gz"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Test the package locally:"
echo "   kpackagetool6 --type Plasma/Applet --install ${PACKAGE_NAME}-${VERSION}.tar.gz"
echo ""
echo "2. Upload to KDE Store:"
echo "   - Go to https://store.kde.org"
echo "   - Navigate to your plasmoid page"
echo "   - Add new version and upload ${PACKAGE_NAME}-${VERSION}.tar.gz"
