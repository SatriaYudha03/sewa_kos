// lib/core/services/kos_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_constants.dart'; // Import AppConstants
import '../models/kos_model.dart'; // Import KosModel
import '../models/kamar_kos_model.dart'; // Import KamarKosModel (jika nanti ada API terkait kamar)
import 'auth_service.dart'; // Import AuthService untuk mendapatkan header otorisasi

class KosService {
  final String _baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  // Method untuk MENAMBAH KOS BARU
  // Sesuaikan parameter dengan API PHP: api/kos/add.php
  Future<Map<String, dynamic>> addKos({
    required String namaKos,
    required String alamat,
    required String deskripsi,
    required String fotoUtama, // Ini bisa berupa URL atau base64 string jika Anda mengupload file
    required String fasilitasUmum, // Contoh: "WiFi, Parkir, Dapur Umum"
  }) async {
    final url = Uri.parse("$_baseUrl/kos/add.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.post(
        url,
        headers: headers, // Gunakan header otorisasi
        body: json.encode({
          'nama_kos': namaKos,
          'alamat': alamat,
          'deskripsi': deskripsi,
          'foto_utama': fotoUtama,
          'fasilitas_umum': fasilitasUmum,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message'], 'data': responseBody['data']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Failed to add kos.'};
      }
    } catch (e) {
      print('Error during addKos: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // Method untuk MENGAMBIL DAFTAR KOS
  // API: api/kos/list.php
  Future<List<Kos>> getListKos() async {
    final url = Uri.parse("$_baseUrl/kos/list.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi (jika diperlukan untuk list)

      final response = await http.get(
        url,
        headers: headers, // Kirim header otorisasi
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final List<dynamic> kosData = responseBody['data'];
        return kosData.map((json) => Kos.fromJson(json)).toList();
      } else {
        print('Error fetching kos list: ${responseBody['message']}');
        return []; // Kembalikan list kosong jika gagal
      }
    } catch (e) {
      print('Error during getListKos: $e');
      return [];
    }
  }

  // Method untuk MENGAMBIL DETAIL KOS berdasarkan ID
  // API: api/kos/detail.php?id={id_kos}
  Future<Kos?> getKosDetail(int kosId) async {
    final url = Uri.parse("$_baseUrl/kos/detail.php?id=$kosId");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.get(
        url,
        headers: headers, // Kirim header otorisasi
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return Kos.fromJson(responseBody['data']);
      } else {
        print('Error fetching kos detail: ${responseBody['message']}');
        return null; // Kembalikan null jika kos tidak ditemukan atau gagal
      }
    } catch (e) {
      print('Error during getKosDetail: $e');
      return null;
    }
  }

  // TODO: Tambahkan method untuk updateKos, deleteKos jika API-nya sudah ada
  // TODO: Tambahkan method untuk getKamarByKosId jika API-nya sudah ada (ini akan mengembalikan List<KamarKos>)
}