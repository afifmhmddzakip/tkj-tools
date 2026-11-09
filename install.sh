#!/usr/bin/env bash
# install.sh — pasang tkj-tools ke /opt/tkj-tools + symlink
set -euo pipefail
[[ "$(id -u)" -eq 0 ]] || { echo "jalankan sebagai root"; exit 1; }
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DST=/opt/tkj-tools
mkdir -p /etc/tkj-tools /var/lib/tkj-tools/state /var/backups/tkj-tools /var/log/tkj-tools
rm -rf "$DST"; cp -a "$SRC/bin" "$SRC/lib" "$DST"
ln -sf "$DST/bin/tkj-tools" /usr/local/bin/tkj-tools
chmod +x "$DST/bin/tkj-tools"
echo "Terpasang: tj-t-tools"
