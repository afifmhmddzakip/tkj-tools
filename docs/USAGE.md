# Penggunaan

`tkj-tools` harus dijalankan sebagai root. Menu utama menyediakan:

- 1–5: kelola tiap layanan (status, wizard konfigurasi, validasi, restart, uji, log, backup, uninstall)
- 6: Diagnostik sistem (OS, IP, status layanan, port)
- 7: Log & backup tool
- 0: Keluar

Setiap perubahan konfigurasi dibuat backup otomatis sebelum ditulis. Validasi dijalankan sebelum restart; jika gagal, perubahan dibatalkan. Perubahan SSH memakai timer rollback 60 detik bila tidak dikonfirmasi.
