// lib/core/services/pemesanan_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_constants.dart'; // Import AppConstants
import '../models/pemesanan_model.dart'; // Import PemesananModel
import 'auth_service.dart'; // Import AuthService untuk mendapatkan header otorisasi

class PemesananService {
  final String _baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  // Method untuk MEMBUAT PEMESANAN BARU
  // API: api/pemesanan/add.php
  Future<Map<String, dynamic>> createPemesanan({
    required int kamarId,
    required DateTime tanggalMulai,
    required int durasiSewa, // Dalam bulan
  }) async {
    final url = Uri.parse("$_baseUrl/pemesanan/create.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.post(
        url,
        headers: headers, // Gunakan header otorisasi
        body: json.encode({
          'kamar_id': kamarId,
          'tanggal_mulai': tanggalMulai.toIso8601String().split('T')[0], // Format YYYY-MM-DD
          'durasi_sewa': durasiSewa,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message'], 'data': responseBody['data']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Failed to create booking.'};
      }
    } catch (e) {
      print('Error during createPemesanan: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // Method untuk MENGAMBIL DAFTAR PEMESANAN (untuk penyewa atau pemilik kos)
  // API: api/pemesanan/list.php
  Future<List<Pemesanan>> getListPemesanan() async {
    final url = Uri.parse("$_baseUrl/pemesanan/list.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.get(
        url,
        headers: headers, // Kirim header otorisasi
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final List<dynamic> pemesananData = responseBody['data'];
        return pemesananData.map((json) => Pemesanan.fromJson(json)).toList();
      } else {
        print('Error fetching pemesanan list: ${responseBody['message']}');
        return []; // Kembalikan list kosong jika gagal
      }
    } catch (e) {
      print('Error during getListPemesanan: $e');
      return [];
    }
  }

  // Method untuk MENGAMBIL DETAIL PEMESANAN berdasarkan ID
  // API: api/pemesanan/detail.php?id={id_pemesanan}
  Future<Pemesanan?> getPemesananDetail(int pemesananId) async {
    final url = Uri.parse("$_baseUrl/pemesanan/detail.php?id=$pemesananId");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.get(
        url,
        headers: headers, // Kirim header otorisasi
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return Pemesanan.fromJson(responseBody['data']);
      } else {
        print('Error fetching pemesanan detail: ${responseBody['message']}');
        return null; // Kembalikan null jika pemesanan tidak ditemukan atau gagal
      }
    } catch (e) {
      print('Error during getPemesananDetail: $e');
      return null;
    }
  }

  // Method untuk MENGUBAH STATUS PEMESANAN (misal: 'terkonfirmasi', 'dibatalkan')
  // API: api/pemesanan/update_status.php
  Future<Map<String, dynamic>> updatePemesananStatus({
    required int pemesananId,
    required String newStatus, // Contoh: 'terkonfirmasi', 'dibatalkan'
  }) async {
    final url = Uri.parse("$_baseUrl/pemesanan/update_status.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({
          'pemesanan_id': pemesananId,
          'status_pemesanan': newStatus,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Failed to update booking status.'};
      }
    } catch (e) {
      print('Error during updatePemesananStatus: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // TODO: Tambahkan method untuk deletePemesanan jika API-nya sudah ada
}