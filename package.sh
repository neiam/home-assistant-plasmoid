#!/bin/bash
#
# Local packaging for a neiam plasmoid. Identical in every plasmoid repo.
#
#   ./package.sh --install     install, or upgrade, into ~/.local for testing
#   ./package.sh [VERSION]     release archives (.tar.gz, .zip) for the KDE Store
#
# Both start from the same clean copy: metadata.json, contents/ and the
# licence — what Plasma loads, and what the .deb and .rpm ship (see
# packaging/build.sh). Named in, rather than everything else excluded,
# so build output, CI config, secrets and old archives lying in the
# checkout can't ride along. `kpackagetool6 --upgrade .` copies the whole
# directory, dist/ and all; use --install instead.

set -euo pipefail

root=$(cd -- "$(dirname -- "$0")" && pwd)
PACKAGE_NAME=$(basename "$root")
ID=$(sed -n 's/^ *"Id": *"\([^"]*\)".*/\1/p' "$root/metadata.json" | head -1)

stage() {
  local dest=$1
  mkdir -p "$dest"
  install -m 0644 "$root/metadata.json" "$root/LICENSE.md" "$dest/"
  # Editor droppings inside contents/ stay behind too.
  rsync -a \
    --exclude='*.swp' --exclude='*~' --exclude='*.kate-swp' --exclude='.*' \
    "$root/contents/" "$dest/contents/"
}

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
PACKAGE_DIR="$TEMP_DIR/$PACKAGE_NAME"

if [[ "${1:-}" == "--install" ]]; then
  stage "$PACKAGE_DIR"
  if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --upgrade "$PACKAGE_DIR"
  else
    kpackagetool6 --type Plasma/Applet --install "$PACKAGE_DIR"
  fi
  echo ""
  echo "Plasma keeps the old QML loaded until the shell restarts:"
  echo "  systemctl --user restart plasma-plasmashell"
  exit 0
fi

VERSION=${1:-"dev"}
echo "🚀 Packaging $PACKAGE_NAME version $VERSION"
stage "$PACKAGE_DIR"

if [[ "$VERSION" != "dev" ]]; then
  echo "🔢 Updating version to $VERSION"
  sed -i "s/\"Version\": \"[^\"]*\"/\"Version\": \"$VERSION\"/" "$PACKAGE_DIR/metadata.json"
fi

archives=("${PACKAGE_NAME}-${VERSION}.tar.gz")
(cd "$TEMP_DIR" && tar -czf "$root/${PACKAGE_NAME}-${VERSION}.tar.gz" "$PACKAGE_NAME/")

if command -v zip >/dev/null 2>&1; then
  rm -f "$root/${PACKAGE_NAME}-${VERSION}.zip"
  (cd "$TEMP_DIR" && zip -qr "$root/${PACKAGE_NAME}-${VERSION}.zip" "$PACKAGE_NAME/")
  archives+=("${PACKAGE_NAME}-${VERSION}.zip")
else
  echo "⚠️  zip command not found, skipping zip package creation"
fi

echo "✅ Packages created:"
(cd "$root" && ls -lh "${archives[@]}")

echo ""
echo "🎯 Next steps:"
echo "1. Test the package locally:"
echo "   kpackagetool6 --type Plasma/Applet --install ${PACKAGE_NAME}-${VERSION}.tar.gz"
echo ""
echo "2. Upload to KDE Store:"
echo "   - Go to https://store.kde.org"
echo "   - Navigate to your plasmoid page"
echo "   - Add new version and upload ${PACKAGE_NAME}-${VERSION}.tar.gz"
