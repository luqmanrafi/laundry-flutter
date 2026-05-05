# Flow Aplikasi Washweswos (End-to-End)

## 1. Flow Utama Sistem
Register/Login -> Home -> Pilih Layanan -> Pilih Lokasi Pickup -> Pilih Jadwal -> Buat Order -> Menunggu Kurir -> Kurir Pickup -> Input Berat -> Generate Invoice -> User Konfirmasi -> Laundry Diproses -> Delivery -> Selesai -> Riwayat

## 2. Flow Pelanggan
### A. Order Laundry
Login/Register -> Home -> Pesan Laundry -> Pilih Layanan -> Pilih Lokasi -> Pilih Jadwal Pickup -> Pesan -> Status Pending

### B. Tracking Order
Order dibuat -> Menunggu kurir -> Kurir menuju lokasi -> Kurir pickup -> Status Pickup -> Kurir input berat -> Invoice dibuat -> User menerima invoice -> User konfirmasi -> Laundry diproses -> Delivery -> Selesai

### C. Pembayaran
Terima invoice -> Lihat detail (berat x harga) -> Konfirmasi -> (Opsional: bayar) -> Lanjut ke proses

### D. Riwayat
Order selesai -> Masuk Riwayat -> Lihat detail, status, total harga

## 3. Flow Kurir
### A. Terima Order
Login -> Home Kurir -> Daftar order -> Detail order -> Terima/Ambil order

### B. Menuju Lokasi
Klik order -> Buka map -> Navigasi -> Klik "Sampai di lokasi"

### C. Pickup dan Input
Ambil laundry -> Timbang -> Input berat/item -> Buat invoice

### D. Invoice
Sistem hitung harga -> Kurir kirim invoice -> Menunggu konfirmasi user

### E. Update Status
User konfirmasi -> Kurir update status (Diproses -> Siap diantar -> Delivery) -> Selesai

## 4. Flow Admin
### A. Monitoring
Login Admin -> Dashboard -> Total order, order aktif, kurir aktif

### B. Monitoring Lokasi (SIG)
Dashboard -> Map -> Sebaran order, lokasi kurir, area layanan

### C. Manajemen
Kelola user -> Kelola kurir -> Kelola layanan/harga -> Kelola order

### D. Laporan
Ambil data -> Generate laporan harian/bulanan -> Grafik

## 5. Status Order (Patokan Sistem)
Pending -> Pickup -> Menunggu Konfirmasi -> Processing -> Delivery -> Completed

Status terminal tambahan:
- Dibatalkan (Cancelled)

## 6. Interaksi Antar Role
User buat order -> Kurir ambil -> Kurir pickup -> Kurir input data -> Sistem generate invoice -> User konfirmasi -> Kurir proses dan antar -> Selesai -> Admin monitoring

## 7. Error Flow (Bonus)
### A. User Cancel Order
User cancel -> Status Dibatalkan

### B. Gagal Konfirmasi Invoice
Invoice tidak dikonfirmasi -> Reminder -> Auto cancel (opsional)
