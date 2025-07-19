// lib/core/services/kos_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sewa_kos/core/constants/app_constants.dart'; // Sesuaikan import AppConstants
import 'package:sewa_kos/core/models/kos_model.dart'; // Import KosModel
import 'package:sewa_kos/core/models/kamar_kos_model.dart'; // Import KamarKosModel
import 'package:sewa_kos/core/services/auth_service.dart'; // Import AuthService

class KosService {
  final String _baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  // Method untuk MENAMBAH KOS BARU
  // API PHP: api/kos/add.php
  Future<Map<String, dynamic>> addKos({
    required String namaKos,
    required String alamat,
    String? deskripsi, // Nullable sesuai model dan API
    String? fotoUtama, // Nullable sesuai model dan API
    String? fasilitasUmum, // Nullable sesuai model dan API
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
        return {'status': 'error', 'message': responseBody['message'] ?? 'Gagal menambah kos.'};
      }
    } catch (e) {
      print('Error during addKos: $e');
      return {'status': 'error', 'message': 'Gagal terhubung ke server. Silakan coba lagi.'};
    }
  }

  // Method untuk MENGAMBIL DAFTAR KOS
  // API: api/kos/list.php
  Future<List<Kos>> getListKos() async {
    final url = Uri.parse("$_baseUrl/kos/list.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

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
        // Kembalikan list kosong jika gagal, agar aplikasi tidak crash
        return []; 
      }
    } catch (e) {
      print('Error during getListKos: $e');
      // Tangani error jaringan
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
        return null; 
      }
    } catch (e) {
      print('Error during getKosDetail: $e');
      return null;
    }
  }

  // Method untuk MEMPERBARUI DATA KOS
  // API PHP: api/kos/update.php (menggunakan method PUT)
  Future<Map<String, dynamic>> updateKos({
    required int id,
    String? namaKos,
    String? alamat,
    String? deskripsi,
    String? fotoUtama,
    String? fasilitasUmum,
  }) async {
    final url = Uri.parse("$_baseUrl/kos/update.php");
    
    // Siapkan body secara dinamis agar hanya mengirim field yang tidak null
    final Map<String, dynamic> bodyData = {
      'id': id, // ID Kos wajib dikirim untuk update
    };
    if (namaKos != null) bodyData['nama_kos'] = namaKos;
    if (alamat != null) bodyData['alamat'] = alamat;
    if (deskripsi != null) bodyData['deskripsi'] = deskripsi;
    if (fotoUtama != null) bodyData['foto_utama'] = fotoUtama;
    if (fasilitasUmum != null) bodyData['fasilitas_umum'] = fasilitasUmum;

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
        return {'status': 'error', 'message': responseBody['message'] ?? 'Gagal memperbarui kos.'};
      }
    } catch (e) {
      print('Error during updateKos: $e');
      return {'status': 'error', 'message': 'Gagal terhubung ke server. Silakan coba lagi.'};
    }
  }

  // Method untuk MENGHAPUS KOS
  // API PHP: api/kos/delete.php (menggunakan method DELETE)
  Future<Map<String, dynamic>> deleteKos(int kosId) async {
    final url = Uri.parse("$_baseUrl/kos/delete.php"); // API delete kita menggunakan body, bukan ID di URL
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.delete( // Menggunakan DELETE method
        url,
        headers: headers,
        body: json.encode({'id': kosId}), // Kirim ID di body
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Gagal menghapus kos.'};
      }
    } catch (e) {
      print('Error during deleteKos: $e');
      return {'status': 'error', 'message': 'Gagal terhubung ke server. Silakan coba lagi.'};
    }
  }

// API PHP: api/kos/search.php
  Future<List<Kos>> searchKos({
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? fasilitas, // Fasilitas kamar, dipisahkan koma (misal: "AC,KM Dalam")
  }) async {
    // Bangun URL dengan query parameters
    final Map<String, String> queryParams = {};
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    if (minPrice != null) {
      queryParams['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['max_price'] = maxPrice.toString();
    }
    if (fasilitas != null && fasilitas.isNotEmpty) {
      queryParams['fasilitas'] = fasilitas;
    }

    final uri = Uri.parse("$_baseUrl/kos/search.php").replace(queryParameters: queryParams);
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi (diperlukan)

      final response = await http.get(
        uri,
        headers: headers,
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final List<dynamic> kosData = responseBody['data'];
        return kosData.map((json) => Kos.fromJson(json)).toList();
      } else {
        print('Error searching kos: ${responseBody['message']}');
        return [];
      }
    } catch (e) {
      print('Error during searchKos: $e');
      return [];
    }
  }
  // TODO: Tambahkan method untuk getKamarByKosId jika API-nya sudah ada (ini akan mengembalikan List<KamarKos>)
}