/// PembayaranService - Layanan untuk mengelola pembayaran menggunakan Supabase
///
/// Mengelola upload bukti pembayaran dan verifikasi pembayaran

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../config/supabase_config.dart';
import '../models/pembayaran_model.dart';
import '../models/pemesanan_model.dart';
import 'auth_service.dart';

class PembayaranService {
  final AuthService _authService = AuthService();

  /// Upload bukti pembayaran
  Future<Map<String, dynamic>> uploadPaymentProof({
    required int pemesananId,
    required double jumlahBayar,
    required String metodePembayaran,
    required XFile buktiPembayaranFile,
    Uint8List? buktiPembayaranBytes,
    String? jenisPembayaran,
  }) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {
          'status': 'error',
          'message': 'Silakan login terlebih dahulu.',
        };
      }

      // Upload bukti transfer ke Storage
      final buktiTransferUrl = await _uploadBuktiTransfer(
        pemesananId: pemesananId,
        file: buktiPembayaranFile,
        bytes: buktiPembayaranBytes,
      );

      if (buktiTransferUrl == null) {
        return {
          'status': 'error',
          'message': 'Gagal mengupload bukti transfer.',
        };
      }

      // Insert data pembayaran
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.detailPembayaranTable)
          .insert({
            'pemesanan_id': pemesananId,
            'jumlah_bayar': jumlahBayar,
            'jenis_pembayaran': jenisPembayaran,
            'metode_pembayaran': metodePembayaran,
            'status_pembayaran':
                StatusPembayaran.menungguVerifikasi.toDbString(),
            'bukti_transfer_url': buktiTransferUrl,
          })
          .select()
          .single();

      return {
        'status': 'success',
        'message': 'Bukti pembayaran berhasil diupload. Menunggu verifikasi.',
        'data': Pembayaran.fromJson(response),
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal mengupload bukti pembayaran. Silakan coba lagi.',
      };
    }
  }

  /// Upload bukti transfer ke Supabase Storage
  Future<String?> _uploadBuktiTransfer({
    required int pemesananId,
    required XFile file,
    Uint8List? bytes,
  }) async {
    try {
      final fileName =
          'bukti_${pemesananId}_${DateTime.now().millisecondsSinceEpoch}.${file.name.split('.').last}';

      Uint8List fileBytes;
      if (bytes != null) {
        fileBytes = bytes;
      } else {
        fileBytes = await file.readAsBytes();
      }

      await SupabaseConfig.client.storage
          .from(SupabaseConfig.buktiTransferBucket)
          .uploadBinary(fileName, fileBytes);

      return SupabaseConfig.client.storage
          .from(SupabaseConfig.buktiTransferBucket)
          .getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  /// Verifikasi pembayaran (untuk pemilik kos)
  Future<Map<String, dynamic>> verifyPayment({
    required int pembayaranId,
    required StatusPembayaran status,
  }) async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        return {
          'status': 'error',
          'message': 'Silakan login terlebih dahulu.',
        };
      }

      if (!currentUser.isPemilikKos) {
        return {
          'status': 'error',
          'message': 'Hanya pemilik kos yang dapat memverifikasi pembayaran.',
        };
      }

      // Update status pembayaran
      await SupabaseConfig.client
          .from(SupabaseConfig.detailPembayaranTable)
          .update({
        'status_pembayaran': status.toDbString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', pembayaranId);

      // Jika terverifikasi, update status pemesanan
      if (status == StatusPembayaran.terverifikasi) {
        // Dapatkan pemesanan_id dari pembayaran
        final pembayaran = await SupabaseConfig.client
            .from(SupabaseConfig.detailPembayaranTable)
            .select('pemesanan_id')
            .eq('id', pembayaranId)
            .single();

        final pemesananId = pembayaran['pemesanan_id'] as int;

        // Update status pemesanan menjadi terkonfirmasi
        await SupabaseConfig.client.from(SupabaseConfig.pemesananTable).update({
          'status_pemesanan': StatusPemesanan.terkonfirmasi.toDbString(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', pemesananId);
      }

      return {
        'status': 'success',
        'message': 'Pembayaran berhasil diverifikasi.',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal memverifikasi pembayaran. Silakan coba lagi.',
      };
    }
  }

  /// Mengambil daftar pembayaran berdasarkan pemesanan ID
  Future<List<Pembayaran>> getPaymentsByPemesananId(int pemesananId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.detailPembayaranTable)
          .select()
          .eq('pemesanan_id', pemesananId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Pembayaran.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Mengambil pembayaran yang menunggu verifikasi (untuk pemilik kos)
  Future<List<Pembayaran>> getPendingPaymentsForOwner() async {
    try {
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null || !currentUser.isPemilikKos) {
        return [];
      }

      // Query pembayaran yang statusnya menunggu_verifikasi
      // dan pemesanannya berada di kamar milik kos user ini
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.detailPembayaranTable)
          .select('''
            *,
            pemesanan!inner(
              *,
              kamar_kos!inner(
                kos!inner(user_id)
              )
            )
          ''')
          .eq('status_pembayaran',
              StatusPembayaran.menungguVerifikasi.toDbString())
          .eq('pemesanan.kamar_kos.kos.user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Pembayaran.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Mengambil detail pembayaran berdasarkan ID
  Future<Pembayaran?> getPaymentDetail(int pembayaranId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.detailPembayaranTable)
          .select()
          .eq('id', pembayaranId)
          .single();

      return Pembayaran.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
