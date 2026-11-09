#!/usr/bin/env bash
MODULE=ssh
SSH_CONF=${SSH_CONF:-/etc/ssh/sshd_config.d/99-tkj-tools.conf}

ssh_status() {
  pkg_installed openssh-server || { echo "belum terpasang"; return; }
  svc_failed ssh && echo "gagal" && return
  svc_active ssh && echo "aktif" || echo "terpasang"
}

ssh_install() {
  pkg_installed openssh-server && { ui_msg "openssh-server sudah terpasang."; return; }
  ui_msg "Pasang manual: sudo apt update && sudo apt install openssh-server"
}

ssh_configure() {
  local port rootlogin pass key svc rollback
  port=$(ui_input "Port SSH (default 22)" "22") || return 8
  valid_port "$port" || { ui_error "Port tidak valid"; return 1; }
  ui_yesno "Izinkan PermitRootLogin?" && rootlogin=yes || rootlogin=no
  ui_yesno "Aktifkan PasswordAuthentication?" && pass=yes || pass=no
  ui_yesno "Aktifkan PubkeyAuthentication?" && pubkey=yes || pubkey=no
  key=$(ui_input "Public key (opsional, kosongkan utk lewati)" "") || return 8
  user=$(ui_input "User untuk pasang key" "$(stat -c %U /home/* 2>/dev/null | head -1)") || return 8

  ui_msg "PERINGATAN: mengubah port / mematikan password bisa menyebabkan lockout."
  ui_yesno "Lanjutkan dan terapkan? (rollback otomatis 60 detik)" || return 8

  backup_create "$SSH_CONF"
  mkdir -p "$TKJ_STATE/stage"
  {
    echo "Port $port"
    echo "PermitRootLogin $rootlogin"
    echo "PasswordAuthentication $pass"
    echo "PubkeyAuthentication $pubkey"
  } >"$TKJ_STATE/stage/ssh.conf"
  atomic_write "$SSH_CONF" <"$TKJ_STATE/stage/ssh.conf"

  [[ -n "$key" && -n "$user" ]] && {
    home=$(getent passwd "$user" | cut -d: -f6)
    [[ -n "$home" ]] || { ui_error "User $user tidak ditemukan."; return 1; }
    mkdir -p "$home/.ssh" 2>/dev/null || true; chmod 700 "$home/.ssh" 2>/dev/null || true
    grep -qF "$key" "$home/.ssh/authorized_keys" 2>/dev/null || echo "$key" >>"$home/.ssh/authorized_keys" 2>/dev/null || true
    chmod 600 "$home/.ssh/authorized_keys" 2>/dev/null || true; chown -R "$user:$user" "$home/.ssh" 2>/dev/null || true
  }

  sshd -t >/dev/null 2>&1 || { ui_error "sshd -t gagal. Batal."; return 6; }
  smc=ssh; svc_active ssh.socket && smc=ssh.socket
  svc_restart "$smc" || { ui_error "Gagal restart ssh."; return 7; }

  # auto-rollback 60 dtk bila tidak dikonfirmasi
  cp -a "$SSH_CONF" "$TKJ_STATE/stage/ssh.conf.pre" 2>/dev/null || :
  systemd-run --no-block --on-active=60s --timer-property=AccuracySec=1s /bin/bash -c \
    "if [[ ! -e /tmp/tkj-ssh-ok ]]; then cp -a '$TKJ_STATE/stage/ssh.conf.pre' '$SSH_CONF' 2>/dev/null; systemctl restart $smc; fi" 2>/dev/null

  if ui_yesno "Cek koneksi SSH dari sesi kedua BERHASIL? (Ya = kunci rollback)"; then
    touch /tmp/tkj-ssh-ok
    log INFO apply "port=$port rootlogin=$rootlogin pass=$pass"
  else
    rm -f /tmp/tkj-ssh-ok
    ui_msg "Rollback otomatis aktif: konfigurasi lama akan dipulihkan."
    return 7
  fi
  firewall_hint "$port/tcp"
}

ssh_validate() { sshd -t >/dev/null 2>&1; }
ssh_test() {
  local port; port=$(sed -n 's/^Port //p' "$SSH_CONF"); port=${port:-22}
  ui_msg "Uji dari klien lain: ssh -p $port user@<IP-server>"
}
ssh_logs() { tail -50 /var/log/auth.log | grep -i sshd; }
ssh_uninstall() {
  ui_yesno "Hapus konfigurasi SSH buatan tool? (paket dipertahankan)" || return 8
  backup_create "$SSH_CONF"
  rm -f "$SSH_CONF"
  svc_restart ssh 2>/dev/null
  ui_msg "Konfigurasi SSH dihapus (kembali ke default)."
}
