/// Konstanta aplikasi Sewa Kos
///
/// Berisi konstanta-konstanta yang digunakan di seluruh aplikasi
library;

import 'package:flutter/material.dart';

class AppConstants {
  // Private constructor untuk mencegah instansiasi
  AppConstants._();

  // --- App Info Constants ---
  static const String appName = 'Sewa Kos';
  static const String appVersion = '1.0.0';
  static const String slogan = 'Temukan Kos Impianmu';

  // --- UI/Styling Constants ---
  static const Color primaryColor = Color(0xFF2196F3); // Blue
  static const Color accentColor = Color(0xFF00BCD4); // Cyan
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color warningColor = Color(0xFF81D4FA); // Light Blue
  static const Color textColorPrimary = Color(0xFF212121);
  static const Color textColorSecondary = Color(0xFF757575);

  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // --- Asset Paths ---
  static const String imageAssetPath = 'assets/images/';
  static const String imageAssetLogo = '${imageAssetPath}logo.png';
  static const String imageAssetPlaceholderKos =
      '${imageAssetPath}placeholder_kos.png';
  static const String imageAssetPlaceholderKamar =
      '${imageAssetPath}placeholder_kamar.png';

  // --- Validation Constants ---
  static const int minPasswordLength = 6;
  static const int minUsernameLength = 3;
  static const String emailRegexPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegexPattern = r'^[0-9]{10,13}$';

  // --- Message Constants ---
  static const String loginFailedMessage =
      'Login gagal. Cek kembali username/email dan password.';
  static const String registrationSuccessMessage =
      'Registrasi berhasil! Silakan login.';
  static const String networkErrorMessage =
      'Gagal terhubung ke server. Periksa koneksi internet Anda.';
  static const String unknownErrorMessage =
      'Terjadi kesalahan. Silakan coba lagi.';

  // --- Pagination Constants ---
  static const int defaultPageSize = 20;

  // --- Duration Constants ---
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration apiTimeout = Duration(seconds: 30);
}
