# Product Requirements Document (PRD)

## tkj-tools — Toolkit Administrasi Server TKJ Berbasis Terminal

| Field | Keterangan |
|---|---|
| Nama Produk | `tkj-tools` |
| Versi Dokumen | 1.0 (Draft) |
| Tanggal | 9 November 2026 |
| Status | Draft untuk review |
| Pemilik Produk | Tim tkj-tools |
| Target Platform | Debian 13 (trixie) — CLI / headless |
| Jenis Produk | CLI + Terminal UI (TUI) |
| Lisensi | TBD (lihat Pertanyaan Terbuka) |

---

## 1. Ringkasan Eksekutif

`tkj-tools` adalah perkakas berbasis shell script dan Terminal UI (TUI) untuk membantu siswa, guru, dan teknisi TKJ menyiapkan serta mengelola layanan server dasar di Debian 13 melalui satu antarmuka menu yang konsisten.

MVP berfokus pada lima layanan:

1. DNS Server — BIND9
2. FTP Server — VSFTPD
3. DHCP Server — ISC DHCP Server
4. Web Server — Apache2
5. Remote Access Server — OpenSSH

Setiap layanan dapat dipasang, dikonfigurasi, divalidasi, dijalankan, diuji, dicadangkan, dan dihapus dari menu yang sama tanpa harus menghafal lokasi file konfigurasi atau urutan perintah.

---

## 2. Latar Belakang & Masalah

Praktik konfigurasi server di jurusan TKJ umumnya dilakukan secara manual: mengedit file di `/etc`, menjalankan `systemctl`, lalu mengecek hasilnya dengan perintah yang berbeda-beda. Pola ini menimbulkan beberapa masalah:

- **Rawan salah ketik dan salah path** saat mengedit konfigurasi.
- **Tidak ada validasi sebelum restart**, sehingga layanan bisa gagal menyala.
- **Tidak ada backup otomatis**, sehingga konfigurasi lama sulit dikembalikan.
- **Pengetahuan tersebar** di banyak modul dan tidak seragam antar kelas.
- **Proses instalasi dan konfigurasi memakan waktu**, terutama saat harus diulang di banyak VM.
- **Risiko lockout** saat mengubah konfigurasi SSH.

`tkj-tools` hadir sebagai lapisan pembantu yang menyederhanakan alur tersebut, tanpa menyembunyikan konsep dasar: pengguna tetap melihat file, perintah, dan hasil validasi yang digunakan.

---

## 3. Tujuan & Non-Tujuan

### 3.1 Tujuan

| ID | Tujuan | Ukuran Keberhasilan |
|---|---|---|
| G-01 | Menyediakan satu pintu masuk untuk mengelola lima layanan server TKJ | Semua layanan dapat diakses dari menu utama |
| G-02 | Mempercepat penyiapan layanan | Konfigurasi dasar selesai < 5 menit per layanan |
| G-03 | Mengurangi kegagalan konfigurasi | Validasi dijalankan sebelum layanan di-restart |
| G-04 | Memberi rasa aman saat mengubah konfigurasi | Backup otomatis + opsi restore |
| G-05 | Menjadi media belajar yang transparan | Pengguna dapat melihat perintah dan file yang diubah |
| G-06 | Menjaga dependensi tetap ringan | Tidak ada runtime tambahan selain paket sistem |

### 3.2 Non-Tujuan (MVP)

- Bukan control panel berbasis web (tidak ada UI browser).
- Bukan pengganti pemahaman konsep jaringan/server.
- Tidak menangani mail server, database server, container, atau Kubernetes.
- Tidak melakukan manajemen multi-server terpusat.
- Tidak mendukung distro selain Debian 13 pada MVP.
- Tidak mengubah firewall secara diam-diam tanpa persetujuan pengguna.
- Tidak menyimpan password dalam bentuk plaintext.
- Tidak berjalan sebagai daemon di latar belakang.

---

## 4. Target Pengguna & Lingkungan

### 4.1 Persona

| Persona | Kebutuhan Utama | Tingkat Keahlian |
|---|---|---|
| Siswa TKJ | Belajar konfigurasi server langkah demi langkah | Pemula–menengah |
| Guru / Instruktur | Menyiapkan lab cepat dan seragam | Menengah–mahir |
| Teknisi Lab | Memasang ulang layanan di banyak VM | Mahir |
| Admin Sekolah | Merawat layanan yang sudah berjalan | Menengah |

### 4.2 Lingkungan Target

- **OS:** Debian 13 (trixie), instalasi minimal atau standard.
- **Mode:** CLI/headless, diakses langsung atau melalui SSH.
- **Arsitektur:** amd64 dan arm64.
- **Inisiatif sistem:** systemd.
- **Hak akses:** root atau `sudo`.
- **Terminal:** minimal 80×24, mendukung warna dasar.
- **RAM:** dapat berjalan nyaman pada VM 512 MB–1 GB.
- **Jaringan:** minimal satu antarmuka dengan IP statis untuk layanan server.
- **Internet:** diperlukan saat instalasi paket; aplikasi tidak melakukan panggilan internet saat runtime.

### 4.3 Asumsi

- Pengguna memiliki hak root.
- Paket diambil dari repositori resmi Debian.
- Satu instance `tkj-tools` mengelola satu mesin.
- Layanan yang dikelola tidak sedang dikonfigurasi bersamaan oleh alat lain.

---

## 5. Ruang Lingkup MVP

| Fitur | Paket | Prioritas | Ringkasan |
|---|---|---|---|
| DNS Server | `bind9`, `bind9-utils`, `bind9-dnsutils` | Must | Zona forward/reverse, forwarder, validasi, uji query |
| FTP Server | `vsftpd` | Must | User lokal, chroot, write, passive port, uji koneksi |
| DHCP Server | `isc-dhcp-server` | Must | Interface, subnet, pool, gateway, DNS, reservasi |
| Web Server | `apache2` | Must | Virtual host, document root, modul dasar, uji HTTP |
| SSH Server | `openssh-server` | Must | Port, kebijakan login, key, apply aman |
| Diagnostik | — | Should | Status layanan, port, log, validasi massal |
| Backup/Restore | — | Must | Backup sebelum perubahan dan restore |
| Mode non-interaktif | — | Could | Subcommand untuk otomasi |
| TLS FTP/Web | `openssl` | Could | Sertifikat self-signed |

**Di luar MVP:** Kea DHCP, IPv6, DNS slave, clustering, panel web, paket `.deb`, multi-bahasa penuh.

---

## 6. Kebutuhan Fungsional

### 6.1 Kebutuhan Umum (FR-COM)

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-COM-01 | Memeriksa `EUID == 0`; menolak berjalan jika bukan root dengan pesan jelas | Must |
| FR-COM-02 | Memeriksa `/etc/os-release`; memastikan `ID=debian` dan `VERSION_ID=13`; memberi peringatan (bukan blokir) jika berbeda | Must |
| FR-COM-03 | Mendeteksi dependensi (`bash`, `whiptail`, `systemctl`, `apt`, `ip`, `ss`, `dig`/`curl`) dan menawarkan instalasi | Must |
| FR-COM-04 | Menyediakan menu utama TUI untuk memilih layanan | Must |
| FR-COM-05 | Menyediakan navigasi konsisten: Kembali, Batal, Keluar | Must |
| FR-COM-06 | Mendeteksi status tiap layanan: belum terpasang, terpasang, aktif, gagal, dikelola oleh tool | Must |
| FR-COM-07 | Membuat backup konfigurasi sebelum setiap perubahan | Must |
| FR-COM-08 | Menyediakan daftar backup dan opsi restore | Must |
| FR-COM-09 | Mencatat aktivitas ke log dengan timestamp, level, modul, dan aksi | Must |
| FR-COM-10 | Mendukung idempotensi: menjalankan ulang konfigurasi yang sama tidak merusak state | Must |
| FR-COM-11 | Menyediakan mode dry-run: menampilkan diff tanpa menulis file | Should |
| FR-COM-12 | Memvalidasi input pengguna (IP, CIDR, port, domain, path, nama user) | Must |
| FR-COM-13 | Menampilkan ringkasan hasil akhir: file diubah, layanan, status, dan langkah uji | Must |
| FR-COM-14 | Menyediakan menu Diagnostik (OS, IP, port, status layanan, disk, log) | Should |
| FR-COM-15 | Memasang konfigurasi logrotate untuk log tool | Should |
| FR-COM-16 | Menyediakan uninstall per layanan dengan konfirmasi eksplisit | Must |
| FR-COM-17 | Menangani `Ctrl+C`/ESC tanpa meninggalkan file sementara | Must |
| FR-COM-18 | Menyediakan fallback prompt teks jika `whiptail` tidak tersedia | Should |
| FR-COM-19 | Menyediakan subcommand non-interaktif (`status`, `validate`, `backup`) | Could |
| FR-COM-20 | Menampilkan peringatan sebelum aksi berisiko (restart jaringan, ubah SSH, stop DHCP) | Must |

### 6.2 DNS Server (BIND9) — FR-DNS

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-DNS-01 | Memasang `bind9`, `bind9-utils`, `bind9-dnsutils` jika belum ada | Must |
| FR-DNS-02 | Memilih mode: **forwarder/cache** atau **authoritative** | Must |
| FR-DNS-03 | Mengatur `listen-on`, `listen-on-v6`, `allow-query`, dan forwarder | Must |
| FR-DNS-04 | Membuat zona forward (`db.<domain>`) dengan record A, CNAME, MX, TXT | Must |
| FR-DNS-05 | Membuat zona reverse (`db.<x.y.z.in-addr.arpa>`) dengan record PTR | Must |
| FR-DNS-06 | Mendaftarkan zona ke `named.conf.local` secara idempotent | Must |
| FR-DNS-07 | Memvalidasi dengan `named-checkconf` dan `named-checkzone` sebelum restart | Must |
| FR-DNS-08 | Mengaktifkan dan me-restart `bind9`/`named`; reload via `rndc` bila memungkinkan | Must |
| FR-DNS-09 | Menguji query dengan `dig` ke `127.0.0.1` dan menampilkan hasil | Must |
| FR-DNS-10 | Menampilkan rekomendasi aturan firewall untuk port 53/tcp dan 53/udp | Should |
| FR-DNS-11 | Menyediakan uninstall yang menghapus zona buatan tool (dengan konfirmasi) | Must |
| FR-DNS-12 | Memeriksa konflik dengan `systemd-resolved` pada port 53 | Should |

**Kriteria Penerimaan DNS**

- [ ] Pengguna dapat membuat zona `lab.tkj` beserta reverse zone melalui wizard.
- [ ] `named-checkconf` dan `named-checkzone` dijalankan dan hasilnya ditampilkan.
- [ ] `dig @127.0.0.1 nama.lab.tkj` mengembalikan IP yang dikonfigurasi.
- [ ] Jika validasi gagal, layanan **tidak** di-restart dan perubahan terakhir dapat dibatalkan.
- [ ] Backup file lama tersimpan sebelum perubahan.

### 6.3 FTP Server (VSFTPD) — FR-FTP

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-FTP-01 | Memasang `vsftpd` jika belum ada | Must |
| FR-FTP-02 | Menonaktifkan anonymous login secara default | Must |
| FR-FTP-03 | Mengaktifkan `local_enable` dan memilih/membuat user FTP | Must |
| FR-FTP-04 | Mengatur `chroot_local_user` dan `allow_writeable_chroot` dengan aman | Must |
| FR-FTP-05 | Mengatur `write_enable` sesuai pilihan pengguna | Must |
| FR-FTP-06 | Mengatur rentang passive port (default 30000–30100) dan `pasv_address` | Must |
| FR-FTP-07 | Memvalidasi kombinasi konfigurasi dan menampilkan peringatan untuk opsi berisiko | Must |
| FR-FTP-08 | Mengaktifkan dan me-restart `vsftpd`, lalu memeriksa status | Must |
| FR-FTP-09 | Menguji koneksi lokal dengan `curl`/`ftp` bila tersedia | Should |
| FR-FTP-10 | Menampilkan rekomendasi firewall (21/tcp + passive range) | Should |
| FR-FTP-11 | Mendukung TLS self-signed (`ssl_enable=YES`) | Could |
| FR-FTP-12 | Menyediakan uninstall dan pembersihan user/konfigurasi | Must |

**Kriteria Penerimaan FTP**

- [ ] Anonymous login ditolak.
- [ ] User lokal dapat login dan melihat direktori sesuai chroot.
- [ ] Upload berhasil jika `write_enable=YES`.
- [ ] Mode passive berfungsi dari klien di jaringan lab.
- [ ] Konfigurasi tidak valid tidak diterapkan.

### 6.4 DHCP Server (ISC DHCP) — FR-DHCP

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-DHCP-01 | Memasang `isc-dhcp-server` jika belum ada | Must |
| FR-DHCP-02 | Memilih antarmuka layanan dan memastikan antarmuka memiliki IP statis | Must |
| FR-DHCP-03 | Mengatur subnet, netmask, range, gateway, DNS, domain, dan lease time | Must |
| FR-DHCP-04 | Mendukung reservasi alamat berdasarkan MAC address | Should |
| FR-DHCP-05 | Menulis `INTERFACESv4` pada `/etc/default/isc-dhcp-server` | Must |
| FR-DHCP-06 | Memvalidasi dengan `dhcpd -t` sebelum restart | Must |
| FR-DHCP-07 | Memperingatkan bahwa satu segmen jaringan sebaiknya hanya memiliki satu DHCP server | Must |
| FR-DHCP-08 | Mengaktifkan dan me-restart `isc-dhcp-server`, lalu memeriksa status | Must |
| FR-DHCP-09 | Menampilkan rekomendasi firewall untuk 67/udp | Should |
| FR-DHCP-10 | Menyediakan uninstall dan pembersihan konfigurasi | Must |

**Kriteria Penerimaan DHCP**

- [ ] Klien di segmen yang sama memperoleh IP dari range yang dikonfigurasi.
- [ ] Gateway dan DNS yang diberikan sesuai pengaturan.
- [ ] Reservasi MAC menghasilkan IP yang sama setiap kali.
- [ ] `dhcpd -t` gagal → layanan tidak di-restart.
- [ ] Tool memberi peringatan jika antarmuka belum memiliki IP statis.

### 6.5 Web Server (Apache2) — FR-WEB

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-WEB-01 | Memasang `apache2` jika belum ada | Must |
| FR-WEB-02 | Membuat virtual host baru di `sites-available` dan mengaktifkannya | Must |
| FR-WEB-03 | Mengatur `ServerName`, `DocumentRoot`, dan permission direktori | Must |
| FR-WEB-04 | Mengaktifkan modul dasar yang dipilih (`rewrite`, `headers`, `ssl`) | Should |
| FR-WEB-05 | Membuat halaman `index.html` contoh (opsional) | Could |
| FR-WEB-06 | Memvalidasi dengan `apache2ctl configtest` sebelum reload/restart | Must |
| FR-WEB-07 | Mengaktifkan dan me-reload `apache2` | Must |
| FR-WEB-08 | Menguji HTTP dengan `curl` ke `localhost`/virtual host | Should |
| FR-WEB-09 | Menampilkan rekomendasi firewall untuk 80/tcp dan 443/tcp | Should |
| FR-WEB-10 | Mendukung TLS self-signed per virtual host | Could |
| FR-WEB-11 | Menyediakan uninstall virtual host tanpa menghapus Apache secara paksa | Must |

**Kriteria Penerimaan Web**

- [ ] Virtual host dapat diakses melalui `Host` header/domain yang dikonfigurasi.
- [ ] `apache2ctl configtest` sukses sebelum reload.
- [ ] Konfigurasi gagal tidak membuat Apache berhenti.
- [ ] Document root memiliki permission yang benar dan tidak world-writable.

### 6.6 SSH Server (OpenSSH) — FR-SSH

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-SSH-01 | Memasang `openssh-server` jika belum ada | Must |
| FR-SSH-02 | Mendeteksi apakah SSH berjalan via `ssh.service` atau `ssh.socket` | Must |
| FR-SSH-03 | Mengatur port, `PermitRootLogin`, `PasswordAuthentication`, dan `PubkeyAuthentication` | Must |
| FR-SSH-04 | Mengimpor public key ke `authorized_keys` user yang dipilih | Should |
| FR-SSH-05 | Memvalidasi dengan `sshd -t` sebelum menerapkan | Must |
| FR-SSH-06 | Menerapkan perubahan dengan mekanisme **auto-rollback** jika koneksi tidak dikonfirmasi | Must |
| FR-SSH-07 | Menampilkan peringatan eksplisit sebelum mengubah port atau mematikan password login | Must |
| FR-SSH-08 | Menampilkan rekomendasi firewall untuk port SSH yang dipakai | Should |
| FR-SSH-09 | Menyediakan uninstall tanpa memutus sesi aktif secara paksa | Must |
| FR-SSH-10 | Menampilkan perintah uji koneksi dari klien lain | Must |

**Kriteria Penerimaan SSH**

- [ ] Perubahan port dapat diuji tanpa kehilangan akses permanen.
- [ ] Jika pengguna tidak mengonfirmasi dalam batas waktu, konfigurasi lama dipulihkan otomatis.
- [ ] `sshd -t` gagal → tidak ada restart.
- [ ] Public key dapat ditambahkan dan login key berhasil.
- [ ] Tool mendeteksi socket activation dan menyesuaikan cara apply.

### 6.7 Diagnostik & Log — FR-DIAG

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-DIAG-01 | Menampilkan ringkasan OS, kernel, arsitektur, uptime, dan IP | Should |
| FR-DIAG-02 | Menampilkan status kelima layanan dalam satu layar | Should |
| FR-DIAG-03 | Menampilkan port yang sedang listen (`ss -tulpn`) | Should |
| FR-DIAG-04 | Menjalankan validasi konfigurasi semua layanan sekaligus | Should |
| FR-DIAG-05 | Melihat 50 baris log terakhir per layanan | Should |
| FR-DIAG-06 | Menampilkan daftar backup dan ukurannya | Should |

---

## 7. Kebutuhan Non-Fungsional

| ID | Kategori | Kebutuhan | Target |
|---|---|---|---|
| NFR-01 | Performa | Waktu buka menu utama | < 1 detik |
| NFR-02 | Jejak sumber daya | Tanpa daemon; ukuran skrip total | < 500 KB |
| NFR-03 | Kompatibilitas | Debian 13 minimal & standard, amd64/arm64 | 100% |
| NFR-04 | Keamanan | Root-only, `umask 077`, tidak ada secret di log | Wajib |
| NFR-05 | Keandalan | Penulisan file atomik (temp + `mv`), backup sebelum ubah | Wajib |
| NFR-06 | Keandalan | Rollback otomatis untuk perubahan SSH | Wajib |
| NFR-07 | Usability | Keyboard-only, berfungsi di 80×24, teks Bahasa Indonesia | Wajib |
| NFR-08 | Maintainability | Modular per layanan, lolos `shellcheck` | Wajib |
| NFR-09 | Offline-friendly | Tidak ada panggilan jaringan saat runtime | Wajib |
| NFR-10 | Aksesibilitas | Tidak mengandalkan warna saja untuk status | Wajib |
| NFR-11 | Lokalisasi | Struktur siap untuk `id` dan `en` | Should |
| NFR-12 | Portabilitas | Tidak menggunakan fitur Bash di luar versi 5.2 | Wajib |
| NFR-13 | Keamanan | Input divalidasi; tidak menggunakan `eval` pada input pengguna | Wajib |
| NFR-14 | Observability | Log konsisten dan dapat dibaca manusia | Wajib |

---

## 8. Desain UX / TUI

### 8.1 Prinsip

1. **Satu layar, satu keputusan.** Jangan menumpuk terlalu banyak pertanyaan.
2. **Selalu ada jalan keluar.** ESC/Batal kembali tanpa efek samping.
3. **Konfirmasi untuk aksi merusak.** Restart, stop, uninstall, ubah SSH.
4. **Tampilkan konsekuensi.** Sebelum apply, tampilkan ringkasan dan diff.
5. **Jangan sembunyikan perintah.** Tampilkan perintah yang dijalankan (opsional via "Mode Belajar").
6. **Bahasa konsisten.** Gunakan istilah Indonesia + nama teknis dalam tanda kurung.

### 8.2 Peta Navigasi

```text
Menu Utama
├── 1. DNS Server (BIND9)
│   ├── Status & Informasi
│   ├── Pasang
│   ├── Konfigurasi (wizard)
│   ├── Validasi
│   ├── Start / Stop / Restart
│   ├── Uji Query
│   ├── Lihat Log
│   ├── Backup / Restore
│   └── Uninstall
├── 2. FTP Server (VSFTPD)        [struktur serupa]
├── 3. DHCP Server (ISC DHCP)     [struktur serupa]
├── 4. Web Server (Apache2)       [struktur serupa]
├── 5. SSH Server (OpenSSH)       [struktur serupa]
├── 6. Diagnostik Sistem
├── 7. Log & Backup
└── 0. Keluar
```

### 8.3 Mockup Menu Utama

```text
┌──────────────────────────────────────────────────────────┐
│  tkj-tools v0.1.0                    Debian 13 · root    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│   Pilih layanan yang ingin dikelola:                     │
│                                                          │
│     1  DNS Server        BIND9        ● aktif            │
│     2  FTP Server        VSFTPD       ○ belum terpasang  │
│     3  DHCP Server       ISC DHCP     ● aktif            │
│     4  Web Server        Apache2      ● aktif            │
│     5  SSH Server        OpenSSH      ● aktif            │
│                                                          │
│     6  Diagnostik Sistem                                 │
│     7  Log & Backup                                      │
│     0  Keluar                                            │
│                                                          │
├──────────────────────────────────────────────────────────┤
│  ↑↓ navigasi   Enter pilih   q keluar                    │
└──────────────────────────────────────────────────────────┘
```

### 8.4 Pola Interaksi

| Aksi | Perilaku |
|---|---|
| Panah atas/bawah | Memindahkan pilihan |
| Enter | Memilih |
| ESC | Kembali / batal |
| `q` | Keluar dari menu utama (dengan konfirmasi jika ada proses) |
| Aksi destruktif | `--yesno` dengan default **No** |
| Proses panjang | `--gauge` / spinner + log singkat |
| Error | Kotak error + saran tindakan |
| Sukses | Ringkasan + langkah verifikasi |

### 8.5 Alur Wizard Konfigurasi

```text
Preflight (root, OS, paket, konflik)
        │
        ▼
Form input (validasi per field)
        │
        ▼
Pratinjau perubahan (diff)
        │
        ▼
Konfirmasi
        │
        ▼
Backup → Tulis file → Validasi
        │                  │
        │            gagal │ sukses
        │                  ▼
        │             Restart/Reload
        │                  │
        │            gagal │ sukses
        │                  ▼
        └──────────► Rollback + pesan error
                           │
                           ▼
                    Uji fungsi + ringkasan
```

---

## 9. Arsitektur Teknis

### 9.1 Keputusan Stack

| Opsi | Kelebihan | Kekurangan | Keputusan |
|---|---|---|---|
| **Bash + whiptail** | Ringan, tersedia di Debian, mudah dipelajari | TUI terbatas | **Dipilih** |
| Bash + dialog | Widget lebih kaya | Perlu paket tambahan | Alternatif |
| Python + Textual | TUI modern | Runtime & dependensi lebih berat | Ditolak untuk MVP |
| Go + Bubble Tea | Binary mandiri | Toolchain dan ukuran build lebih besar | Roadmap |

**Alasan:** target utama adalah lingkungan Debian CLI dengan dependensi minimal. `whiptail` (paket `newt`) sudah tersedia pada instalasi Debian standar dan cukup untuk kebutuhan menu, form, checklist, dan progress.

### 9.2 Struktur Direktori

```text
tkj-tools/
├── bin/
│   └── tkj-tools                 # entry point
├── lib/
│   ├── core.sh                   # bootstrap, root/OS check, exit code
│   ├── ui.sh                     # wrapper whiptail + fallback teks
│   ├── pkg.sh                    # apt install/remove/query
│   ├── service.sh                # systemctl helpers
│   ├── backup.sh                 # backup, restore, manifest
│   ├── validate.sh               # validator input & konfigurasi
│   ├── net.sh                    # ip, port, firewall hints
│   └── modules/
│       ├── dns.sh
│       ├── ftp.sh
│       ├── dhcp.sh
│       ├── web.sh
│       ├── ssh.sh
│       └── diag.sh
├── templates/
│   ├── bind/
│   ├── vsftpd/
│   ├── dhcp/
│   ├── apache/
│   └── ssh/
├── share/
│   └── lang/
│       ├── id.sh
│       └── en.sh                 # opsional
├── tests/
│   ├── unit/
│   └── integration/
├── docs/
│   ├── PRD.md
│   └── USAGE.md
├── install.sh
└── README.md
```

### 9.3 Kontrak Modul

Setiap modul layanan wajib menyediakan fungsi berikut:

```bash
module_status()      # belum terpasang / terpasang / aktif / gagal
module_install()     # pasang paket
module_configure()   # wizard konfigurasi
module_validate()    # validasi konfigurasi
module_apply()       # backup + tulis + validate + restart
module_test()        # uji fungsi
module_logs()        # tampilkan log
module_uninstall()   # hapus konfigurasi/paket
```

Modul tidak boleh memanggil `whiptail` secara langsung; semua interaksi melalui `ui.sh`.

### 9.4 Lokasi File Tool

| Path | Fungsi |
|---|---|
| `/etc/tkj-tools/config.conf` | Preferensi tool (bahasa, mode belajar, timeout rollback) |
| `/var/lib/tkj-tools/state/` | State per modul (`managed=1`, timestamp apply) |
| `/var/backups/tkj-tools/<timestamp>/` | Backup konfigurasi |
| `/var/log/tkj-tools/tkj-tools.log` | Log aktivitas |
| `/etc/logrotate.d/tkj-tools` | Rotasi log |

### 9.5 Format Backup

```text
/var/backups/tkj-tools/20261109-142530/
├── manifest.tsv          # modul, path asli, path backup, checksum
├── dns/
│   └── etc/bind/named.conf.local
├── web/
│   └── etc/apache2/sites-available/lab.conf
└── ...
```

Aturan:

- Backup dibuat **sebelum** perubahan.
- File disimpan dengan path relatif dari root agar mudah dipulihkan.
- `manifest.tsv` mencatat checksum untuk verifikasi.
- Retensi default: 20 backup terakhir (dapat diubah).

### 9.6 Logging

Format:

```text
2026-11-09T14:25:30+07:00 INFO  dns   apply_start domain=lab.tkj
2026-11-09T14:25:31+07:00 WARN  dns   validate_skip reason=dry-run
2026-11-09T14:25:32+07:00 ERROR ssh   validate_failed exit=1
```

Aturan:

- Tidak mencatat password, private key, atau isi file sensitif.
- Log ditulis ke file dan ditampilkan di TUI.
- Rotasi: harian, simpan 14 hari, kompresi.

### 9.7 Exit Code

| Code | Arti |
|---|---|
| 0 | Sukses |
| 1 | Error umum |
| 2 | Argumen tidak valid |
| 3 | Bukan root |
| 4 | OS tidak didukung |
| 5 | Dependensi hilang |
| 6 | Validasi konfigurasi gagal |
| 7 | Apply/restart gagal |
| 8 | Dibatalkan pengguna |

### 9.8 Prinsip Keamanan Implementasi

- `set -Eeuo pipefail` pada entry point.
- Semua variabel di-quote (`"$var"`).
- Tidak menggunakan `eval` untuk input pengguna.
- Validasi path agar tidak keluar dari direktori yang diizinkan.
- Penulisan file melalui temp file + `mv` atomik.
- File konfigurasi baru memakai permission yang sesuai (umumnya `0644`, secret `0600`).
- Perubahan SSH memakai timer rollback (`systemd-run --on-active=...`) atau mekanisme setara.

---

## 10. Alur Utama: Apply Perubahan

1. **Preflight** — cek root, OS, paket, konflik port, status layanan.
2. **Input** — wizard mengumpulkan parameter.
3. **Validasi input** — format IP, CIDR, port, domain, path, user.
4. **Render** — template diisi ke file sementara.
5. **Diff** — tampilkan perbedaan terhadap konfigurasi aktif.
6. **Konfirmasi** — pengguna menyetujui.
7. **Backup** — simpan konfigurasi lama + manifest.
8. **Tulis** — pasang file baru secara atomik.
9. **Validasi layanan** — `named-checkconf`, `dhcpd -t`, `apache2ctl configtest`, `sshd -t`, cek VSFTPD.
10. **Apply** — restart/reload, dengan rollback jika gagal.
11. **Verifikasi** — cek status dan uji fungsi.
12. **Ringkasan** — tampilkan hasil, file, port, dan langkah uji manual.

Jika langkah 9 atau 10 gagal:

- Kembalikan file dari backup.
- Restart layanan dengan konfigurasi lama.
- Tampilkan error + lokasi log.

---

## 11. Rencana Pengujian & QA

### 11.1 Jenis Pengujian

| Jenis | Alat | Cakupan |
|---|---|---|
| Statis | `shellcheck`, `shfmt` | Seluruh skrip |
| Unit | `bats-core` (dev-only) | Validator input, parser, fungsi backup |
| Integrasi | VM Debian 13 | Instalasi, konfigurasi, restart, rollback |
| Negatif | VM | IP salah, port konflik, konfigurasi rusak, paket hilang |
| Manual | Checklist | UX, alur wizard, pesan error |
| Regresi | VM snapshot | Sebelum rilis |

### 11.2 Matriks Uji

| Skenario | DNS | FTP | DHCP | Web | SSH |
|---|---|---|---|---|---|
| Instalasi bersih | ✓ | ✓ | ✓ | ✓ | ✓ |
| Konfigurasi ulang | ✓ | ✓ | ✓ | ✓ | ✓ |
| Validasi gagal | ✓ | ✓ | ✓ | ✓ | ✓ |
| Restart gagal | ✓ | ✓ | ✓ | ✓ | ✓ |
| Rollback | ✓ | ✓ | ✓ | ✓ | ✓ |
| Uninstall | ✓ | ✓ | ✓ | ✓ | ✓ |
| Tanpa internet saat runtime | ✓ | ✓ | ✓ | ✓ | ✓ |
| Terminal 80×24 | ✓ | ✓ | ✓ | ✓ | ✓ |

### 11.3 Uji Khusus

- **SSH lockout:** ubah port, putuskan koneksi, pastikan rollback berjalan.
- **DHCP:** dua server DHCP dalam satu segmen → peringatan.
- **DNS:** zona duplikat dan record salah → validasi menolak.
- **Web:** document root tanpa izin baca → error jelas.
- **FTP:** user tanpa shell valid → pesan diagnostik.

---

## 12. Metrik Keberhasilan

| Metrik | Target |
|---|---|
| Waktu konfigurasi dasar per layanan | < 5 menit |
| Konfigurasi lolos validasi pada percobaan pertama | ≥ 95% |
| Kejadian lockout SSH tanpa pemulihan | 0 |
| Pengguna yang berhasil menyelesaikan wizard tanpa bantuan | ≥ 80% (uji kelas) |
| Error yang tidak tertangani (unhandled) | 0 pada jalur utama |
| Waktu buka menu | < 1 detik |

---

## 13. Milestone & Timeline

| Milestone | Deliverable | Kriteria Keluar |
|---|---|---|
| M0 — Fondasi | Entry point, `ui.sh`, `core.sh`, `pkg.sh`, `service.sh`, backup, log | Menu utama + diagnostik berjalan |
| M1 — Layanan risiko rendah | Web + SSH | Vhost dibuat, SSH apply dengan rollback |
| M2 — DNS | Wizard zona forward/reverse | `dig` berhasil, validasi menolak input salah |
| M3 — FTP | Wizard VSFTPD | Login, chroot, upload, passive berfungsi |
| M4 — DHCP | Wizard ISC DHCP | Klien memperoleh lease, validasi berjalan |
| M5 — Hardening & rilis | Docs, shellcheck clean, uji VM, installer | Checklist QA lengkap |

Estimasi: 4–6 minggu setelah PRD disetujui (1 pengembang paruh waktu).

---

## 14. Risiko & Mitigasi

| Risiko | Dampak | Kemungkinan | Mitigasi |
|---|---|---|---|
| Lockout saat mengubah SSH | Tinggi | Sedang | Auto-rollback, konfirmasi, uji dari sesi kedua |
| ISC DHCP sudah EOL di hulu | Tinggi | Tinggi | Dukungan Debian 13 tetap ada; roadmap migrasi ke Kea |
| Konflik dengan `systemd-resolved` (port 53) | Sedang | Sedang | Deteksi dini + panduan menonaktifkan stub listener |
| Firewall tidak dikonfigurasi | Sedang | Tinggi | Tampilkan perintah, tawarkan apply dengan konfirmasi |
| AppArmor memblokir path baru | Sedang | Rendah | Deteksi `aa-status`, tampilkan pesan |
| Perbedaan versi paket Debian | Sedang | Sedang | Uji di Debian 13 terbaru, hindari parsing output rapuh |
| `whiptail` tidak tersedia | Rendah | Rendah | Fallback prompt teks |
| Scope creep | Sedang | Tinggi | Non-goals eksplisit, review tiap milestone |
| Pengguna menjalankan di distro lain | Sedang | Sedang | Cek OS + peringatan, bukan blokir |
| Kesalahan pengguna saat uninstall | Tinggi | Rendah | Konfirmasi ganda, backup wajib |

---

## 15. Roadmap Pasca-MVP

1. **v0.2** — TLS untuk FTP dan Web (self-signed + impor sertifikat).
2. **v0.3** — Modul firewall (nftables/ufw) dengan profil per layanan.
3. **v0.4** — Migrasi opsi DHCP ke Kea; dukungan IPv6.
4. **v0.5** — Mode non-interaktif penuh + output JSON untuk otomasi.
5. **v0.6** — Paket `.deb`, repo APT internal.
6. **v1.0** — Modul tambahan (NTP, Samba, reverse proxy), dokumentasi lengkap, lokalisasi `en`.

---

## 16. Pertanyaan Terbuka

| ID | Pertanyaan | Dampak | Pemilik |
|---|---|---|---|
| Q-01 | Lisensi proyek (MIT/GPL-3.0)? | Distribusi & kontribusi | Pemilik produk |
| Q-02 | DHCP: tetap ISC DHCP atau langsung Kea? | Arsitektur modul | Tech lead |
| Q-03 | Perlukah mode non-interaktif di MVP? | Scope | Pemilik produk |
| Q-04 | Apakah TLS harus default untuk FTP/Web? | Keamanan vs kesederhanaan | Pemilik produk |
| Q-05 | Dukungan Debian 12 juga, atau hanya 13? | Kompatibilitas | Tech lead |
| Q-06 | Apakah tool perlu menampilkan perintah secara default ("Mode Belajar")? | UX | Guru/instruktur |
| Q-07 | Format bahasa: Indonesia saja atau bilingual? | Lokalisasi | Pemilik produk |

---

## 17. Lampiran

### 17.1 Contoh Konfigurasi yang Dihasilkan

**BIND9 — `/etc/bind/named.conf.local`**

```conf
// dikelola oleh tkj-tools
zone "lab.tkj" {
    type master;
    file "/etc/bind/db.lab.tkj";
};

zone "10.10.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.10.10.10";
};
```

**BIND9 — `/etc/bind/db.lab.tkj`**

```conf
$TTL 604800
@   IN  SOA ns1.lab.tkj. admin.lab.tkj. (
        2026110901 ; serial
        3600       ; refresh
        1800       ; retry
        604800     ; expire
        86400 )    ; minimum
@       IN  NS   ns1.lab.tkj.
ns1     IN  A    10.10.10.1
server  IN  A    10.10.10.10
www     IN  CNAME server
```

**VSFTPD — `/etc/vsftpd.conf` (potongan)**

```conf
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30100
```

**ISC DHCP — `/etc/dhcp/dhcpd.conf` (potongan)**

```conf
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 10.10.10.0 netmask 255.255.255.0 {
    range 10.10.10.100 10.10.10.200;
    option routers 10.10.10.1;
    option domain-name-servers 10.10.10.1;
    option domain-name "lab.tkj";
}

host pc01 {
    hardware ethernet 08:00:27:12:34:56;
    fixed-address 10.10.10.50;
}
```

**Apache2 — `/etc/apache2/sites-available/lab.conf`**

```apache
<VirtualHost *:80>
    ServerName lab.tkj
    ServerAlias www.lab.tkj
    DocumentRoot /var/www/lab

    <Directory /var/www/lab>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/lab-error.log
    CustomLog ${APACHE_LOG_DIR}/lab-access.log combined
</VirtualHost>
```

**OpenSSH — `/etc/ssh/sshd_config.d/99-tkj-tools.conf`**

```conf
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

### 17.2 Checklist Rilis MVP

- [ ] `shellcheck` tanpa error pada seluruh skrip.
- [ ] Menu utama dan kelima submenu dapat diakses.
- [ ] Instalasi bersih di Debian 13 minimal berhasil untuk semua layanan.
- [ ] Backup dan restore diuji.
- [ ] Rollback SSH diuji.
- [ ] Validasi menolak input tidak valid.
- [ ] Log dan logrotate berfungsi.
- [ ] Dokumentasi `README.md` dan `USAGE.md` tersedia.
- [ ] Tidak ada kredensial atau data sensitif di log.
- [ ] Uninstall tidak merusak layanan lain.

### 17.3 Referensi

- Debian 13 Release Notes — <https://www.debian.org/releases/trixie/>
- BIND 9 Administrator Reference Manual
- `vsftpd.conf(5)`
- ISC DHCP `dhcpd.conf(5)`
- Apache HTTP Server Documentation
- `sshd_config(5)`, `ssh_config(5)`

---

*Dokumen ini adalah draft. Perubahan scope harus melalui review dan pembaruan versi dokumen.*
