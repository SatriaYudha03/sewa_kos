// lib/features/tenant_dashboard/screens/upload_payment_proof_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
import 'package:sewa_kos/core/services/pembayaran_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // Untuk Uint8List

class UploadPaymentProofScreen extends StatefulWidget {
  final Pemesanan pemesanan;
  final VoidCallback onProofUploaded;

  const UploadPaymentProofScreen({
    super.key,
    required this.pemesanan,
    required this.onProofUploaded,
  });

  @override
  State<UploadPaymentProofScreen> createState() => _UploadPaymentProofScreenState();
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
    _jumlahBayarController.text = widget.pemesanan.totalHarga.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _jumlahBayarController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImageFile = image;
        _pickedImageBytes = bytes;
      });
    }
  }

  // Fungsi untuk mengunggah bukti pembayaran
  Future<void> _uploadProof() async {
    if (_pickedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih bukti pembayaran terlebih dahulu.')),
      );
      return;
    }
    if (_jumlahBayarController.text.isEmpty || double.tryParse(_jumlahBayarController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan jumlah pembayaran yang valid.')),
      );
      return;
    }
    if (_selectedMetodePembayaran == null || _selectedMetodePembayaran!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih metode pembayaran.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _pembayaranService.uploadPaymentProof(
        pemesananId: widget.pemesanan.id,
        jumlahBayar: double.parse(_jumlahBayarController.text),
        metodePembayaran: _selectedMetodePembayaran!,
        buktiPembayaranFile: _pickedImageFile!,
        buktiPembayaranBytes: _pickedImageBytes, // <-- KIRIM BYTES JUGA DI SINI
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Bukti pembayaran berhasil diunggah!'), backgroundColor: AppConstants.successColor),
          );
          widget.onProofUploaded();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal mengunggah bukti pembayaran.'), backgroundColor: AppConstants.errorColor),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppConstants.errorColor),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total yang harus dibayar: Rp ${widget.pemesanan.totalHarga.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, color: AppConstants.textColorPrimary),
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
                              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 50, color: Colors.grey[600]),
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
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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