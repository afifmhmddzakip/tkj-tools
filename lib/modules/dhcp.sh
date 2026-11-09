#!/usr/bin/env bash
MODULE=dhcp
DHCP_CONF=${DHCP_CONF:-/etc/dhcp/dhcpd.conf}
DHCP_DEFAULT=${DHCP_DEFAULT:-/etc/default/isc-dhcp-server}

dhcp_status() {
  pkg_installed isc-dhcp-server || { echo "belum terpasang"; return; }
  svc_failed isc-dhcp-server && echo "gagal" && return
  svc_active isc-dhcp-server && echo "aktif" || echo "terpasang"
}

dhcp_install() {
  pkg_installed isc-dhcp-server && { ui_msg "ISC DHCP sudah terpasang."; return; }
  ui_msg "Pasang manual: sudo apt update && sudo apt install isc-dhcp-server"
}

dhcp_configure() {
  local iface subnet netmask gw dns dom r1 r2 mac ip
  iface=$(ui_input "Antarmuka layanan" "$(net_primary_iface)") || return 8
  subnet=$(ui_input "Subnet (cth: 10.10.10.0)" "") || return 8
  valid_ip "$subnet" || { ui_error "Subnet tidak valid"; return 1; }
  netmask=$(ui_input "Netmask (cth: 255.255.255.0)" "255.255.255.0") || return 8
  valid_ip "$netmask" || { ui_error "Netmask tidak valid"; return 1; }
  gw=$(ui_input "Gateway" "") || return 8
  valid_ip "$gw" || { ui_error "Gateway tidak valid"; return 1; }
  dns=$(ui_input "DNS server" "$gw") || return 8
  dom=$(ui_input "Domain name" "") || return 8
  r1=$(ui_input "Awal range" "") || return 8
  valid_ip "$r1" || { ui_error "Range awal tidak valid"; return 1; }
  r2=$(ui_input "Akhir range" "") || return 8
  valid_ip "$r2" || { ui_error "Range akhir tidak valid"; return 1; }
  ui_yesno "Tambah reservasi MAC?" && {
    mac=$(ui_input "MAC address (aa:bb:cc:dd:ee:ff)" "") || return 8
    valid_mac "$mac" || { ui_error "MAC tidak valid"; return 1; }
    ip=$(ui_input "IP reservasi" "") || return 8
    valid_ip "$ip" || { ui_error "IP reservasi tidak valid"; return 1; }
  } || mac=ip=

  ui_msg "Peringatan: satu segmen jaringan sebaiknya hanya punya SATU DHCP server."
  ui_yesno "Terapkan konfigurasi DHCP?" || return 8
  backup_create "$DHCP_CONF" "$DHCP_DEFAULT"
  mkdir -p "$TKJ_STATE/stage"
  {
    echo "default-lease-time 600;"
    echo "max-lease-time 7200;"
    echo "authoritative;"
    echo
    echo "subnet $subnet netmask $netmask {"
    echo "    range $r1 $r2;"
    echo "    option routers $gw;"
    echo "    option domain-name-servers $dns;"
    [[ -n "$dom" ]] && echo "    option domain-name \"$dom\";"
    echo "}"
    [[ -n "$mac" && -n "$ip" ]] && {
      echo
      echo "host pc01 {"
      echo "    hardware ethernet $mac;"
      echo "    fixed-address $ip;"
      echo "}"
    }
  } >"$TKJ_STATE/stage/dhcpd.conf"
  atomic_write "$DHCP_CONF" <"$TKJ_STATE/stage/dhcpd.conf"

  { echo "INTERFACESv4=\"$iface\""; } >"$TKJ_STATE/stage/default"
  atomic_write "$DHCP_DEFAULT" <"$TKJ_STATE/stage/default"

  dhcpd -t -cf "$DHCP_CONF" >/dev/null 2>&1 || { ui_error "Validasi dhcpd gagal. Batal."; return 6; }
  svc_restart isc-dhcp-server || { ui_error "Gagal restart isc-dhcp-server."; return 7; }
  log INFO apply "iface=$iface subnet=$subnet"
  firewall_hint "67/udp"
}

dhcp_validate() { dhcpd -t -cf "$DHCP_CONF" >/dev/null 2>&1; }
_tcp_test() {
  ui_msg "Uji: klien pada segmen yang sama harus mendapat IP dari range $r1-$r2."
  ui_msg "Cek lease: dhcpd -f -d --no-pid 2>&1 | head -30"
}
dhcp_logs() { tail -50 /var/log/syslog | grep -i dhcpd; }
dhcp_uninstall() {
  ui_yesno "Hapus konfigurasi DHCP? (paket dipertahankan)" || return 8
  backup_create "$DHCP_CONF"
  rm -f "$DHCP_CONF"
  [[ -f "$DHCP_DEFAULT" ]] && echo "INTERFACESv4=\"\"" >"$TKJ_STATE/stage/default" && atomic_write "$DHCP_DEFAULT" <"$TKJ_STATE/stage/default"
  ui_msg "Konfigurasi DHCP dihapus."
}
