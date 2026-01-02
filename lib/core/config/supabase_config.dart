/// Konfigurasi Supabase untuk aplikasi Sewa Kos
/// File ini berisi konstanta dan helper untuk mengakses Supabase client
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Kelas untuk menyimpan konfigurasi Supabase
class SupabaseConfig {
  // Private constructor untuk mencegah instansiasi
  SupabaseConfig._();

  /// URL Supabase project
  /// PENTING: Ganti dengan URL project Supabase Anda
  static const String supabaseUrl = 'https://kpomlpwjahijkkvkcsbz.supabase.co';

  /// Anon key Supabase (public key)
  /// PENTING: Ganti dengan anon key yang valid dari Supabase Dashboard
  /// Format yang benar: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx
  /// Dapatkan dari: Supabase Dashboard > Project Settings > API > Project API keys > anon public
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtwb21scHdqYWhpamtrdmtjc2J6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4NDk2MjYsImV4cCI6MjA4MjQyNTYyNn0.Lu5h0MOTz_D5KNHdeP2iUiW1UpOpN8DXj1QIOv4mdm0';

  /// Mendapatkan instance Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Nama-nama tabel di database
  static const String usersTable = 'users';
  static const String rolesTable = 'roles';
  static const String kosTable = 'kos';
  static const String kamarKosTable = 'kamar_kos';
  static const String pemesananTable = 'pemesanan';
  static const String detailPembayaranTable = 'detail_pembayaran';

  /// Nama-nama bucket storage
  static const String kosImagesBucket = 'kos-images';
  static const String kamarImagesBucket = 'kamar-images';
  static const String buktiTransferBucket = 'bukti-pembayaran';
}
