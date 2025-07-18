// lib/features/tenant_dashboard/screens/upload_payment_proof_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart'; // Import PemesananModel
import 'package:sewa_kos/core/services/pembayaran_service.dart'; // Import PembayaranService
import 'dart:io'; // Untuk File

class UploadPaymentProofScreen extends StatefulWidget {
  final Pemesanan pemesanan; // Pemesanan yang akan diupload buktinya
  final VoidCallback onProofUploaded; // Callback setelah berhasil upload

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

  XFile? _pickedImage;
  final TextEditingController _jumlahBayarController = TextEditingController();
  String? _selectedMetodePembayaran;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi jumlah bayar dengan total harga pemesanan
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
      setState(() {
        _pickedImage = image;
      });
    }
  }

  // Fungsi untuk mengunggah bukti pembayaran
  Future<void> _uploadProof() async {
    if (_pickedImage == null) {
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
        buktiPembayaranFile: _pickedImage!,
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Bukti pembayaran berhasil diunggah!'), backgroundColor: AppConstants.successColor),
          );
          widget.onProofUploaded(); // Panggil callback untuk refresh riwayat pemesanan
          Navigator.pop(context); // Kembali ke layar sebelumnya
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
                    'Pemesanan untuk: ${widget.pemesanan.namaKamar} di ${widget.pemesanan.namaKos}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total yang harus dibayar: Rp ${widget.pemesanan.totalHarga.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, color: AppConstants.textColorPrimary),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Input Jumlah Bayar
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

                  // Pilih Metode Pembayaran
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

                  // Tampilan dan Pilih Gambar
                  const Text(
                    'Bukti Pembayaran:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: _pickedImage == null
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
                        : Image.file(
                            File(_pickedImage!.path),
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

                  // Tombol Unggah
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