// lib/core/services/kamar_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_constants.dart'; // Import AppConstants
import '../models/kamar_kos_model.dart'; // Import KamarKosModel
import 'auth_service.dart'; // Import AuthService untuk mendapatkan header otorisasi

class KamarService {
  final String _baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  // Method untuk MENAMBAH KAMAR BARU ke dalam suatu Kos
  // API PHP: api/kamar/add.php
  Future<Map<String, dynamic>> addKamar({
    required int kosId,
    required String namaKamar,
    required double hargaSewa,
    String? luasKamar,
    String? fasilitas, // Contoh: "AC, Kamar Mandi Dalam"
  }) async {
    final url = Uri.parse("$_baseUrl/kamar/add.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.post(
        url,
        headers: headers, // Gunakan header otorisasi
        body: json.encode({
          'kos_id': kosId,
          'nama_kamar': namaKamar,
          'harga_sewa': hargaSewa, // Kirim sebagai double, PHP akan parse
          'luas_kamar': luasKamar,
          'fasilitas': fasilitas,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message'], 'data': responseBody['data']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Failed to add room.'};
      }
    } catch (e) {
      print('Error during addKamar: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // Method untuk MENGAMBIL DAFTAR KAMAR untuk Kos tertentu
  // API PHP: api/kamar/list_by_kos.php?kos_id={kos_id}
  Future<List<KamarKos>> getKamarByKosId(int kosId) async {
    final url = Uri.parse("$_baseUrl/kamar/list_by_kos.php?kos_id=$kosId");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.get(
        url,
        headers: headers, // Kirim header otorisasi
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final List<dynamic> kamarData = responseBody['data'];
        return kamarData.map((json) => KamarKos.fromJson(json)).toList();
      } else {
        print('Error fetching kamar list: ${responseBody['message']}');
        return [];
      }
    } catch (e) {
      print('Error during getKamarByKosId: $e');
      return [];
    }
  }

  // Method untuk MENGAMBIL DETAIL KAMAR berdasarkan ID Kamar
  // API PHP: api/kamar/detail.php?id={id_kamar}
  Future<KamarKos?> getKamarDetail(int kamarId) async {
    final url = Uri.parse("$_baseUrl/kamar/detail.php?id=$kamarId");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.get(
        url,
        headers: headers, // Kirim header otorisasi
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return KamarKos.fromJson(responseBody['data']);
      } else {
        print('Error fetching kamar detail: ${responseBody['message']}');
        return null;
      }
    } catch (e) {
      print('Error during getKamarDetail: $e');
      return null;
    }
  }

  // Method untuk MEMPERBARUI DATA KAMAR
  // API PHP: api/kamar/update.php
  Future<Map<String, dynamic>> updateKamar({
    required int kamarId,
    String? namaKamar,
    double? hargaSewa,
    String? luasKamar,
    String? fasilitas,
    String? status, // Misal: 'tersedia', 'terisi', 'perbaikan'
  }) async {
    final url = Uri.parse("$_baseUrl/kamar/update.php");
    
    // Siapkan body secara dinamis agar hanya mengirim field yang tidak null
    final Map<String, dynamic> bodyData = {
      'id': kamarId, // ID kamar wajib
    };
    if (namaKamar != null) bodyData['nama_kamar'] = namaKamar;
    if (hargaSewa != null) bodyData['harga_sewa'] = hargaSewa;
    if (luasKamar != null) bodyData['luas_kamar'] = luasKamar;
    if (fasilitas != null) bodyData['fasilitas'] = fasilitas;
    if (status != null) bodyData['status'] = status;

    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.put( // Menggunakan PUT method
        url,
        headers: headers,
        body: json.encode(bodyData),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Failed to update room.'};
      }
    } catch (e) {
      print('Error during updateKamar: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // Method untuk MENGHAPUS KAMAR
  // API PHP: api/kamar/delete.php
  Future<Map<String, dynamic>> deleteKamar(int kamarId) async {
    final url = Uri.parse("$_baseUrl/kamar/delete.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.delete( // Menggunakan DELETE method
        url,
        headers: headers,
        body: json.encode({'id': kamarId}), // Kirim ID di body untuk DELETE
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Failed to delete room.'};
      }
    } catch (e) {
      print('Error during deleteKamar: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }
}