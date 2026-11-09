#!/usr/bin/env bash
# backup.sh — backup/restore konfigurasi (FR-COM-07/08)

backup_create() {
  local ts dir; ts=$(date +%Y%m%d-%H%M%S); dir="$TKJ_BACKUPS/$ts"
  mkdir -p "$dir"; : >"$dir/manifest.tsv"
  local f rel
  for f in "$@"; do
    [[ -e "$f" ]] || continue
    rel="${f#/}"
    mkdir -p "$dir/$(dirname "$rel")"
    cp -a "$f" "$dir/$rel"
    printf '%s\t%s\t%s\n' "$MODULE" "$f" "$(md5sum <"$f" | cut -d' ' -f1)" >>"$dir/manifest.tsv"
  done
  echo "$dir"
}

backup_list() { ls -1dt "$TKJ_BACKUPS"/*/ 2>/dev/null | head -20; }

backup_restore_one() { local dir="$1" f="$2" rel="${2#/}"; [[ -f "$dir/$rel" ]] && cp -a "$dir/$rel" "$f"; }

backup_restore() {
  local dir="$1" f rel
  local IFS=$'\t'
  while read -r _ f _; do
    [[ -n "$f" ]] && backup_restore_one "$dir" "$f"
  done <"$dir/manifest.tsv"
  log INFO restore "from=$dir"
}

backup_prune() { local keep="${1:-20}"; ls -1dt "$TKJ_BACKUPS"/*/ 2>/dev/null | tail -n +$((keep+1)) | xargs -r rm -rf; }
