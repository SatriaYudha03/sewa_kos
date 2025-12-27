// lib/core/services/pembayaran_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/services/auth_service.dart';
import 'package:image_picker/image_picker.dart'; // Untuk XFile
import 'package:sewa_kos/core/models/user_model.dart'; // Import UserModel
import 'package:sewa_kos/core/models/pembayaran_model.dart'; // Pastikan ini juga diimpor
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk deteksi platform web
import 'dart:typed_data'; // Untuk Uint8List

class PembayaranService {
  final String _baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService();

  // Metode untuk mengunggah bukti pembayaran
  // Menerima XFile untuk path/nama file, dan Uint8List (opsional) untuk bytes gambar di web
  Future<Map<String, dynamic>> uploadPaymentProof({
    required int pemesananId,
    required double jumlahBayar,
    required String metodePembayaran,
    required XFile buktiPembayaranFile, // XFile tetap diperlukan untuk nama file dan path (di mobile/desktop)
    Uint8List? buktiPembayaranBytes, // Parameter opsional untuk bytes gambar (khususnya untuk web)
  }) async {
    final User? currentUser = await _authService.getLoggedInUser();
    final Map<String, String> authHeaders = await _authService.getAuthHeaders();

    if (currentUser == null) {
      return {'status': 'error', 'message': 'Autentikasi diperlukan. Silakan login kembali.'};
    }

    final uri = Uri.parse('$_baseUrl/pembayaran/upload_proof.php');
    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll(authHeaders)
      ..fields['pemesanan_id'] = pemesananId.toString()
      ..fields['jumlah_bayar'] = jumlahBayar.toString()
      ..fields['metode_pembayaran'] = metodePembayaran;

    // Menambahkan file bukti pembayaran berdasarkan platform
    if (kIsWeb) {
      // Untuk Flutter Web, gunakan bytes dari file
      if (buktiPembayaranBytes == null) {
        return {'status': 'error', 'message': 'Data gambar (bytes) tidak tersedia untuk upload web.'};
      }
      request.files.add(
        http.MultipartFile.fromBytes( // <-- Gunakan fromBytes untuk web
          'bukti_pembayaran', // Nama field di PHP
          buktiPembayaranBytes, // <-- Kirim bytes langsung
          filename: buktiPembayaranFile.name, // Nama file asli
        ),
      );
    } else {
      // Untuk platform non-web (Android, iOS, Desktop), gunakan path file
      request.files.add(
        await http.MultipartFile.fromPath( // <-- Gunakan fromPath untuk mobile/desktop
          'bukti_pembayaran', // Nama field di PHP
          buktiPembayaranFile.path,
          filename: buktiPembayaranFile.name, // Nama file asli
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Gagal mengunggah bukti pembayaran. Status: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error during uploadPaymentProof: $e');
      return {'status': 'error', 'message': 'Terjadi kesalahan koneksi: ${e.toString()}'};
    }
  }

  // Metode untuk memverifikasi pembayaran (digunakan oleh pemilik kos)
  Future<Map<String, dynamic>> verifyPayment({
    required int pembayaranId,
    required String status, // 'terverifikasi' atau 'gagal'
  }) async {
    final User? currentUser = await _authService.getLoggedInUser();
    final Map<String, String> authHeaders = await _authService.getAuthHeaders();

    if (currentUser == null) {
      return {'status': 'error', 'message': 'Autentikasi diperlukan. Silakan login kembali.'};
    }
    // --- PERBAIKAN DI SINI: currentUser.roleName ---
    if (currentUser.roleName != 'pemilik_kos') { // Menggunakan 'pemilik_kos' sesuai role_name di DB
      return {'status': 'error', 'message': 'Akses ditolak. Hanya pemilik kos yang dapat memverifikasi pembayaran.'};
    }

    // Perhatikan: endpoint PHP ini kita buat menerima PUT, bukan POST
    // Saya akan sesuaikan agar http.put() yang digunakan Flutter cocok dengan PHP
    final uri = Uri.parse('$_baseUrl/pembayaran/verify.php'); // URL ke endpoint verify.php
    try {
      final response = await http.put( // Menggunakan http.put()
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...authHeaders,
        },
        body: json.encode({
          'id': pembayaranId, // Mengirim ID pembayaran
          'status': status,   // Mengirim status verifikasi
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return responseBody;
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Gagal memverifikasi pembayaran.'};
      }
    } catch (e) {
      print('Error during verifyPayment: $e');
      return {'status': 'error', 'message': 'Terjadi kesalahan koneksi: ${e.toString()}'};
    }
  }

  // Metode untuk mendapatkan daftar pembayaran berdasarkan ID pemesanan
  Future<List<Pembayaran>> getPaymentsByPemesananId(int pemesananId) async {
    final User? currentUser = await _authService.getLoggedInUser();
    final Map<String, String> authHeaders = await _authService.getAuthHeaders();

    if (currentUser == null) {
      print('Error: User not logged in.');
      return [];
    }

    final uri = Uri.parse('$_baseUrl/pembayaran/list_by_pemesanan.php?pemesanan_id=$pemesananId');
    try {
      final response = await http.get(
        uri,
        headers: authHeaders,
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        List<dynamic> paymentData = responseBody['data'];
        return paymentData.map((json) => Pembayaran.fromJson(json)).toList();
      } else {
        print('Error fetching payments: ${responseBody['message']}');
        return [];
      }
    } catch (e) {
      print('Error during getPaymentsByPemesananId: $e');
      return [];
    }
  }

  // Metode untuk mendapatkan semua pembayaran yang menunggu verifikasi (untuk pemilik kos)
  // Catatan: Anda perlu membuat API PHP endpoint ini jika ingin menggunakannya
  // Misalnya: api/pembayaran/pending_payments.php
  Future<List<Pembayaran>> getPendingPaymentsForOwner() async {
    final User? currentUser = await _authService.getLoggedInUser();
    final Map<String, String> authHeaders = await _authService.getAuthHeaders();

    if (currentUser == null) {
      print('Error: User not logged in.');
      return [];
    }
    // --- PERBAIKAN DI SINI: currentUser.roleName ---
    if (currentUser.roleName != 'pemilik_kos') { // Menggunakan 'pemilik_kos' sesuai role_name di DB
      print('Error: User is not an owner.');
      return [];
    }

    // Endpoint ini perlu dibuat di PHP jika ingin digunakan
    // Contoh: '$_baseUrl/pembayaran/pending_payments.php'
    final uri = Uri.parse('$_baseUrl/pembayaran/pending_payments.php'); // <-- Pastikan endpoint ini ada di PHP
    try {
      final response = await http.get(
        uri,
        headers: authHeaders,
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        List<dynamic> paymentData = responseBody['data'];
        return paymentData.map((json) => Pembayaran.fromJson(json)).toList();
      } else {
        print('Error fetching pending payments: ${responseBody['message']}');
        return [];
      }
    } catch (e) {
      print('Error during getPendingPaymentsForOwner: $e');
      return [];
    }
  }
}