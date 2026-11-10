#!/usr/bin/env bash
MODULE=web
WEB_SITES=${WEB_SITES:-/etc/apache2/sites-available}
WEB_EN=${WEB_EN:-/etc/apache2/sites-enabled}

web_status() {
  pkg_installed apache2 || { echo "belum terpasang"; return; }
  svc_failed apache2 && echo "gagal" && return
  svc_active apache2 && echo "aktif" || echo "terpasang"
}

web_install() {
  pkg_installed apache2 && { ui_msg "apache2 sudah terpasang."; return; }
  ui_yesno "Pasang apache2 via apt?" || return 8
  ui_spin "apt-get update…" apt-get update -qq || return 1
  ui_spin "apt-get install apache2…" apt-get install -y apache2
}

web_configure() {
  local domain root
  domain=$(ui_input "ServerName (domain virtual host)" "lab.tkj") || return 8
  valid_domain "$domain" || { ui_error "Domain tidak valid"; return 1; }
  root=$(ui_input "DocumentRoot" "/var/www/lab") || return 8
  valid_path "$root" || { ui_error "Path tidak valid"; return 1; }
  mkdir -p "$root"
  chown root:www-data "$root" 2>/dev/null || true; chmod 755 "$root" 2>/dev/null || true
  cat >"$root/index.html" <<EOF
<!doctype html><html><head><meta charset="utf-8"><title>$domain</title></head>
<body><h1>Selamat datang di $domain</h1><p>Dikelola tkj-tools.</p></body></html>
EOF
  chmod 644 "$root/index.html"

  backup_create "$WEB_SITES/$domain.conf"
  {
    echo "<VirtualHost *:80>"
    echo "    ServerName $domain"
    echo "    DocumentRoot $root"
    echo "    <Directory $root>"
    echo "        Options -Indexes +FollowSymLinks"
    echo "        AllowOverride All"
    echo "        Require all granted"
    echo "    </Directory>"
    echo "    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log"
    echo "    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined"
    echo "</VirtualHost>"
  } | atomic_write "$WEB_SITES/$domain.conf"

  a2ensite "$domain" >/dev/null 2>&1
  a2enmod rewrite headers >/dev/null 2>&1
  apache2ctl configtest >/dev/null 2>&1 || { ui_error "configtest gagal. Batal."; return 6; }
  svc_restart apache2 || { ui_error "Gagal restart apache2."; return 7; }
  log INFO apply "domain=$domain root=$root"
  firewall_hint "80/tcp"
}

web_validate() { apache2ctl configtest >/dev/null 2>&1; }
web_test() {
  curl -s --max-time 3 -H "Host: $domain" http://127.0.0.1/ >/dev/null && ui_msg "OK: HTTP merespons untuk $domain." || ui_error "curl gagal."
}
web_logs() { tail -50 /var/log/apache2/*error.log 2>/dev/null; }
web_uninstall() {
  ui_yesno "Hapus virtual host & document root? (apache2 dipertahankan)" || return 8
  a2dissite "$domain" >/dev/null 2>&1
  backup_create "$WEB_SITES/$domain.conf"
  rm -f "$WEB_SITES/$domain.conf" "$WEB_EN/$domain.conf"
  [[ -n "$root" && -d "$root" ]] && rm -rf "$root"
  svc_restart apache2 2>/dev/null
  ui_msg "Virtual host dihapus."
}
