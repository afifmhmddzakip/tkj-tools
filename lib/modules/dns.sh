#!/usr/bin/env bash
MODULE=dns
BIND_CONF=${BIND_CONF:-/etc/bind/named.conf.local}
BIND_DIR=${BIND_DIR:-/etc/bind}
DNS_PKGS="bind9 bind9-utils bind9-dnsutils"

dns_status() {
  pkg_installed bind9 || { echo "belum terpasang"; return; }
  svc_failed named && echo "gagal" && return
  svc_active named && echo "aktif" || echo "terpasang"
}

dns_install() {
  missing=$(pkg_missing $DNS_PKGS)
  [[ -z "$missing" ]] && { ui_msg "Paket BIND9 sudah terpasang."; return; }
  ui_msg "Paket yang dibutuhkan belum ada: $missing"
  ui_msg "Pasang manual: sudo apt update && sudo apt install $DNS_PKGS"
}

dns_configure() {
  local domain ip fwd
  domain=$(ui_input "Nama domain (cth: lab.tkj)" "lab.tkj") || return 8
  valid_domain "$domain" || { ui_error "Domain tidak valid"; return 1; }
  local defip; defip=$(net_primary_ip); defip="${defip%/*}"
  ip=$(ui_input "IP utama server ns (cth: 10.10.10.1)" "$defip") || return 8
  valid_ip "${ip%%/*}" || { ui_error "IP tidak valid"; return 1; }

  ui_yesno "Sertakan reverse zone untuk $ip?" && fwd=yes || fwd=no
  ui_yesno "Terapkan konfigurasi DNS?" || return 8
  dns_apply "$domain" "$ip" "$fwd"
}

dns_apply() {
  local domain="$1" ip="$2" reverse="$3" rev revfile zone
  backup_create "$BIND_CONF" "$BIND_DIR/db."* 2>/dev/null || true
  mkdir -p "$TKJ_STATE/stage"
  {
    echo "// dikelola oleh tkj-tools"
    echo "zone \"$domain\" { type master; file \"/etc/bind/db.$domain\"; };"
    if [[ $reverse == yes ]]; then
      rev=$(echo "$ip" | awk -F. '{print $3"."$2"."$1}')
      echo "zone \"$rev.in-addr.arpa\" { type master; file \"/etc/bind/db.$rev\"; };"
    fi
  } >"$TKJ_STATE/stage/named.conf.local"
  atomic_write "$BIND_CONF" <"$TKJ_STATE/stage/named.conf.local"

  {
    echo "\$TTL 604800"
    echo "@   IN  SOA ns1.$domain. admin.$domain. ("
    echo "        2026110901 ; serial"
    echo "        3600 ; refresh"
    echo "        1800 ; retry"
    echo "        604800 ; expire"
    echo "        86400 ) ; minimum"
    echo "@       IN  NS   ns1.$domain."
    echo "ns1     IN  A    $ip"
    echo "server  IN  A    $ip"
    echo "www     IN  CNAME server"
  } >"$BIND_DIR/db.$domain"
  chmod 0644 "$BIND_DIR/db.$domain"

  if [[ $reverse == yes ]]; then
    revfile="db.$rev"
    {
      echo "\$TTL 604800"
      echo "@   IN  SOA ns1.$domain. admin.$domain. ("
      echo "        2026110901 ; serial"
      echo "        3600 ; refresh"
      echo "        1800 ; retry"
      echo "        604800 ; expire"
      echo "        86400 ) ; minimum"
      echo "@       IN  NS   ns1.$domain."
      echo "1       IN  PTR  ns1.$domain."
    } >"$BIND_DIR/$revfile"
    chmod 0644 "$BIND_DIR/$revfile"
  fi

  if ! named-checkconf "$BIND_CONF" >/dev/null 2>&1 || ! named-checkzone "$domain" "$BIND_DIR/db.$domain" >/dev/null 2>&1; then
    ui_error "Validasi zona gagal. Batal."
    return 6
  fi
  svc_restart named || { ui_error "Gagal restart named."; return 7; }
  log INFO apply "domain=$domain"
  dns_test
}

dns_validate() { named-checkconf; }
dns_test() {
  local domain ip rc defip
  domain=$(ui_input "Domain untuk uji dig" "lab.tkj") || return 8
  defip=$(net_primary_ip); defip="${defip%/*}"
  ip=$(ui_input "IP yang diharapkan" "$defip") || return 8
  dig @127.0.0.1 "$domain" +short | grep -q "$ip" && ui_msg "OK: $domain -> $ip" || ui_error "dig: tidak cocok / gagal."
}
dns_logs() { [[ -f /var/log/syslog ]] && tail -50 /var/log/syslog | grep -i named || tail -50 /var/log/daemon.log 2>/dev/null | grep -i named; }
dns_uninstall() {
  ui_yesno "Backup dan hapus zona buatan tool? (paket bind9 TIDAK dihapus)" || return 8
  backup_create "$BIND_CONF" "$BIND_DIR/db."* 2>/dev/null
  sed -i '/dikelola oleh tkj-tools/d' "$BIND_CONF" 2>/dev/null
  grep -l 'dikelola oleh tkj-tools' "$BIND_DIR"/db.* 2>/dev/null | xargs -r rm -f
  echo >/dev/null
}
