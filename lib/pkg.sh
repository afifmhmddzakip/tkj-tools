#!/usr/bin/env bash
# pkg.sh — query/instalasi paket via apt (instalasi tetap dipicu manual/opt-in)

pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

pkg_missing() {
  local p miss=()
  for p in "$@"; do pkg_installed "$p" || miss+=("$p"); done
  echo "${miss[*]}"
}

# Menawarkan apt jika paket belum ada; tanpa persetujuan -> batal (rc 8)
pkg_ensure() {
  local missing; missing=$(pkg_missing "$@")
  [[ -z "$missing" ]] && return 0
  if ui_yesno "Paket belum terpasang: $missing. Pasang melalui apt sekarang?"; then
    apt-get update -qq && apt-get install -y $missing || return 1
  else
    log WARN pkg_skip "missing=$missing"
    return 8
  fi
}
