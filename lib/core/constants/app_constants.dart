import 'package:flutter/material.dart';

class AppConstants {
  // --- API Constants ---
  static const String baseUrl = 'http://192.168.178.27/sewa_kos_api'; // Pastikan ini IP yang benar
  static const Duration apiTimeout = Duration(seconds: 20);

  // --- App Info Constants ---
  static const String appName = 'Sewa Kos';
  static const String appVersion = '1.0.0';
  static const String slogan = 'Temukan Kos Impianmu';

  // --- UI/Styling Constants ---
  static const Color primaryColor = Color(0xFF2196F3); // Blue
  static const Color accentColor = Color(0xFF00BCD4); // Cyan
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color textColorPrimary = Color(0xFF212121);
  static const Color textColorSecondary = Color(0xFF757575);
  
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultBorderRadius = 12.0;

  // --- Asset Paths ---
  static const String imageAssetLogo = 'assets/images/logo.png';
  static const String imageAssetPlaceholderKos = 'assets/images/placeholder_kos.png'; // Untuk MyKosScreen

  // --- Validation Constants ---
  static const int minPasswordLength = 6;
  static const String emailRegexPattern = r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+";

  // --- Message Constants (Opsional, jika tidak dari API) ---
  static const String loginFailedMessage = 'Login gagal. Cek kembali username/email dan password.';
  static const String registrationSuccessMessage = 'Registrasi berhasil! Silakan login.';
}