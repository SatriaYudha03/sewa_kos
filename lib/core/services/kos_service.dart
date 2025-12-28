/// KosService - Layanan untuk mengelola data kos menggunakan Supabase
///
/// Mengelola CRUD untuk data kos (properti kos)
library;

import 'dart:convert';
import 'dart:typed_data';

import '../config/supabase_config.dart';
import '../models/kos_model.dart';
import 'auth_service.dart';

class KosService {
  final AuthService _authService = AuthService();

  /// Menambah kos baru
  /// [fotoUtama] - base64 encoded string of image
  Future<Map<String, dynamic>> addKos({
    required String namaKos,
    required String alamat,
    String? deskripsi,
    String? fasilitasUmum,
    String? fotoUtama, // base64 string
  }) async {
    try {
      print('=== KosService.addKos START ===');
      print('namaKos: $namaKos');
      print('alamat: $alamat');
      print('deskripsi: $deskripsi');
      print('fasilitasUmum: $fasilitasUmum');
      print('fotoUtama provided: ${fotoUtama != null}');
      print('fotoUtama length: ${fotoUtama?.length ?? 0}');

      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        print('ERROR: No logged in user');
        return {'status': 'error', 'message': 'Silakan login terlebih dahulu.'};
      }

      print('Current user ID: ${currentUser.id}');

      String? fotoUtamaUrl;

      // Upload foto jika ada
      if (fotoUtama != null && fotoUtama.isNotEmpty) {
        print('Uploading image to Supabase Storage...');
        fotoUtamaUrl = await _uploadKosImageFromBase64(
          userId: currentUser.id,
          base64Image: fotoUtama,
        );
        print('Upload result - fotoUtamaUrl: $fotoUtamaUrl');
      } else {
        print('No image to upload');
      }

      // Insert data kos
      final insertData = {
        'user_id': currentUser.id,
        'nama_kos': namaKos,
        'alamat': alamat,
        'deskripsi': deskripsi,
        'foto_utama_url': fotoUtamaUrl,
        'fasilitas_umum': fasilitasUmum,
      };

      print('Inserting to Supabase with data:');
      print(insertData);

      final response = await SupabaseConfig.client
          .from(SupabaseConfig.kosTable)
          .insert(insertData)
          .select()
          .single();

      print('Insert successful! Response:');
      print(response);

      return {
        'status': 'success',
        'message': 'Kos berhasil ditambahkan.',
        'data': Kos.fromJson(response),
      };
    } catch (e) {
      print('=== ERROR in KosService.addKos ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      return {
        'status': 'error',
        'message': 'Gagal menambahkan kos. Silakan coba lagi. Error: $e',
      };
    }
  }

  /// Upload gambar kos ke Supabase Storage dari base64 string
  Future<String?> _uploadKosImageFromBase64({
    required int userId,
    required String base64Image,
  }) async {
    try {
      print('=== _uploadKosImageFromBase64 START ===');
      final fileName =
          'kos_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Generated filename: $fileName');
      print('Base64 image length: ${base64Image.length}');

      final Uint8List fileBytes = base64Decode(base64Image);
      print('Decoded bytes length: ${fileBytes.length}');

      print('Uploading to bucket: ${SupabaseConfig.kosImagesBucket}');
      await SupabaseConfig.client.storage
          .from(SupabaseConfig.kosImagesBucket)
          .uploadBinary(fileName, fileBytes);

      final publicUrl = SupabaseConfig.client.storage
          .from(SupabaseConfig.kosImagesBucket)
          .getPublicUrl(fileName);

      print('Upload successful! Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('=== ERROR in _uploadKosImageFromBase64 ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      return null;
    }
  }

  /// Mengambil semua daftar kos
  Future<List<Kos>> getListKos() async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.kosTable)
          .select('*, users(username, nama_lengkap)')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Kos.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Mengambil daftar kos milik user tertentu (pemilik kos)
  Future<List<Kos>> getMyKosList() async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) return [];

      final response = await SupabaseConfig.client
          .from(SupabaseConfig.kosTable)
          .select('*, users(username, nama_lengkap)')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Kos.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Mengambil detail kos berdasarkan ID
  Future<Kos?> getKosDetail(int kosId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.kosTable)
          .select('*, users(username, nama_lengkap)')
          .eq('id', kosId)
          .single();

      return Kos.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Memperbarui data kos
  /// [fotoUtama] - base64 encoded string of new image
  Future<Map<String, dynamic>> updateKos({
    required int id,
    String? namaKos,
    String? alamat,
    String? deskripsi,
    String? fasilitasUmum,
    String? fotoUtama, // base64 string
  }) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {'status': 'error', 'message': 'Silakan login terlebih dahulu.'};
      }

      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (namaKos != null) updateData['nama_kos'] = namaKos;
      if (alamat != null) updateData['alamat'] = alamat;
      if (deskripsi != null) updateData['deskripsi'] = deskripsi;
      if (fasilitasUmum != null) updateData['fasilitas_umum'] = fasilitasUmum;

      // Upload foto baru jika ada
      if (fotoUtama != null && fotoUtama.isNotEmpty) {
        final fotoUrl = await _uploadKosImageFromBase64(
          userId: currentUser.id,
          base64Image: fotoUtama,
        );
        if (fotoUrl != null) {
          updateData['foto_utama_url'] = fotoUrl;
        }
      }

      await SupabaseConfig.client
          .from(SupabaseConfig.kosTable)
          .update(updateData)
          .eq('id', id)
          .eq('user_id', currentUser.id);

      return {
        'status': 'success',
        'message': 'Kos berhasil diperbarui.',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal memperbarui kos. Silakan coba lagi.',
      };
    }
  }

  /// Menghapus kos
  Future<Map<String, dynamic>> deleteKos(int kosId) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {'status': 'error', 'message': 'Silakan login terlebih dahulu.'};
      }

      await SupabaseConfig.client
          .from(SupabaseConfig.kosTable)
          .delete()
          .eq('id', kosId)
          .eq('user_id', currentUser.id);

      return {
        'status': 'success',
        'message': 'Kos berhasil dihapus.',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal menghapus kos. Silakan coba lagi.',
      };
    }
  }

  /// Mencari kos berdasarkan keyword dan filter
  Future<List<Kos>> searchKos({
    String? keyword,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      var query = SupabaseConfig.client
          .from(SupabaseConfig.kosTable)
          .select('*, users(username, nama_lengkap)');

      // Filter berdasarkan keyword
      if (keyword != null && keyword.isNotEmpty) {
        query = query.or('nama_kos.ilike.%$keyword%,alamat.ilike.%$keyword%');
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) => Kos.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
