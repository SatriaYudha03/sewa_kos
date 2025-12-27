/// Konfigurasi Supabase untuk aplikasi Sewa Kos
/// File ini berisi konstanta dan helper untuk mengakses Supabase client
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Kelas untuk menyimpan konfigurasi Supabase
class SupabaseConfig {
  // Private constructor untuk mencegah instansiasi
  SupabaseConfig._();

  /// URL Supabase project
  static const String supabaseUrl = 'https://kpomlpwjahijkkvkcsbz.supabase.co';

  /// Anon key Supabase (public key)
  static const String supabaseAnonKey =
      'sb_publishable_cIbpHhpHcBxwSInAVOLncw_kMCaRXqk';

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
  static const String buktiTransferBucket = 'bukti-transfer';
}
