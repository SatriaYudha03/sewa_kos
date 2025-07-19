// lib/features/owner_dashboard/screens/add_edit_kos_screen.dart
import 'dart:convert'; // Untuk base64Encode
import 'dart:io'; // Untuk File
import 'dart:typed_data'; // Untuk Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk cek platform web
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/services/kos_service.dart'; // Import KosService
import 'package:sewa_kos/core/models/kos_model.dart'; // Import KosModel
import 'package:sewa_kos/core/constants/app_constants.dart'; // Import AppConstants
import 'package:file_picker/file_picker.dart'; // Untuk memilih file gambar

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
  final TextEditingController _fasilitasUmumController = TextEditingController();

  PlatformFile? _imageFile;
  Uint8List? _webImage; // Untuk pratinjau gambar di web
  // Hapus int? _currentFotoUtamaId; karena tidak diperlukan lagi

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.kos != null) {
      _namaKosController.text = widget.kos!.namaKos;
      _alamatController.text = widget.kos!.alamat;
      _deskripsiController.text = widget.kos!.deskripsi ?? '';
      _fasilitasUmumController.text = widget.kos!.fasilitasUmum ?? '';
      // Hapus baris _currentFotoUtamaId = widget.kos!.fotoUtamaId;
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
          // Tidak perlu set _currentFotoUtamaId = null; karena tidak ada variabel itu lagi
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

    String? fotoUtamaBase64;
    if (_imageFile != null && _imageFile!.bytes != null) {
      fotoUtamaBase64 = base64Encode(_imageFile!.bytes!);
    } 
    // Jika _imageFile null, artinya user tidak memilih gambar baru.
    // Jika ini mode edit dan _imageFile null, kita tidak akan mengubah gambar.
    // PHP API kita (update.php) sudah dirancang untuk mempertahankan BLOB yang ada
    // jika field foto_utama tidak dikirim, atau menghapus jika dikirim null secara eksplisit.
    // Jadi, kita hanya akan mengirim fotoUtamaBase64 jika ada gambar baru.
    // Jika ingin menghapus gambar lama secara eksplisit, Anda bisa menambah tombol 'Hapus Gambar'.

    final kosService = KosService();
    dynamic response;

    try {
      if (widget.kos == null) {
        // Mode Tambah Kos Baru
        response = await kosService.addKos(
          namaKos: _namaKosController.text,
          alamat: _alamatController.text,
          deskripsi: _deskripsiController.text.isNotEmpty ? _deskripsiController.text : null,
          fotoUtama: fotoUtamaBase64,
          fasilitasUmum: _fasilitasUmumController.text.isNotEmpty ? _fasilitasUmumController.text : null,
        );
      } else {
        // Mode Edit Kos
        response = await kosService.updateKos(
          id: widget.kos!.id,
          namaKos: _namaKosController.text,
          alamat: _alamatController.text,
          deskripsi: _deskripsiController.text.isNotEmpty ? _deskripsiController.text : null,
          fotoUtama: fotoUtamaBase64, // Hanya kirim jika ada gambar baru
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
          Navigator.pop(context, true);
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
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
                    Center( // Tambahkan Center untuk tampilan gambar
                      child: _imageFile != null // Jika ada gambar baru dipilih (dari FilePicker)
                          ? kIsWeb // Cek apakah di web
                              ? Image.memory(_webImage!, height: 150, fit: BoxFit.cover) // Tampilan untuk web
                              : Image.file(File(_imageFile!.path!), height: 150, fit: BoxFit.cover) // Tampilan untuk mobile
                          : widget.kos != null && widget.kos!.hasImage // Jika tidak ada gambar baru, tapi ada gambar lama
                              ? Image.network(
                                  '${AppConstants.baseUrl}/images/serve.php?type=kos&id=${widget.kos!.id}', // Panggil serve.php dengan ID Kos
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                )
                              : Container( // Jika tidak ada gambar sama sekali (baru atau lama)
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
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
    _fasilitasUmumController.dispose();
    super.dispose();
  }
}