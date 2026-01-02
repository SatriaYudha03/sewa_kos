/// PembayaranService - Layanan untuk mengelola pembayaran menggunakan Supabase
///
/// Mengelola upload bukti pembayaran dan verifikasi pembayaran
library;

import 'dart:developer' as developer;
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
      developer.log('\n🔧 [PembayaranService] uploadPaymentProof dipanggil',
          name: 'PembayaranService');
      developer.log('   Pemesanan ID: $pemesananId', name: 'PembayaranService');
      developer.log('   Jumlah Bayar: Rp ${jumlahBayar.toStringAsFixed(0)}',
          name: 'PembayaranService');
      developer.log('   Metode: $metodePembayaran', name: 'PembayaranService');
      developer.log('   Jenis: ${jenisPembayaran ?? "null"}',
          name: 'PembayaranService');
      developer.log('   File: ${buktiPembayaranFile.name}',
          name: 'PembayaranService');
      developer.log('   Bytes tersedia: ${buktiPembayaranBytes != null}',
          name: 'PembayaranService');

      // Cek autentikasi
      developer.log('\n🔐 Memeriksa autentikasi user...',
          name: 'PembayaranService');
      final currentUser = await _authService.getLoggedInUser();
      if (currentUser == null) {
        developer.log('❌ User tidak terautentikasi', name: 'PembayaranService');
        return {
          'status': 'error',
          'message': 'Silakan login terlebih dahulu.',
        };
      }
      developer.log('✅ User terautentikasi: ${currentUser.username}',
          name: 'PembayaranService');

      // Upload bukti transfer ke Storage
      developer.log('\n📤 Memulai upload bukti transfer ke Storage...',
          name: 'PembayaranService');
      final buktiTransferUrl = await _uploadBuktiTransfer(
        pemesananId: pemesananId,
        file: buktiPembayaranFile,
        bytes: buktiPembayaranBytes,
      );

      if (buktiTransferUrl == null) {
        developer.log('❌ Upload bukti transfer gagal (URL null)',
            name: 'PembayaranService');
        return {
          'status': 'error',
          'message': 'Gagal mengupload bukti transfer.',
        };
      }
      developer.log('✅ Bukti transfer berhasil diupload',
          name: 'PembayaranService');
      developer.log('   URL: $buktiTransferUrl', name: 'PembayaranService');

      // Insert data pembayaran
      developer.log('\n💾 Menyimpan data pembayaran ke database...',
          name: 'PembayaranService');
      final dataToInsert = {
        'pemesanan_id': pemesananId,
        'jumlah_bayar': jumlahBayar,
        'jenis_pembayaran': jenisPembayaran,
        'metode_pembayaran': metodePembayaran,
        'status_pembayaran': StatusPembayaran.menungguVerifikasi.toDbString(),
        'bukti_transfer_url': buktiTransferUrl,
      };
      developer.log('   Data yang akan diinsert: $dataToInsert',
          name: 'PembayaranService');

      final response = await SupabaseConfig.client
          .from(SupabaseConfig.detailPembayaranTable)
          .insert(dataToInsert)
          .select()
          .single();

      developer.log('✅ Data pembayaran berhasil disimpan',
          name: 'PembayaranService');
      developer.log('   Response: $response', name: 'PembayaranService');

      return {
        'status': 'success',
        'message': 'Bukti pembayaran berhasil diupload. Menunggu verifikasi.',
        'data': Pembayaran.fromJson(response),
      };
    } catch (e, stackTrace) {
      developer.log(
        '❌ EXCEPTION di uploadPaymentProof',
        name: 'PembayaranService',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'status': 'error',
        'message': 'Gagal mengupload bukti pembayaran: ${e.toString()}',
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
      developer.log('\n📁 [Storage] Menyiapkan upload file',
          name: 'PembayaranService');
      developer.log('   Nama file: $fileName', name: 'PembayaranService');
      developer.log('   Bucket: ${SupabaseConfig.buktiTransferBucket}',
          name: 'PembayaranService');

      Uint8List fileBytes;
      if (bytes != null) {
        developer.log('   Menggunakan bytes yang sudah ada',
            name: 'PembayaranService');
        fileBytes = bytes;
      } else {
        developer.log('   Membaca bytes dari file...',
            name: 'PembayaranService');
        fileBytes = await file.readAsBytes();
      }
      developer.log(
          '   Ukuran file: ${fileBytes.length} bytes (${(fileBytes.length / 1024).toStringAsFixed(2)} KB)',
          name: 'PembayaranService');

      developer.log('   Mengirim file ke Supabase Storage...',
          name: 'PembayaranService');
      await SupabaseConfig.client.storage
          .from(SupabaseConfig.buktiTransferBucket)
          .uploadBinary(fileName, fileBytes);
      developer.log('✅ File berhasil diupload ke storage',
          name: 'PembayaranService');

      final publicUrl = SupabaseConfig.client.storage
          .from(SupabaseConfig.buktiTransferBucket)
          .getPublicUrl(fileName);
      developer.log('✅ Public URL didapatkan: $publicUrl',
          name: 'PembayaranService');

      return publicUrl;
    } catch (e, stackTrace) {
      developer.log(
        '❌ EXCEPTION di _uploadBuktiTransfer',
        name: 'PembayaranService',
        error: e,
        stackTrace: stackTrace,
      );
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
