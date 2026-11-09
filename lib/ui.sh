#!/usr/bin/env bash
# ui.sh — wrapper whiptail + fallback teks (FR-COM-18)
# Default UI=text. Whiptail HANYA bila dieksplisitkan (TKJ_UI=whiptail):
# whiptail menggambar ke stdout, sehingga tak bisa dipakai dalam $(...) — teks selalu aman.
UI="${TKJ_UI:-text}"

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
    local v; v=$(whiptail --inputbox "$prompt" 10 60 "$def" 2>/dev/null) || return $?
    echo "$v"
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
    local sel
    sel=$(whiptail --title "$title" --menu "$title" 18 72 12 "$@" 2>/dev/null) || return $?
    echo "$sel"; return 0
  else
    # title + item ke stderr (tampil di terminal); HANYA pilihan ke stdout utk $(...)
    echo "$title" >&2
    local i
    for i in "${!tags[@]}"; do echo "  $((i+1))) ${descs[$i]}" >&2; done
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
