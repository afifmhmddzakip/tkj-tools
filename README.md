# tkj-tools

Tool manajemen server Debian 13 (terminal interaktif via whiptail). Mengelola layanan:

| Modul | Layanan | File konfigurasi |
|-------|---------|------------------|
| DNS | BIND9 | `/etc/bind/named.conf.local` |
| FTP | vsftpd | `/etc/vsftpd.conf` |
| DHCP | ISC DHCP | `/etc/dhcp/dhcpd.conf` |
| Web | Apache2 | `/etc/apache2/sites-available` |
| SSH | OpenSSH | `/etc/ssh/sshd_config.d/99-tkj-tools.conf` |

## Persyaratan
<<<<<<< HEAD

- Debian 13 (Trixie) atau sejenis (Ubuntu 24.04+)
- Root (`sudo`)
- `whiptail` (default); bila tidak ada, tool fallback ke mode teks
- `git`, `bash`

```sh
sudo apt update
sudo apt install -y git whiptail
```

## Pasang

Clone dan jalankan langsung:

```sh
git clone https://github.com/afifmhmddzakip/tkj-tools.git
cd tkj-tools
sudo bash bin/tkj-tools
```

Untuk memanggil dari mana saja (opsional):

```sh
sudo install -m 0755 bin/tkj-tools /usr/local/bin/tkj-tools
tkj-tools
```

## Pemakaian

Menu utama: 1 DNS · 2 FTP · 3 DHCP · 4 Web · 5 SSH · 6 Diagnostik · 7 Log & Backup · 0 Keluar.

Tiap modul mendukung: `status`, `configure` (wizard), `validate`, `restart`, `test`, `logs`, `backup`, `uninstall`.

Uji otomatis (stub, non-root):

```sh
bash tests/smoke.sh
bash tests/entry.sh
=======

- Debian 13 (Trixie) atau sejenis (Ubuntu 24.04+)
- Root (`sudo`)
- `whiptail` (default tersedia). Bila tidak ada, tool otomatis fallback ke mode teks.
- `git`, `bash`

```bash
sudo apt update
sudo apt install -y git whiptail
>>>>>>> a87e189 (docs: README tutorial install + pemakaian)
```

## Instalasi

Clone dan jalankan langsung dari repo:

```bash
git clone https://github.com/afifmhmddzakip/tkj-tools.git
cd tkj-tools
sudo bash bin/tkj-tools
```

Untuk memanggil dari mana saja (opsional, pasang sebagai perintah sistem):

```bash
sudo install -m 0755 bin/tkj-tools /usr/local/bin/tkj-tools
tkj-tools
```

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

```
bin/tkj-tools        # entry point + menu
lib/core.sh           # inisialisasi, backup, logging, utils
lib/ui.sh             # wrapper whiptail + fallback teks
lib/modules/*.sh      # dns, ftp, dhcp, web, ssh
tests/smoke.sh        # uji wizard (stub, non-root)
tests/entry.sh        # uji navigasi menu
```

## Test

```bash
bash tests/smoke.sh
bash tests/entry.sh
```

## Keamanan

- SSH: mengubah port / mematikan password memicu **rollback otomatis 60 detik** jika sesi tidak dikonfirmasi.
- Setiap perubahan konfigurasi di-backup sebelum diterapkan.
- Jalankan hanya sebagai root (tool menolak non-root).
