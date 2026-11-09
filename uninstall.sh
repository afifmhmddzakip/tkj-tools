#!/usr/bin/env bash
# uninstall.sh — hapus tkj-tools (/opt/tkj-tools + symlink)
set -euo pipefail

if [[ ${ALLOW_NONROOT:-0} -ne 1 && ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Error: jalankan sebagai root (sudo ./uninstall.sh)" >&2
  exit 1
fi

DEST="${DEST:-/opt/tkj-tools}"
BIN="${BIN:-/usr/local/bin}"

echo "Menghapus $BIN/tkj-tools ..."
rm -f "$BIN/tkj-tools"

echo "Menghapus $DEST ..."
rm -rf "$DEST"

echo "Selesai. tkj-tools berhasil di-uninstall."
