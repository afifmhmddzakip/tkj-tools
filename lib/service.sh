#!/usr/bin/env bash
# service.sh — helper systemctl

svc_exists() { [[ -e "/etc/systemd/system/$1.service" ]] || systemctl list-unit-files "$1.service" >/dev/null 2>&1; }
svc_active() { systemctl is-active --quiet "$1" 2>/dev/null; }
svc_failed() { systemctl is-failed "$1" >/dev/null 2>&1; }
svc_restart() { systemctl restart "$1"; }
svc_enable() { systemctl enable --now "$1" >/dev/null 2>&1 || systemctl enable "$1" >/dev/null 2>&1; }
