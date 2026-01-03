# 🏠 Sewa Kos

**Temukan Kos Impianmu**

Aplikasi mobile untuk pencarian dan pengelolaan kos-kosan berbasis Flutter dengan backend Supabase.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=flat-square&logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-Private-red?style=flat-square)

## 📋 Deskripsi

Sewa Kos adalah aplikasi yang menghubungkan pemilik kos dengan pencari kos. Aplikasi ini memudahkan proses pencarian, pemesanan, dan pengelolaan properti kos-kosan dengan fitur lengkap untuk dua jenis pengguna: **Pemilik Kos (Owner)** dan **Pencari Kos (Tenant)**.

## 📱 Preview

### Login & Register

https://github.com/user-attachments/assets/8c33c1ca-de90-4b5c-ba4c-b7ff9bb82298

### Penyewa Kos

https://github.com/user-attachments/assets/fbf34f2b-f453-45ee-acd5-55bb31f74951

### Pemilik Kos

https://github.com/user-attachments/assets/716b22f6-2cec-4b8a-8d70-eb383d45327c

## ✨ Fitur Utama

### 🔐 Autentikasi

- Login & Register dengan email
- Manajemen sesi pengguna
- Role-based access (Owner/Tenant)

### 👤 Fitur Tenant (Pencari Kos)

- Melihat daftar kos yang tersedia
- Melihat detail kos dan kamar
- Melakukan pemesanan kamar
- Upload bukti pembayaran
- Melihat riwayat pemesanan

### 🏢 Fitur Owner (Pemilik Kos)

- Mengelola daftar kos milik sendiri
- Menambah/edit/hapus kos
- Mengelola kamar pada setiap kos
- Menerima/menolak pemesanan masuk
- Verifikasi pembayaran dari tenant

## 🛠️ Tech Stack

| Teknologi             | Kegunaan                                       |
| --------------------- | ---------------------------------------------- |
| **Flutter**           | Framework UI cross-platform                    |
| **Dart**              | Bahasa pemrograman                             |
| **Supabase**          | Backend-as-a-Service (Auth, Database, Storage) |

## 📁 Struktur Proyek

```
lib/
├── main.dart                    # Entry point aplikasi
├── core/
│   ├── config/                  # Konfigurasi (Supabase, dll)
│   ├── constants/               # Konstanta aplikasi (app_constants.dart)
│   ├── models/                  # Model data
│   │   ├── user_model.dart
│   │   ├── kos_model.dart
│   │   ├── kamar_kos_model.dart
│   │   ├── pemesanan_model.dart
│   │   ├── pembayaran_model.dart
│   │   └── role_model.dart
│   ├── services/                # Business logic & API calls
│   │   ├── auth_service.dart
│   │   ├── kos_service.dart
│   │   ├── kamar_service.dart
│   │   ├── pemesanan_service.dart
│   │   └── pembayaran_service.dart
│   └── utils/                   # Helper functions
├── features/
│   ├── auth/                    # Modul autentikasi
│   │   ├── providers/
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   ├── owner_dashboard/         # Dashboard pemilik kos
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── owner_home_screen.dart
│   │   │   ├── my_kos_screen.dart
│   │   │   ├── add_edit_kos_screen.dart
│   │   │   ├── kamar_management_screen.dart
│   │   │   ├── add_edit_kamar_screen.dart
│   │   │   ├── incoming_bookings_screen.dart
│   │   │   └── payment_verification_screen.dart
│   │   └── widgets/
│   ├── tenant_dashboard/        # Dashboard pencari kos
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── tenant_home_screen.dart
│   │   │   ├── kos_list_screen.dart
│   │   │   ├── kos_detail_screen.dart
│   │   │   ├── booking_history_screen.dart
│   │   │   └── upload_payment_proof_screen.dart
│   │   └── widgets/
│   └── shared_features/         # Fitur bersama
│       └── screens/
│           └── main_app_shell.dart
└── themes/                      # Tema aplikasi
```

## 🚀 Cara Menjalankan

### Prasyarat

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Akun Supabase (untuk backend)

### Langkah Instalasi

1. **Clone repository**

   ```bash
   git clone <repository-url>
   cd sewa_kos
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Setup Database Supabase**

   1. Buat project Supabase baru.
   2. Buka menu **SQL** → **SQL Editor**.
   3. Jalankan isi file [`database/schema.sql`](database/schema.sql) untuk membuat tabel utama.
   4. Pastikan Anda sudah membuat bucket storage:
      - `kos-images` (untuk gambar kos & kamar)
      - `bukti-pembayaran` (untuk bukti pembayaran)
   5. Jalankan isi file [`database/rls_policies.sql`](database/rls_policies.sql) untuk mengaktifkan RLS pada bucket tersebut.
   6. Sesuaikan kembali policy jika ingin pembatasan akses yang lebih ketat (misalnya hanya user tertentu yang bisa upload/delete).

4. **Konfigurasi Supabase di aplikasi**

   Buat file `lib/core/config/supabase_config.dart`:

   ```dart
   class SupabaseConfig {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

5. **Jalankan aplikasi**

   ```bash
   # Untuk development
   flutter run

   # Untuk build APK
   flutter build apk

   # Untuk build iOS
   flutter build ios
   ```

## 📄 Lisensi

Proyek ini bersifat **private** dan tidak dipublikasikan ke pub.dev.

---

<p align="center">
  <b>Sewa Kos</b> - Temukan Kos Impianmu 🏠
</p>
