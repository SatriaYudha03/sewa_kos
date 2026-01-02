// lib/features/tenant_dashboard/screens/upload_payment_proof_screen.dart (DIUPDATE)
import 'dart:developer' as developer;
import 'dart:typed_data'; // Untuk Uint8List

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
import 'package:sewa_kos/core/services/pembayaran_service.dart';

class UploadPaymentProofScreen extends StatefulWidget {
  final Pemesanan pemesanan;
  final VoidCallback onProofUploaded;

  const UploadPaymentProofScreen({
    super.key,
    required this.pemesanan,
    required this.onProofUploaded,
  });

  @override
  State<UploadPaymentProofScreen> createState() =>
      _UploadPaymentProofScreenState();
}

class _UploadPaymentProofScreenState extends State<UploadPaymentProofScreen> {
  final PembayaranService _pembayaranService = PembayaranService();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImageFile;
  Uint8List? _pickedImageBytes; // Sudah ada

  final TextEditingController _jumlahBayarController = TextEditingController();
  String? _selectedMetodePembayaran;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _jumlahBayarController.text =
        widget.pemesanan.totalHarga.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _jumlahBayarController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    try {
      developer.log('🖼️ Memulai proses pemilihan gambar...',
          name: 'UploadPaymentProof');

      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        developer.log('✅ Gambar dipilih: ${image.name}, Path: ${image.path}',
            name: 'UploadPaymentProof');

        final bytes = await image.readAsBytes();
        developer.log(
            '✅ Berhasil membaca bytes gambar. Ukuran: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(2)} KB)',
            name: 'UploadPaymentProof');

        setState(() {
          _pickedImageFile = image;
          _pickedImageBytes = bytes;
        });
      } else {
        developer.log('❌ Tidak ada gambar yang dipilih (dibatalkan)',
            name: 'UploadPaymentProof');
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ ERROR saat memilih gambar',
        name: 'UploadPaymentProof',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  // Fungsi untuk mengunggah bukti pembayaran
  Future<void> _uploadProof() async {
    developer.log('\n═══════════════════════════════════════',
        name: 'UploadPaymentProof');
    developer.log('🚀 MEMULAI PROSES UPLOAD BUKTI PEMBAYARAN',
        name: 'UploadPaymentProof');
    developer.log('═══════════════════════════════════════',
        name: 'UploadPaymentProof');

    // Validasi file gambar
    if (_pickedImageFile == null) {
      developer.log('❌ VALIDASI GAGAL: File gambar tidak dipilih',
          name: 'UploadPaymentProof');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mohon pilih bukti pembayaran terlebih dahulu.')),
      );
      return;
    }
    developer.log('✅ File gambar: ${_pickedImageFile!.name}',
        name: 'UploadPaymentProof');
    developer.log('   Path: ${_pickedImageFile!.path}',
        name: 'UploadPaymentProof');
    developer.log(
        '   Bytes tersedia: ${_pickedImageBytes != null ? "Ya (${_pickedImageBytes!.length} bytes)" : "Tidak"}',
        name: 'UploadPaymentProof');

    // Validasi jumlah bayar
    if (_jumlahBayarController.text.isEmpty ||
        double.tryParse(_jumlahBayarController.text) == null) {
      developer.log(
          '❌ VALIDASI GAGAL: Jumlah bayar tidak valid: "${_jumlahBayarController.text}"',
          name: 'UploadPaymentProof');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mohon masukkan jumlah pembayaran yang valid.')),
      );
      return;
    }
    final jumlahBayar = double.parse(_jumlahBayarController.text);
    developer.log('✅ Jumlah bayar: Rp ${jumlahBayar.toStringAsFixed(0)}',
        name: 'UploadPaymentProof');

    // Validasi metode pembayaran
    if (_selectedMetodePembayaran == null ||
        _selectedMetodePembayaran!.isEmpty) {
      developer.log('❌ VALIDASI GAGAL: Metode pembayaran tidak dipilih',
          name: 'UploadPaymentProof');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih metode pembayaran.')),
      );
      return;
    }
    developer.log('✅ Metode pembayaran: $_selectedMetodePembayaran',
        name: 'UploadPaymentProof');

    developer.log('\n📦 DATA YANG AKAN DIKIRIM:', name: 'UploadPaymentProof');
    developer.log('   - Pemesanan ID: ${widget.pemesanan.id}',
        name: 'UploadPaymentProof');
    developer.log('   - Jumlah Bayar: Rp ${jumlahBayar.toStringAsFixed(0)}',
        name: 'UploadPaymentProof');
    developer.log('   - Metode: $_selectedMetodePembayaran',
        name: 'UploadPaymentProof');
    developer.log('   - File: ${_pickedImageFile!.name}',
        name: 'UploadPaymentProof');

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('\n🌐 Mengirim request ke PembayaranService...',
          name: 'UploadPaymentProof');

      final response = await _pembayaranService.uploadPaymentProof(
        pemesananId: widget.pemesanan.id,
        jumlahBayar: jumlahBayar,
        metodePembayaran: _selectedMetodePembayaran!,
        buktiPembayaranFile: _pickedImageFile!,
        buktiPembayaranBytes: _pickedImageBytes, // <-- KIRIM BYTES JUGA DI SINI
      );

      developer.log('✅ Response diterima dari server',
          name: 'UploadPaymentProof');
      developer.log('   Status: ${response['status']}',
          name: 'UploadPaymentProof');
      developer.log('   Message: ${response['message']}',
          name: 'UploadPaymentProof');
      developer.log('   Full response: $response', name: 'UploadPaymentProof');

      if (mounted) {
        if (response['status'] == 'success') {
          developer.log('\n✅ ═════════════════════════════════════',
              name: 'UploadPaymentProof');
          developer.log('✅ UPLOAD BERHASIL!', name: 'UploadPaymentProof');
          developer.log('✅ ═════════════════════════════════════\n',
              name: 'UploadPaymentProof');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ??
                    'Bukti pembayaran berhasil diunggah!'),
                backgroundColor: AppConstants.successColor),
          );
          widget.onProofUploaded();
          Navigator.pop(context);
        } else {
          developer.log('\n❌ ═════════════════════════════════════',
              name: 'UploadPaymentProof');
          developer.log('❌ UPLOAD GAGAL (Status: ${response['status']})',
              name: 'UploadPaymentProof');
          developer.log('❌ Pesan error: ${response['message']}',
              name: 'UploadPaymentProof');
          developer.log('❌ ═════════════════════════════════════\n',
              name: 'UploadPaymentProof');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ??
                    'Gagal mengunggah bukti pembayaran.'),
                backgroundColor: AppConstants.errorColor),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ ═════════════════════════════════════',
        name: 'UploadPaymentProof',
      );
      developer.log(
        '❌ EXCEPTION TERJADI SAAT UPLOAD',
        name: 'UploadPaymentProof',
        error: e,
        stackTrace: stackTrace,
      );
      developer.log(
        '❌ ═════════════════════════════════════\n',
        name: 'UploadPaymentProof',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppConstants.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Bukti Pembayaran'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pemesanan untuk: ${widget.pemesanan.namaKamar ?? ''} di ${widget.pemesanan.namaKos ?? ''}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total yang harus dibayar: Rp ${widget.pemesanan.totalHarga.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 16, color: AppConstants.textColorPrimary),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  TextFormField(
                    controller: _jumlahBayarController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Bayar',
                      hintText: 'Masukkan jumlah yang Anda bayarkan',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  DropdownButtonFormField<String>(
                    value: _selectedMetodePembayaran,
                    decoration: const InputDecoration(
                      labelText: 'Metode Pembayaran',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Pilih metode pembayaran'),
                    items: <String>['Transfer Bank', 'E-Wallet', 'Tunai']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMetodePembayaran = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  const Text(
                    'Bukti Pembayaran:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: _pickedImageBytes == null
                        ? Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image,
                                    size: 50, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada gambar dipilih',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : Image.memory(
                            _pickedImageBytes!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding / 2),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pilih Gambar Bukti'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _uploadProof,
                      icon: const Icon(Icons.cloud_upload, color: Colors.white),
                      label: const Text(
                        'Unggah Bukti Pembayaran',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
