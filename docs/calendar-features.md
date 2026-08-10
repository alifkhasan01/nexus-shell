# CalendarPanel - Dokumentasi Fitur

## 🎯 Fitur Lengkap

### 1. 📅 Event System
**Cara Menggunakan:**
- Klik tombol `` (biru) di footer untuk menambah event
- Isi judul event (wajib)
- Isi waktu (opsional): misal "14:00" atau "2 PM"
- Pilih warna dari 8 pilihan yang tersedia
- Klik "Simpan"

**Fitur:**
- Event ditampilkan sebagai dot berwarna di tanggal
- List event muncul di footer saat tanggal dipilih
- Hapus event dengan klik icon `󰆴` (merah)
- Data tersimpan di: `~/.config/quickshell/calendar-events.json`

---

### 2. 🎉 Hari Libur Nasional Indonesia
**Fitur:**
- Database lengkap 2024-2027
- Tanggal libur ditandai border peach/oranye
- Nama libur muncul di info tanggal (dengan icon `󰙳`)
- Termasuk: Tahun Baru, Lebaran, Natal, Kemerdekaan RI, dll

---

### 3. 📊 Week Numbers (ISO 8601)
**Fitur:**
- Kolom "W" di sebelah kiri menampilkan nomor minggu
- Minggu 1-52 dalam setahun
- Standar internasional ISO 8601

---

### 4. 🔍 Quick Jump (Navigasi Cepat)
**Cara Menggunakan:**
- **Klik nama bulan** (misal "Agustus") → muncul grid 12 bulan
- **Klik tahun** (misal "2026") → muncul list ±10 tahun
- Pilih bulan/tahun yang diinginkan

---

### 5. 📝 Catatan Harian
**Cara Menggunakan:**
- Klik tombol `󰷈` (kuning) di footer untuk tambah/edit catatan
- Tulis catatan di text area
- Klik "Simpan" atau "Batal"
- Untuk hapus: kosongkan text lalu klik "Hapus Catatan"

**Fitur:**
- Indikator icon `󰷈` kecil di tanggal yang ada catatan
- Preview 3 baris di footer
- Klik preview untuk edit
- Data tersimpan di: `~/.config/quickshell/calendar-notes.json`

---

### 6. 🌙 Kalender Hijriyah
**Fitur:**
- Konversi otomatis ke tanggal Hijriyah
- Ditampilkan di bawah tanggal Masehi (warna hijau)
- Format: "DD NamaBulan YYYY H"
- Contoh: "29 Muharram 1448 H"

---

### 7. 📈 Statistik Bulanan
**Cara Menggunakan:**
- Klik tombol `󰄶` di header (samping tombol next)
- Tampil/sembunyikan panel statistik

**Informasi yang ditampilkan:**
- 🔵 Total Hari dalam bulan
- 🟢 Hari Kerja (Senin-Jumat)
- 🔴 Weekend (Sabtu-Minggu)
- 🟠 Libur Nasional
- 🟣 Total Events yang dijadwalkan

---

## 🎨 Visual Indicators

| Simbol | Arti |
|--------|------|
| Border biru | Hari ini |
| Background biru solid | Hari yang dipilih + hari ini |
| Background abu | Hari yang dipilih |
| Border peach | Hari libur nasional |
| Background peach | Hari libur nasional |
| Dot berwarna | Ada event (warna sesuai pilihan) |
| Icon `󰷈` kecil | Ada catatan |
| Teks merah | Weekend (Sabtu & Minggu) |

---

## ⌨️ Navigasi

### Mouse:
- **Klik tanggal**: Pilih tanggal
- **Klik bulan**: Quick jump bulan
- **Klik tahun**: Quick jump tahun
- **Klik `󰍞`**: Bulan sebelumnya
- **Klik `󰍟`**: Bulan berikutnya
- **Klik `󰄶`**: Toggle statistik
- **Klik ``**: Tambah event
- **Klik `󰷈`**: Tambah/edit catatan
- **Klik "Hari ini"**: Kembali ke bulan/tanggal sekarang

### Visual Feedback:
- Hover → background abu terang
- Weekend → teks merah
- Libur → border + background peach
- Event → dot berwarna
- Note → icon kuning kecil

---

## 🔧 Konfigurasi

### Data Storage:
```
~/.config/quickshell/calendar-events.json  # Events
~/.config/quickshell/calendar-notes.json   # Notes
```

### Edit Libur Nasional:
Buka `services/CalendarService.qml` → function `loadHolidays()`

Format:
```javascript
"YYYY-MM-DD": "Nama Hari Libur"
```

---

## 💡 Tips

1. **Multi-Event per Hari**: Bisa tambah banyak event dalam 1 hari
2. **Color Coding**: Gunakan warna berbeda untuk kategori event (biru=meeting, merah=deadline, dll)
3. **Catatan Panjang**: Text area mendukung catatan panjang dengan scroll
4. **Backup Data**: File JSON bisa di-backup/restore manual
5. **Integrasi Todo**: Bisa dipanggil dari TodoWidget untuk set deadline

---

## 🐛 Troubleshooting

**Event tidak tersimpan?**
- Pastikan title tidak kosong
- Cek permission folder `~/.config/quickshell/`

**Hijriyah tidak akurat?**
- Algoritma menggunakan approximation, bukan database resmi
- Untuk keperluan resmi, gunakan kalender Hijriyah resmi

**Dialog tidak muncul?**
- Reload quickshell (restart)
- Cek log error di terminal

---

## 📚 Struktur File

```
panels/
├── CalendarPanel.qml      # Main panel (lengkap dengan semua fitur)
├── EventDialog.qml        # Dialog tambah event
└── NoteDialog.qml         # Dialog catatan harian

services/
└── CalendarService.qml    # Backend service (CRUD events/notes)
```

---

**Versi**: 2.0 (August 2026)  
**Fitur**: Event System, Notes, Hijri Calendar, Week Numbers, Quick Jump, Statistics, Indonesian Holidays
