#!/usr/bin/env bash
# ui.sh — wrapper whiptail + fallback teks (FR-COM-18)
command -v whiptail >/dev/null 2>&1 && UI=whiptail || UI=text

ui_msg() {
  local msg="$1"
  [[ -t 0 ]] || msg="$(cat)"
  if [[ $UI == whiptail ]]; then whiptail --msgbox "$msg" 12 68
  else echo "$msg"; fi
}

ui_error() { ui_msg "Error: $1"; }

ui_yesno() {
  if [[ $UI == whiptail ]]; then whiptail --yesno "$1" 12 60
  else local a; read -rp "$1 [y/N] " a; [[ $a =~ ^[yY] ]]; fi
}

ui_input() {
  local prompt="$1" def="${2:-}"
  if [[ $UI == whiptail ]]; then
    whiptail --inputbox "$prompt" 10 60 "$def" 2>/tmp/tkj-in
    local rc=$?; [[ $rc -ne 0 ]] && return "$rc"
    cat /tmp/tkj-in; rm -f /tmp/tkj-in
  else
    local v; read -rp "$prompt: " v; echo "${v:-$def}"
  fi
}

# ui_menu TITLE  [tag desc]...  -> echo tag; rc 0 ok, 8 cancel
ui_menu() {
  local title="$1"; shift
  local tags=() descs=()
  while (($#>0)); do tags+=("$1"); descs+=("$2"); shift 2; done
  if [[ $UI == whiptail ]]; then
    whiptail --title "$title" --menu "$title" 18 72 12 "$@" 2>/tmp/tkj-menu
    local rc=$?; [[ $rc -ne 0 ]] && return "$rc"
    local sel; sel=$(</tmp/tkj-menu); rm -f /tmp/tkj-menu
    echo "$sel"; return 0
  else
    echo "$title"
    local i
    for i in "${!tags[@]}"; do echo "  $((i+1))) ${descs[$i]}"; done
    local n; read -rp "Pilih: " n
    [[ "$n" =~ ^[0-9]+$ && $n -ge 1 && $n -le ${#tags[@]} ]] || return 8
    echo "${tags[$((n-1))]}"; return 0
  fi
}

ui_spin() {
  local msg="$1"; shift
  "$@" >/dev/null 2>&1 & local pid=$!
  if [[ $UI != whiptail ]]; then
    while kill -0 "$pid" 2>/dev/null; do printf '\r%s … ' "$msg"; sleep 0.2; done
    echo; fi
  wait "$pid"; return $?
}
