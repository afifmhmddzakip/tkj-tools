# tkj-tools

Toolkit administrasi server TKJ berbasis terminal (Debian 13). Platform TUI untuk mengelola konfigurasi 5 layanan: DNS (BIND9), FTP (VSFTPD), DHCP (ISC DHCP), Web (Apache2), SSH (OpenSSH).

Instalasi paket dilakukan manual via `apt`; tool hanya mendeteksi & memandu.

## Persyaratan

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
```

## Struktur

- `bin/tkj-tools` — entry point
- `lib/core.sh, ui.sh, pkg.sh, service.sh, backup.sh, validate.sh, net.sh` — fondasi
- `lib/modules/{dns,ftp,dhcp,web,ssh,diag}.sh` — modul layanan

## Lokasi data

- Konfigurasi: `/etc/tkj-tools/`
- State: `/var/lib/tkj-tools/state/`
- Backup: `/var/backups/tkj-tools/`
- Log: `/var/log/tkj-tools/tkj-tools.log`

## Uji

```sh
bash -n bin/tkj-tools lib/*.sh lib/modules/*.sh
```
