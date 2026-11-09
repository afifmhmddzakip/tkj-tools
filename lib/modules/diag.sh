#!/usr/bin/env bash
MODULE=diag

diag_show() {
  echo "=== OS/Kernel ==="
  check_os
  uname -r
  echo "=== IP ==="
  net_ips
  echo "=== Status Layanan ==="
  for m in dns ftp dhcp web ssh; do printf '%-8s %s\n' "$m" "$(${m}_status)"; done
  echo "=== Port Listen ==="
  ss -tulpn | grep -E ':(53|21|67|80|443|22)\b' || true
}
