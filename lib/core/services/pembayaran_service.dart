// lib/core/services/pembayaran_service.dart (DIUPDATE)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/services/auth_service.dart';
import 'package:image_picker/image_picker.dart'; // Untuk XFile
import 'package:sewa_kos/core/models/user_model.dart'; // Import UserModel untuk getLoggedInUser
import 'package:sewa_kos/core/models/pembayaran_model.dart'; // Pastikan ini juga diimpor jika digunakan di metode lain di service ini

class PembayaranService {
  final String _baseUrl = AppConstants.baseUrl; // Menggunakan AppConstants.baseUrl
  final AuthService _authService = AuthService();

  // Metode untuk mengunggah bukti pembayaran
  Future<Map<String, dynamic>> uploadPaymentProof({
    required int pemesananId,
    required double jumlahBayar,
    required String metodePembayaran,
    required XFile buktiPembayaranFile, // Menggunakan XFile dari image_picker
  }) async {
    // --- PERBAIKAN DI SINI ---
    final User? currentUser = await _authService.getLoggedInUser(); // Dapatkan objek User yang login
    final Map<String, String> authHeaders = await _authService.getAuthHeaders(); // Dapatkan semua header otorisasi

    if (currentUser == null) { // Jika user tidak login
      return {'status': 'error', 'message': 'Autentikasi diperlukan. Silakan login kembali.'};
    }

    final uri = Uri.parse('$_baseUrl/pembayaran/upload_proof.php'); // URL lengkap ke endpoint PHP
    var request = http.MultipartRequest('POST', uri)
      // Tambahkan headers yang sudah didapat dari AuthService
      ..headers.addAll(authHeaders) // Menambahkan semua headers sekaligus
      // Tambahkan fields data
      ..fields['pemesanan_id'] = pemesananId.toString()
      ..fields['jumlah_bayar'] = jumlahBayar.toString()
      ..fields['metode_pembayaran'] = metodePembayaran;

    // Tambahkan file ke request
    // Pastikan field name 'bukti_pembayaran' sesuai dengan $_FILES di PHP
    request.files.add(
      await http.MultipartFile.fromPath(
        'bukti_pembayaran', // Nama field di PHP ($_FILES['bukti_pembayaran'])
        buktiPembayaranFile.path,
        filename: buktiPembayaranFile.name,
      ),
    );
    // --- AKHIR PERBAIKAN ---

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseBody = json.decode(response.body); // Dekode respons

        if (response.statusCode == 200) { // Cek status HTTP 200 OK
        return responseBody; // Kembalikan seluruh body respons
      } else {
        // Tangani error HTTP
        // errorBody sudah sama dengan responseBody
        return {'status': 'error', 'message': responseBody['message'] ?? 'Gagal mengunggah bukti pembayaran. Status: ${response.statusCode}'};
      }
    } catch (e) {
      // Tangani error koneksi atau lainnya
      print('Error during uploadPaymentProof: $e'); // Log error untuk debugging
      return {'status': 'error', 'message': 'Terjadi kesalahan koneksi: ${e.toString()}'};
    }
  }

  // Metode untuk VERIFIKASI PEMBAYARAN (hanya untuk pemilik_kos)
  // API PHP: api/pembayaran/verify.php
  Future<Map<String, dynamic>> verifyPayment({
    required int pembayaranId,
    required String statusPembayaran, // Misal: 'terverifikasi', 'ditolak'
  }) async {
    final url = Uri.parse("$_baseUrl/verify.php"); // Sesuaikan URL
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.put( // Menggunakan PUT method
        url,
        headers: headers,
        body: json.encode({
          'id': pembayaranId, // Mengirim ID sebagai 'id'
          'status': statusPembayaran, // Mengirim status sebagai 'status'
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Gagal memverifikasi pembayaran.'};
      }
    } catch (e) {
      print('Error during verifyPayment: $e');
      return {'status': 'error', 'message': 'Gagal terhubung ke server. Silakan coba lagi.'};
    }
  }


  // Method untuk MENGAMBIL DAFTAR PEMBAYARAN berdasarkan ID Pemesanan
  // API PHP: api/pembayaran/list_by_pemesanan.php?pemesanan_id={pemesanan_id}
  Future<List<Pembayaran>> getPaymentsByPemesananId(int pemesananId) async {
    final url = Uri.parse("$_baseUrl/list_by_pemesanan.php?pemesanan_id=$pemesananId");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.get(
        url,
        headers: headers,
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final List<dynamic> pembayaranData = responseBody['data'];
        return pembayaranData.map((json) => Pembayaran.fromJson(json)).toList();
      } else {
        print('Error fetching payments by pemesanan ID: ${responseBody['message']}');
        return [];
      }
    } catch (e) {
      print('Error during getPaymentsByPemesananId: $e');
      return [];
    }
  }
}