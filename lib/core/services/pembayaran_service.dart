// lib/core/services/pembayaran_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../app_constants.dart'; // Import AppConstants
import '../models/pembayaran_model.dart'; // Import PembayaranModel
import 'auth_service.dart'; // Import AuthService untuk mendapatkan header otorisasi

class PembayaranService {
  final String _baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  // Method untuk MENGUNGGAH BUKTI PEMBAYARAN
  // API PHP: api/pembayaran/upload_proof.php
  // Catatan: 'imagePath' diasumsikan adalah path file lokal atau base64 string
  // Jika Anda menggunakan file upload, Anda mungkin perlu menggunakan package 'http' multipart request.
  // Untuk kesederhanaan awal, kita asumsikan base64 string atau URL gambar yang sudah diupload.
  Future<Map<String, dynamic>> uploadPaymentProof({
    required int pemesananId,
    required String paymentMethod, // Misal: 'transfer_bank', 'ewallet'
    required String proofImageUrl, // URL gambar bukti pembayaran atau base64 string
  }) async {
    final url = Uri.parse("$_baseUrl/pembayaran/upload_proof.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.post(
        url,
        headers: headers, // Gunakan header otorisasi
        body: json.encode({
          'pemesanan_id': pemesananId,
          'metode_pembayaran': paymentMethod,
          'bukti_pembayaran_url': proofImageUrl,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message'], 'data': responseBody['data']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Failed to upload payment proof.'};
      }
    } catch (e) {
      print('Error during uploadPaymentProof: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // Method untuk VERIFIKASI PEMBAYARAN (hanya untuk pemilik_kos)
  // API PHP: api/pembayaran/verify.php
  Future<Map<String, dynamic>> verifyPayment({
    required int pembayaranId,
    required String statusPembayaran, // Misal: 'terverifikasi', 'ditolak'
  }) async {
    final url = Uri.parse("$_baseUrl/pembayaran/verify.php");
    
    try {
      final headers = await _authService.getAuthHeaders(); // Dapatkan header otorisasi

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'pembayaran_id': pembayaranId,
          'status_pembayaran': statusPembayaran,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message']};
      } else {
        return {'status': 'error', 'message': responseBody['message'] ?? 'Failed to verify payment.'};
      }
    } catch (e) {
      print('Error during verifyPayment: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // Method untuk MENGAMBIL DAFTAR PEMBAYARAN berdasarkan ID Pemesanan
  // API PHP: api/pembayaran/list_by_pemesanan.php?pemesanan_id={pemesanan_id}
  Future<List<Pembayaran>> getPaymentsByPemesananId(int pemesananId) async {
    final url = Uri.parse("$_baseUrl/pembayaran/list_by_pemesanan.php?pemesanan_id=$pemesananId");
    
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

  // TODO: Tambahkan method lain jika ada API pembayaran lain yang akan dibuat (misal: getPaymentDetail)
}