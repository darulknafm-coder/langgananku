# LanggananKu

Kendali penuh atas semua tagihan berulang Anda — aplikasi Flutter untuk **Android & iOS** (satu kode).

## Fitur yang sudah ada

**MVP**
- **Deteksi otomatis** — pindai SMS bank/e-wallet (Android) atau tempel teks email/nota/Apple receipt (Android & iOS). Diproses di HP, tidak dikirim ke server.
- **Dasbor total** — pengeluaran per bulan & per tahun, jumlah langganan aktif, per kategori.
- **Pengingat jatuh tempo** — notifikasi lokal H-3 dan H-1 (jam bisa diatur).
- **Peringatan kenaikan harga** — riwayat harga per langganan; bila nominal naik muncul peringatan + notifikasi.
- **Pembatalan sekali ketuk** — tombol membuka halaman pembatalan resmi layanan, lalu menandai nonaktif.
- **Tambah manual + katalog** 45 layanan populer Indonesia (Netflix, Vidio, Spotify, ChatGPT, Claude, Canva, IndiHome, dll.).

**Sebagian Fase 2 (tanpa server)**
- Simulasi "berapa hemat jika berhenti X selama N bulan".
- Saran hemat: langganan yang jarang dipakai, paket tahunan lebih murah.
- Deteksi duplikasi (mis. 2 chatbot AI, 3 VPN).
- Mode keluarga/patungan: biaya dibagi jumlah anggota.
- Ekspor/impor cadangan data.

Belum termasuk (butuh backend/akun): AI advisor berbasis LLM, sinkronisasi Supabase, mode keluarga multi-akun, widget home screen, pembayaran premium.

## Struktur

```
lib/
  main.dart                    → inisialisasi, tema, bahasa Indonesia
  models/subscription.dart     → model langganan, siklus tagih, riwayat harga
  data/catalog.dart            → katalog layanan + link pembatalan + kata kunci deteksi
  services/detector.dart       → parser SMS/email (nominal, tanggal, siklus)
  services/sms_scanner.dart    → baca SMS (Android)
  services/notification_service.dart → pengingat H-3/H-1
  services/repository.dart     → penyimpanan lokal + logika hemat
  screens/                     → Beranda, Langganan, Detail, Edit, Katalog, Pindai, Hemat, Setelan
tool/setup.dart                → konfigurasi izin Android/iOS otomatis
.github/workflows/android-release.yml → build AAB + APK rilis di GitHub
codemagic.yaml                 → build iOS di cloud → TestFlight
docs/                          → kebijakan privasi & halaman dukungan (GitHub Pages)
store/                         → teks listing toko, ikon 512, feature graphic
tool/buat-keystore.*           → membuat kunci upload Android
```

## Cara menjalankan (di komputer Anda)

1. Pasang Flutter: https://docs.flutter.dev/get-started/install (Windows/Mac/Linux) + Android Studio.
2. Buka terminal di folder proyek ini, lalu jalankan:

```bash
flutter create --org id.langgananku --project-name langgananku --platforms android,ios .
dart run tool/setup.dart
flutter pub get
dart run flutter_launcher_icons
flutter run            # HP Android tersambung via USB (USB debugging aktif)
```

3. Buat file APK untuk dibagikan/dipasang:

```bash
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

## Tanpa install Flutter: build APK lewat GitHub

1. Buat repository baru di GitHub, unggah seluruh isi folder ini.
2. Buka tab **Actions** → workflow **Android rilis (Play Store)** → *Run workflow* (± 10 menit).
3. Unduh **LanggananKu-android-N** di bagian *Artifacts*: `.aab` untuk Play Store, `.apk` untuk dicoba di HP.

Langkah lengkap rilis ke Play Store & App Store ada di dokumen *Panduan Rilis LanggananKu*.

## iPhone (iOS)

Build iOS **wajib** memakai Mac + Xcode (aturan Apple), atau layanan cloud seperti Codemagic:

```bash
flutter build ios --release
```

Untuk dipasang di iPhone orang lain atau dirilis ke App Store diperlukan akun Apple Developer (USD 99/tahun).
Catatan: iOS tidak mengizinkan aplikasi membaca SMS — di iPhone deteksi memakai fitur "tempel email/nota".

## Catatan rilis Play Store

- Izin `READ_SMS` dibatasi Google Play: aplikasi wajib mengisi *Permissions Declaration Form* dan biasanya hanya disetujui untuk aplikasi pengelola keuangan dengan alasan kuat. Alternatif aman: hapus izin SMS dan andalkan fitur tempel teks / notifikasi.
- Ganti `applicationId` dan buat keystore rilis sendiri sebelum upload ke Play Store.
- Harga di katalog adalah perkiraan; periksa ulang sebelum rilis.
