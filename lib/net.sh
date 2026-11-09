#!/usr/bin/env bash
# net.sh — IP, interface, port, hint firewall

net_ips() { ip -4 addr show scope global | awk '/inet /{print $2}'; }
net_primary_iface() { ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}'; }
net_primary_ip() {
  local iface; iface=$(net_primary_iface)
  [[ -n "$iface" ]] && ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet /{print $2; exit}'
}

port_listen() { ss -tulpn 2>/dev/null | grep -q ":$2 " 2>/dev/null || ss -tulpn 2>/dev/null | grep -q ":$1 "; }

firewall_hint() { echo "Hint firewall (buka port): $*"; }
