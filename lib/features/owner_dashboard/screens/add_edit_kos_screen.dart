// lib/features/owner_dashboard/screens/add_edit_kos_screen.dart
import 'dart:convert'; // Untuk base64Encode
import 'dart:io'; // Untuk PlatformFile, File
import 'dart:typed_data'; // Untuk Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk cek platform web
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Tetap perlu untuk http request jika tanpa service
import 'package:file_picker/file_picker.dart'; // Untuk memilih file gambar
import 'package:sewa_kos/core/services/kos_service.dart'; // Import KosService
import 'package:sewa_kos/core/models/kos_model.dart'; // Import KosModel
import 'package:sewa_kos/core/constants/app_constants.dart'; // Import AppConstants

class AddEditKosScreen extends StatefulWidget {
  final Kos? kos; // Jika ada kos, berarti mode edit

  const AddEditKosScreen({super.key, this.kos});

  @override
  State<AddEditKosScreen> createState() => _AddEditKosScreenState();
}

class _AddEditKosScreenState extends State<AddEditKosScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaKosController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _fotoUtamaController = TextEditingController(); // Untuk URL/Base64 gambar
  final TextEditingController _fasilitasUmumController = TextEditingController();

  PlatformFile? _imageFile;
  Uint8List? _webImage; // Untuk pratinjau gambar di web
  String? _currentImageUrl; // Untuk menyimpan URL gambar yang sudah ada saat mode edit

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.kos != null) {
      // Jika mode edit, isi controller dengan data kos yang ada
      _namaKosController.text = widget.kos!.namaKos;
      _alamatController.text = widget.kos!.alamat;
      _deskripsiController.text = widget.kos!.deskripsi ?? '';
      _fotoUtamaController.text = widget.kos!.fotoUtama ?? ''; // Ini mungkin URL, bukan Base64
      _fasilitasUmumController.text = widget.kos!.fasilitasUmum ?? '';
      _currentImageUrl = widget.kos!.fotoUtama; // Simpan URL gambar yang ada
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowCompression: true,
        withData: true, // Penting untuk web dan mobile (bytes)
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal membaca data gambar.')),
            );
            return;
        }
        if (file.size > 2 * 1024 * 1024) { // 2MB
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ukuran gambar maksimal 2MB')),
          );
          return;
        }

        setState(() {
          _imageFile = file;
          _webImage = file.bytes;
          _currentImageUrl = null; // Hapus URL lama jika memilih gambar baru
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? fotoUtamaData; // Akan berisi base64 atau URL lama
    if (_imageFile != null && _imageFile!.bytes != null) {
      fotoUtamaData = base64Encode(_imageFile!.bytes!); // Encode gambar baru ke Base64
    } else if (_currentImageUrl != null) {
      fotoUtamaData = _currentImageUrl; // Gunakan URL gambar lama jika tidak ada gambar baru
    }

    final kosService = KosService();
    dynamic response;

    try {
      if (widget.kos == null) {
        // Mode Tambah Kos Baru
        response = await kosService.addKos(
          namaKos: _namaKosController.text,
          alamat: _alamatController.text,
          deskripsi: _deskripsiController.text.isNotEmpty ? _deskripsiController.text : null,
          fotoUtama: fotoUtamaData, // Kirim Base64 atau URL
          fasilitasUmum: _fasilitasUmumController.text.isNotEmpty ? _fasilitasUmumController.text : null,
        );
      } else {
        // Mode Edit Kos
        response = await kosService.updateKos(
          id: widget.kos!.id,
          namaKos: _namaKosController.text,
          alamat: _alamatController.text,
          deskripsi: _deskripsiController.text.isNotEmpty ? _deskripsiController.text : null,
          fotoUtama: fotoUtamaData, // Kirim Base64 atau URL
          fasilitasUmum: _fasilitasUmumController.text.isNotEmpty ? _fasilitasUmumController.text : null,
        );
      }

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Operasi kos berhasil.'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          Navigator.pop(context, true); // Beri tahu MyKosScreen untuk refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Operasi kos gagal.'),
              backgroundColor: AppConstants.errorColor,
            ),
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
        title: Text(widget.kos == null ? 'Tambah Kos Baru' : 'Edit Kos'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _namaKosController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kos',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama Kos tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alamat tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deskripsiController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Kos (Opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    // Bagian untuk memilih/menampilkan gambar
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Foto Utama Kos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _imageFile != null
                        ? kIsWeb // Cek apakah di web
                            ? Image.memory(_webImage!, height: 150, fit: BoxFit.cover)
                            : Image.file(File(_imageFile!.path!), height: 150, fit: BoxFit.cover)
                        : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                            ? Image.network(_currentImageUrl!, height: 150, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                                ))
                            : Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                              ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fasilitasUmumController,
                      decoration: const InputDecoration(
                        labelText: 'Fasilitas Umum (Pisahkan dengan koma, Opsional)',
                        hintText: 'Misal: WiFi, Dapur Bersama, Parkir Motor',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        widget.kos == null ? 'Tambah Kos' : 'Simpan Perubahan',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _namaKosController.dispose();
    _alamatController.dispose();
    _deskripsiController.dispose();
    _fotoUtamaController.dispose(); // Masih ada tapi tidak digunakan langsung untuk input
    _fasilitasUmumController.dispose();
    super.dispose();
  }
}