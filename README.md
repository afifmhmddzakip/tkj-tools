# tkj-tools

Toolkit administrasi server TKJ berbasis terminal (Debian 13). Platform TUI untuk mengelola konfigurasi 5 layanan: DNS (BIND9), FTP (VSFTPD), DHCP (ISC DHCP), Web (Apache2), SSH (OpenSSH).

Instalasi paket dilakukan manual via `apt`; tool hanya mendeteksi & memandu.

## Persyaratan

- Debian 13 (Trixie) atau sejenis (Ubuntu 24.04+)
- Root (`sudo`)
- `whiptail` (default tersedia). Bila tidak ada, tool otomatis fallback ke mode teks.
- `git`, `bash`

```bash
sudo apt update
sudo apt install -y git whiptail
```

## Instalasi

Clone dan jalankan langsung dari repo:

```bash
git clone https://github.com/afifmhmddzakip/tkj-tools.git
cd tkj-tools
sudo bash bin/tkj-tools
```

Untuk memanggil dari mana saja, pasang via `install.sh` (menyalin ke `/opt/tkj-tools` + symlink `/usr/local/bin/tkj-tools`):

```bash
sudo ./install.sh
tkj-tools
```

## Uninstall

```bash
sudo ./uninstall.sh
```

Menghapus `/opt/tkj-tools` dan `/usr/local/bin/tkj-tools`.

## Pemakaian

Menu utama menyediakan:

1. **DNS Server (BIND9)** — buat zona forward/reverse, konfigurasi, validasi, test `dig`
2. **FTP Server (VSFTPD)** — wizard user + zona
3. **DHCP Server (ISC DHCP)** — subnet, range, gateway, DNS, reservasi MAC
4. **Web Server (Apache2)** — virtual host, docroot
5. **SSH Server (OpenSSH)** — port, root login, password/pubkey, pasang key, rollback otomatis 60 dtk
6. **Diagnostik Sistem** — OS, kernel, IP, status layanan, port listen
7. **Log & Backup** — backup manual, daftar backup, log tool

Setiap modul mendukung: `status`, `configure` (wizard), `validate`, `restart`, `test`, `logs`, `backup`, `uninstall`.

Backup ditaruh di `/var/backups/tkj-tools/` (timestamp).

## Struktur

- `bin/tkj-tools` — entry point
- `lib/core.sh, ui.sh, pkg.sh, service.sh, backup.sh, validate.sh, net.sh` — fondasi
- `lib/modules/{dns,ftp,dhcp,web,ssh,diag}.sh` — modul layanan
- `install.sh` / `uninstall.sh` — pasang / hapus

## Lokasi data

- Konfigurasi: `/etc/tkj-tools/`
- State: `/var/lib/tkj-tools/state/`
- Backup: `/var/backups/tkj-tools/`
- Log: `/var/log/tkj-tools/tkj-tools.log`

## Uji

```sh
bash tests/smoke.sh
bash tests/entry.sh
bash -n bin/tkj-tools lib/*.sh lib/modules/*.sh tests/*.sh
```
