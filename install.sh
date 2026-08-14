#!/usr/bin/env bash
# Installs rojanarch as a native binary — no git, no Dart SDK required.
#
#   curl -fsSL https://raw.githubusercontent.com/rojanparajuli/My-Folder-Files-Architecture-Script/main/install.sh | bash
#
set -euo pipefail

REPO="rojanparajuli/My-Folder-Files-Architecture-Script"
INSTALL_DIR="${ROJANARCH_INSTALL_DIR:-$HOME/.local/bin}"

os="$(uname -s)"
case "$os" in
  Linux)  suffix="linux-x64" ;;
  Darwin) suffix="macos-x64" ;;
  *) echo "Unsupported OS: $os. On Windows, use install.ps1 instead." >&2; exit 1 ;;
esac

echo "Fetching the latest rojanarch release for $suffix..."
latest_url=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep "browser_download_url.*$suffix.zip" \
  | cut -d '"' -f 4)

if [ -z "$latest_url" ]; then
  echo "Could not find a release asset for $suffix. Has a release been published yet?" >&2
  exit 1
fi

tmp_dir=$(mktemp -d)
curl -fsSL "$latest_url" -o "$tmp_dir/bundle.zip"
unzip -q "$tmp_dir/bundle.zip" -d "$tmp_dir"

mkdir -p "$INSTALL_DIR"
mv "$tmp_dir"/rojanarch* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR"/rojanarch*
rm -rf "$tmp_dir"

echo ""
echo "✅ Installed rojanarch to $INSTALL_DIR"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo "⚠ $INSTALL_DIR isn't on your PATH yet. Add this to your shell profile:"
    echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac

echo "Run it with: rojanarch"
