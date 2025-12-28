/// KamarService - Layanan untuk mengelola data kamar kos menggunakan Supabase
///
/// Mengelola CRUD untuk kamar dalam setiap kos
library;

import 'dart:convert';
import 'dart:typed_data';

import '../config/supabase_config.dart';
import '../models/kamar_kos_model.dart';
import 'auth_service.dart';

class KamarService {
  final AuthService _authService = AuthService();

  /// Menambah kamar baru ke kos
  /// [fotoKamar] - base64 encoded string of image (optional)
  Future<Map<String, dynamic>> addKamar({
    required int kosId,
    required String namaKamar,
    required double hargaSewa,
    String? luasKamar,
    String? fasilitas,
    String? fotoKamar, // base64 string
  }) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {'status': 'error', 'message': 'Silakan login terlebih dahulu.'};
      }

      String? fotoKamarUrl;

      // Upload foto jika ada
      if (fotoKamar != null && fotoKamar.isNotEmpty) {
        fotoKamarUrl = await _uploadKamarImageFromBase64(
          kosId: kosId,
          base64Image: fotoKamar,
        );
      }

      // Insert data kamar
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.kamarKosTable)
          .insert({
            'kos_id': kosId,
            'nama_kamar': namaKamar,
            'harga_sewa': hargaSewa,
            'luas_kamar': luasKamar,
            'fasilitas': fasilitas,
            'status': StatusKamar.tersedia.toDbString(),
            'foto_kamar_url': fotoKamarUrl,
          })
          .select()
          .single();

      return {
        'status': 'success',
        'message': 'Kamar berhasil ditambahkan.',
        'data': KamarKos.fromJson(response),
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal menambahkan kamar. Silakan coba lagi.',
      };
    }
  }

  /// Upload gambar kamar ke Supabase Storage dari base64 string
  Future<String?> _uploadKamarImageFromBase64({
    required int kosId,
    required String base64Image,
  }) async {
    try {
      final fileName =
          'kamar_${kosId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Uint8List fileBytes = base64Decode(base64Image);

      await SupabaseConfig.client.storage
          .from(SupabaseConfig.kamarImagesBucket)
          .uploadBinary(fileName, fileBytes);

      return SupabaseConfig.client.storage
          .from(SupabaseConfig.kamarImagesBucket)
          .getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  /// Mengambil daftar kamar berdasarkan kos ID
  Future<List<KamarKos>> getKamarByKosId(int kosId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.kamarKosTable)
          .select('*, kos(nama_kos, alamat)')
          .eq('kos_id', kosId)
          .order('nama_kamar', ascending: true);

      return (response as List).map((json) => KamarKos.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Mengambil detail kamar berdasarkan ID
  Future<KamarKos?> getKamarDetail(int kamarId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.kamarKosTable)
          .select('*, kos(nama_kos, alamat)')
          .eq('id', kamarId)
          .single();

      return KamarKos.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Memperbarui data kamar
  /// [status] - StatusKamar enum (tersedia, terisi, perbaikan)
  /// [fotoKamar] - base64 encoded string of new image (optional)
  Future<Map<String, dynamic>> updateKamar({
    required int kamarId,
    String? namaKamar,
    double? hargaSewa,
    String? luasKamar,
    String? fasilitas,
    StatusKamar? status,
    String? fotoKamar, // base64 string
  }) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {'status': 'error', 'message': 'Silakan login terlebih dahulu.'};
      }

      // Dapatkan kos_id untuk keperluan upload
      final existingKamar = await getKamarDetail(kamarId);
      if (existingKamar == null) {
        return {'status': 'error', 'message': 'Kamar tidak ditemukan.'};
      }

      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (namaKamar != null) updateData['nama_kamar'] = namaKamar;
      if (hargaSewa != null) updateData['harga_sewa'] = hargaSewa;
      if (luasKamar != null) updateData['luas_kamar'] = luasKamar;
      if (fasilitas != null) updateData['fasilitas'] = fasilitas;
      if (status != null) updateData['status'] = status.toDbString();

      // Upload foto baru jika ada
      if (fotoKamar != null && fotoKamar.isNotEmpty) {
        final fotoUrl = await _uploadKamarImageFromBase64(
          kosId: existingKamar.kosId,
          base64Image: fotoKamar,
        );
        if (fotoUrl != null) {
          updateData['foto_kamar_url'] = fotoUrl;
        }
      }

      await SupabaseConfig.client
          .from(SupabaseConfig.kamarKosTable)
          .update(updateData)
          .eq('id', kamarId);

      return {
        'status': 'success',
        'message': 'Kamar berhasil diperbarui.',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal memperbarui kamar. Silakan coba lagi.',
      };
    }
  }

  /// Menghapus kamar
  Future<Map<String, dynamic>> deleteKamar(int kamarId) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {'status': 'error', 'message': 'Silakan login terlebih dahulu.'};
      }

      await SupabaseConfig.client
          .from(SupabaseConfig.kamarKosTable)
          .delete()
          .eq('id', kamarId);

      return {
        'status': 'success',
        'message': 'Kamar berhasil dihapus.',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal menghapus kamar. Silakan coba lagi.',
      };
    }
  }

  /// Mengambil kamar yang tersedia di semua kos (untuk penyewa mencari kamar)
  Future<List<KamarKos>> getAvailableKamar({
    String? keyword,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      var query = SupabaseConfig.client
          .from(SupabaseConfig.kamarKosTable)
          .select('*, kos(nama_kos, alamat, users(username, nama_lengkap))')
          .eq('status', StatusKamar.tersedia.toDbString());

      // Filter harga
      if (minPrice != null) {
        query = query.gte('harga_sewa', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('harga_sewa', maxPrice);
      }

      final response = await query.order('harga_sewa', ascending: true);

      return (response as List).map((json) => KamarKos.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
