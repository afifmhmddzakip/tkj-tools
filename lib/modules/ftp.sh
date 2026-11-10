#!/usr/bin/env bash
MODULE=ftp
FTP_CONF=${FTP_CONF:-/etc/vsftpd.conf}

ftp_status() {
  pkg_installed vsftpd || { echo "belum terpasang"; return; }
  svc_failed vsftpd && echo "gagal" && return
  svc_active vsftpd && echo "aktif" || echo "terpasang"
}

ftp_install() {
  pkg_installed vsftpd && { ui_msg "vsftpd sudah terpasang."; return; }
  ui_yesno "Pasang vsftpd via apt?" || return 8
  ui_spin "apt-get update…" apt-get update -qq || return 1
  ui_spin "apt-get install vsftpd…" apt-get install -y vsftpd
}

ftp_configure() {
  local user write chroot pasv pasv_min pasv_max
  user=$(ui_input "User FTP (harus sudah ada)" "") || return 8
  valid_user "$user" || { ui_error "User $user tidak ditemukan."; return 1; }
  ui_yesno "Aktifkan write_enable (upload)?" && write=YES || write=NO
  ui_yesno "Aktifkan chroot_local_user?" && chroot=YES || chroot=NO
  ui_yesno "Aktifkan passive mode?" && pasv=YES || pasv=NO
  pasv_min=30000; pasv_max=30100
  backup_create "$FTP_CONF"
  mkdir -p "$TKJ_STATE/stage"
  {
    echo "listen=YES"
    echo "listen_ipv6=NO"
    echo "anonymous_enable=NO"
    echo "local_enable=YES"
    echo "write_enable=$write"
    echo "chroot_local_user=$chroot"
    echo "allow_writeable_chroot=YES"
    echo "pasv_enable=$pasv"
    echo "pasv_min_port=$pasv_min"
    echo "pasv_max_port=$pasv_max"
  } >"$TKJ_STATE/stage/vsftpd.conf"
  atomic_write "$FTP_CONF" <"$TKJ_STATE/stage/vsftpd.conf"
  svc_restart vsftpd || { ui_error "Gagal restart vsftpd."; return 7; }
  log INFO apply "user=$user write=$write chroot=$chroot"
  firewall_hint "21/tcp + ${pasv_min}-${pasv_max}/tcp"
}

ftp_validate() { grep -q '^anonymous_enable=NO' "$FTP_CONF" 2>/dev/null; }
ftp_test() {
  curl -s --max-time 3 ftp://127.0.0.1/ >/dev/null 2>&1 && ui_msg "Koneksi FTP berhasil." || {
    ui_msg "Uji manual: curl ftp://localhost/ (gunakan user $user)"
  }
}
ftp_logs() { if [[ -f /var/log/vsftpd.log ]]; then tail -50 /var/log/vsftpd.log; else tail -50 /var/log/syslog | grep -i vsftpd; fi; }
ftp_uninstall() {
  ui_yesno "Hapus vsftpd (apt purge)? Config ikut terhapus." || return 8
  backup_create "$FTP_CONF"
  ui_spin "apt-get purge vsftpd…" apt-get purge -y vsftpd
}
