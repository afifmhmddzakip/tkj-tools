#!/usr/bin/env bash
# core.sh — bootstrap & shared helpers untuk tkj-tools
export TKJ_ROOT="${TKJ_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export TKJ_CONFIG=/etc/tkj-tools/config.conf
export TKJ_STATE=${TKJ_STATE:-/var/lib/tkj-tools/state}
export TKJ_BACKUPS=${TKJ_BACKUPS:-/var/backups/tkj-tools}
export TKJ_LOG=${TKJ_LOG:-/var/log/tkj-tools/tkj-tools.log}
export TKJ_VERSION=0.1.0

umask 077
set -Eeuo pipefail

EXIT_OK=0; EXIT_ERROR=1; EXIT_ARGS=2; EXIT_ROOT=3; EXIT_OS=4
EXIT_DEPS=5; EXIT_VALIDATE=6; EXIT_APPLY=7; EXIT_CANCEL=8
MODULE=core

mkdir -p "$TKJ_STATE" "$TKJ_BACKUPS" "$(dirname "$TKJ_LOG")"

log() { local lvl="$1"; shift; printf '%s %s %s %s\n' "$(date +%FT%T%z)" "$lvl" "$MODULE" "$*" >>"$TKJ_LOG"; }
die() { log ERROR "$*"; echo "error: $*" >&2; exit "$EXIT_ERROR"; }

source "$TKJ_ROOT/lib/ui.sh"
source "$TKJ_ROOT/lib/validate.sh"
source "$TKJ_ROOT/lib/pkg.sh"
source "$TKJ_ROOT/lib/service.sh"
source "$TKJ_ROOT/lib/net.sh"
source "$TKJ_ROOT/lib/backup.sh"

atomic_write() { local f="$1" tmp="$1.tmp.$$"; cat >"$tmp"; chmod 0644 "$tmp"; mv -f "$tmp" "$f"; }

_cleanup() { rm -rf "$TKJ_STATE/stage" "$TKJ_STATE/tmp"; }
trap _cleanup EXIT
trap 'exit 130' INT TERM

require_root() { [[ "$(id -u)" -eq 0 ]] || { echo "Harus dijalankan sebagai root (gunakan sudo)." >&2; exit "$EXIT_ROOT"; }; }

check_os() { local id="" vid=""
  if [[ -r /etc/os-release ]]; then
    id=$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')
    vid=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')
  fi
  [[ "$id" == debian ]] || log WARN "os_bukan_debian id=${id:-?}"
  [[ "$vid" == 13 ]] || log WARN "os_versi_bukan_13 version=${vid:-?}"
  echo "${id:-?}/${vid:-?}"
}
