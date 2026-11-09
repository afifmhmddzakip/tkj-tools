#!/usr/bin/env bash
# install.sh — pasang tkj-tools ke /opt/tkj-tools + symlink /usr/local/bin
set -euo pipefail

if [[ ${ALLOW_NONROOT:-0} -ne 1 && ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Error: jalankan sebagai root (sudo ./install.sh)" >&2
  exit 1
fi

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${DEST:-/opt/tkj-tools}"
BIN="${BIN:-/usr/local/bin}"

# wajib whiptail untuk UI (fallback teks tanpa itu)
if ! command -v whiptail >/dev/null 2>&1; then
  apt-get update
  apt-get install -y whiptail
fi

echo "Menyalin ke $DEST ..."
rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "$SRC/bin" "$SRC/lib" "$DEST/"
[ -f "$SRC/README.md" ] && cp "$SRC/README.md" "$DEST/"

chmod -R a+rX "$DEST"
chmod +x "$DEST/bin/tkj-tools"

mkdir -p "$BIN"
ln -sf "$DEST/bin/tkj-tools" "$BIN/tkj-tools"

echo "Selesai. Jalankan: tkj-tools"
