# 📅 CalendarPanel - Quick Reference

## ⌨️ Keyboard & Mouse Shortcuts

| Action | Method |
|--------|--------|
| **Tambah Event** | Klik `` (biru) di footer |
| **Tambah Note** | Klik `󰷈` (kuning) di footer |
| **Pilih Tanggal** | Klik angka tanggal |
| **Bulan Sebelumnya** | Klik `󰍞` di header |
| **Bulan Berikutnya** | Klik `󰍟` di header |
| **Quick Jump Bulan** | Klik nama bulan (misal "Agustus") |
| **Quick Jump Tahun** | Klik tahun (misal "2026") |
| **Lihat Statistik** | Klik `󰄶` di header |
| **Ke Hari Ini** | Klik tombol "Hari ini" |
| **Hapus Event** | Klik `󰆴` di samping event |
| **Edit Note** | Klik preview note di footer |
| **Tutup Panel** | Klik area luar panel |

---

## 🎨 Visual Indicators

| Tampilan | Arti |
|----------|------|
| 🔵 Border biru | Hari ini |
| 🔵 Background biru | Hari dipilih (hari ini) |
| ⚪ Background abu | Hari dipilih (bukan hari ini) |
| 🟠 Border peach | Hari libur nasional |
| 🔴 Teks merah | Weekend (Sabtu & Minggu) |
| ● Dot warna | Ada event (warna custom) |
| 󰷈 Icon kecil | Ada catatan |
| W32, W33... | Week number (ISO 8601) |

---

## 🎯 Color Picker (Event)

| Warna | Hex | Saran Penggunaan |
|-------|-----|------------------|
| 🔵 Biru | #89b4fa | Meeting, work |
| 🔴 Merah | #f38ba8 | Deadline, urgent |
| 🟢 Hijau | #a6e3a1 | Success, done |
| 🟠 Oranye | #fab387 | Warning, pending |
| 🟡 Kuning | #f9e2af | Important, note |
| 🟣 Ungu | #cba6f7 | Personal, fun |
| 🔵 Cyan | #89dceb | Info, reminder |
| 🩷 Pink | #f5c2e7 | Love, special |

---

## 📊 Statistik Info

Klik tombol `󰄶` untuk lihat:
- 🔵 **Total Hari**: Jumlah hari dalam bulan
- 🟢 **Hari Kerja**: Senin-Jumat (exclude libur)
- 🔴 **Weekend**: Sabtu & Minggu
- 🟠 **Libur Nasional**: Tanggal merah
- 🟣 **Events**: Total event dijadwalkan

---

## 📝 Dialog Controls

### Event Dialog:
- **Judul**: Wajib diisi
- **Waktu**: Opsional (format bebas)
- **Warna**: Pilih dari 8 warna
- **Simpan**: Hanya aktif jika judul terisi
- **Batal**: Tutup tanpa simpan

### Note Dialog:
- **Text Area**: Support multi-line
- **Auto-scroll**: Jika text panjang
- **Character Count**: Ditampilkan di header
- **Hapus**: Kosongkan text lalu klik "Hapus Catatan"

---

## 💡 Pro Tips

1. **Multi-Event**: Bisa tambah banyak event dalam 1 hari
2. **Color Code**: Gunakan warna konsisten (biru=work, merah=urgent)
3. **Quick Note**: Untuk catatan singkat, cukup tulis 1-2 baris
4. **Week Planning**: Gunakan week numbers untuk planning mingguan
5. **Holiday Check**: Lihat border peach untuk cek libur
6. **Hijri Date**: Berguna untuk event keagamaan Islam
7. **Stats Review**: Cek statistik untuk planning bulanan

---

## 🗂️ Data Files

```bash
# Backup data
cp ~/.config/quickshell/calendar-events.json ~/backup/
cp ~/.config/quickshell/calendar-notes.json ~/backup/

# Restore data
cp ~/backup/calendar-events.json ~/.config/quickshell/
cp ~/backup/calendar-notes.json ~/.config/quickshell/

# Reset semua
rm ~/.config/quickshell/calendar-*.json
```

---

## 🐛 Common Issues

**Q: Event tidak muncul setelah ditambah?**  
A: Pastikan klik "Simpan" dan judul tidak kosong

**Q: Dialog tidak bisa ditutup?**  
A: Klik tombol "Batal" atau area luar dialog

**Q: Tanggal Hijri tidak akurat?**  
A: Algoritma approximation, bukan resmi. Selisih ±1 hari normal.

**Q: Statistik tidak update?**  
A: Close/open panel atau klik bulan lain lalu kembali

**Q: Libur nasional kurang lengkap?**  
A: Edit `services/CalendarService.qml` → function `loadHolidays()`

---

## 🔗 Related Files

- `panels/CalendarPanel.qml` - Main panel
- `panels/EventDialog.qml` - Event dialog
- `panels/NoteDialog.qml` - Note dialog  
- `services/CalendarService.qml` - Backend service
- `docs/calendar-features.md` - Full documentation
- `CALENDAR_CHANGELOG.md` - Version history

---

## 📞 Support

Issues atau suggestions? Edit file QML langsung atau contact developer.

---

**Last Updated**: 10 Agustus 2026  
**Version**: 2.0
