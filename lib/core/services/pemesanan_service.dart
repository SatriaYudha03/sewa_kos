/// PemesananService - Layanan untuk mengelola pemesanan kamar menggunakan Supabase
///
/// Mengelola CRUD dan status pemesanan kamar kos

import '../config/supabase_config.dart';
import '../models/pemesanan_model.dart';
import '../models/kamar_kos_model.dart';
import 'auth_service.dart';

class PemesananService {
  final AuthService _authService = AuthService();

  /// Membuat pemesanan baru
  Future<Map<String, dynamic>> createPemesanan({
    required int kamarId,
    required DateTime tanggalMulai,
    required int durasiSewa, // Dalam bulan
  }) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {'status': 'error', 'message': 'Silakan login terlebih dahulu.'};
      }

      // Dapatkan harga kamar
      final kamarResponse = await SupabaseConfig.client
          .from(SupabaseConfig.kamarKosTable)
          .select('harga_sewa, status')
          .eq('id', kamarId)
          .single();

      final hargaSewa = (kamarResponse['harga_sewa'] as num).toDouble();
      final statusKamar = kamarResponse['status'] as String;

      // Validasi status kamar
      if (statusKamar != 'tersedia') {
        return {
          'status': 'error',
          'message': 'Kamar tidak tersedia untuk disewa.',
        };
      }

      // Hitung total harga dan tanggal selesai
      final totalHarga = hargaSewa * durasiSewa;
      final tanggalSelesai = DateTime(
          tanggalMulai.year, tanggalMulai.month + durasiSewa, tanggalMulai.day);

      // Insert pemesanan
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.pemesananTable)
          .insert({
            'user_id': currentUser.id,
            'kamar_id': kamarId,
            'tanggal_mulai': tanggalMulai.toIso8601String().split('T')[0],
            'durasi_sewa': durasiSewa,
            'tanggal_selesai': tanggalSelesai.toIso8601String().split('T')[0],
            'total_harga': totalHarga,
            'status_pemesanan': StatusPemesanan.menungguPembayaran.toDbString(),
          })
          .select()
          .single();

      return {
        'status': 'success',
        'message': 'Pemesanan berhasil dibuat. Silakan lakukan pembayaran.',
        'data': Pemesanan.fromJson(response),
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal membuat pemesanan. Silakan coba lagi.',
      };
    }
  }

  /// Mengambil daftar pemesanan user (penyewa melihat pemesanannya)
  Future<List<Pemesanan>> getMyPemesanan() async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) return [];

      final response = await SupabaseConfig.client
          .from(SupabaseConfig.pemesananTable)
          .select('''
            *,
            users(username, nama_lengkap),
            kamar_kos(
              nama_kamar, 
              harga_sewa,
              kos(
                nama_kos, 
                alamat, 
                user_id,
                users(username, nama_lengkap)
              )
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Pemesanan.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Mengambil daftar pemesanan untuk pemilik kos (pemesanan masuk)
  Future<List<Pemesanan>> getIncomingPemesanan() async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) return [];

      // Query pemesanan yang kamarnya berada di kos milik user ini
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.pemesananTable)
          .select('''
            *,
            users(username, nama_lengkap),
            kamar_kos!inner(
              nama_kamar, 
              harga_sewa,
              kos!inner(
                nama_kos, 
                alamat, 
                user_id,
                users(username, nama_lengkap)
              )
            )
          ''')
          .eq('kamar_kos.kos.user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Pemesanan.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Mengambil detail pemesanan berdasarkan ID
  Future<Pemesanan?> getPemesananDetail(int pemesananId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.pemesananTable)
          .select('''
            *,
            users(username, nama_lengkap),
            kamar_kos(
              nama_kamar, 
              harga_sewa,
              kos(
                nama_kos, 
                alamat, 
                user_id,
                users(username, nama_lengkap)
              )
            )
          ''')
          .eq('id', pemesananId)
          .single();

      return Pemesanan.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Mengubah status pemesanan
  Future<Map<String, dynamic>> updatePemesananStatus({
    required int pemesananId,
    required StatusPemesanan newStatus,
  }) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {'status': 'error', 'message': 'Silakan login terlebih dahulu.'};
      }

      await SupabaseConfig.client.from(SupabaseConfig.pemesananTable).update({
        'status_pemesanan': newStatus.toDbString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pemesananId);

      // Jika status terkonfirmasi, update status kamar menjadi terisi
      if (newStatus == StatusPemesanan.terkonfirmasi) {
        final pemesanan = await getPemesananDetail(pemesananId);
        if (pemesanan != null) {
          await SupabaseConfig.client
              .from(SupabaseConfig.kamarKosTable)
              .update({'status': StatusKamar.terisi.toDbString()}).eq(
                  'id', pemesanan.kamarId);
        }
      }

      // Jika status dibatalkan atau selesai, update status kamar menjadi tersedia
      if (newStatus == StatusPemesanan.dibatalkan ||
          newStatus == StatusPemesanan.selesai) {
        final pemesanan = await getPemesananDetail(pemesananId);
        if (pemesanan != null) {
          await SupabaseConfig.client
              .from(SupabaseConfig.kamarKosTable)
              .update({'status': StatusKamar.tersedia.toDbString()}).eq(
                  'id', pemesanan.kamarId);
        }
      }

      return {
        'status': 'success',
        'message': 'Status pemesanan berhasil diperbarui.',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal memperbarui status pemesanan. Silakan coba lagi.',
      };
    }
  }

  /// Membatalkan pemesanan
  Future<Map<String, dynamic>> cancelPemesanan(int pemesananId) async {
    return updatePemesananStatus(
      pemesananId: pemesananId,
      newStatus: StatusPemesanan.dibatalkan,
    );
  }
}
