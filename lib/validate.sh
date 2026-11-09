#!/usr/bin/env bash
# validate.sh — validator input (FR-COM-12)

valid_ip() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS=. a; read -ra a <<<"$1"
  local o; for o in "${a[@]}"; do ((o<=255)) || return 1; done
}

valid_cidr() {
  valid_ip "${1%%/*}" || return 1
  local p="${1##*/}"
  [[ "$p" =~ ^[0-9]+$ && $p -ge 0 && $p -le 32 ]]
}

valid_port() { [[ "$1" =~ ^[0-9]+$ && $1 -ge 1 && $1 -le 65535 ]]; }
valid_domain() { [[ "$1" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]]; }
valid_path() { [[ "$1" == /* ]] && [[ "$1" != *..* ]]; }
valid_user() { id "$1" >/dev/null 2>&1; }
valid_mac() { [[ "$1" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; }
