// lib/features/owner_dashboard/screens/add_edit_kos_screen.dart
import 'dart:convert'; // Untuk base64Encode
import 'dart:io'; // Untuk File
import 'dart:typed_data'; // Untuk Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk cek platform web
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/services/kos_service.dart'; // Import KosService
import 'package:sewa_kos/core/models/kos_model.dart'; // Import KosModel
import 'package:sewa_kos/core/constants/app_constants.dart'; // Import AppConstants
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar

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
  final TextEditingController _fasilitasUmumController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _imageFile;
  Uint8List? _imageBytes; // Untuk pratinjau gambar

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.kos != null) {
      _namaKosController.text = widget.kos!.namaKos;
      _alamatController.text = widget.kos!.alamat ?? '';
      _deskripsiController.text = widget.kos!.deskripsi ?? '';
      _fasilitasUmumController.text = widget.kos!.fasilitasUmum ?? '';
    }
  }

  Future<void> _pickImage() async {
    try {
      // Tampilkan bottom sheet untuk pilih sumber gambar
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        if (bytes.length > 2 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ukuran gambar maksimal 2MB')),
            );
          }
          return;
        }

        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
        );
      }
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
    if (_imageBytes != null) {
      fotoUtamaBase64 = base64Encode(_imageBytes!);
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
          deskripsi: _deskripsiController.text.isNotEmpty
              ? _deskripsiController.text
              : null,
          fotoUtama: fotoUtamaBase64,
          fasilitasUmum: _fasilitasUmumController.text.isNotEmpty
              ? _fasilitasUmumController.text
              : null,
        );
      } else {
        // Mode Edit Kos
        response = await kosService.updateKos(
          id: widget.kos!.id,
          namaKos: _namaKosController.text,
          alamat: _alamatController.text,
          deskripsi: _deskripsiController.text.isNotEmpty
              ? _deskripsiController.text
              : null,
          fotoUtama: fotoUtamaBase64, // Hanya kirim jika ada gambar baru
          fasilitasUmum: _fasilitasUmumController.text.isNotEmpty
              ? _fasilitasUmumController.text
              : null,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(
            color: AppConstants.primaryColor.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius - 2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : widget.kos != null && widget.kos!.hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius - 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.kos!.fotoUtamaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildEmptyImagePlaceholder(),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildEmptyImagePlaceholder(),
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: AppConstants.primaryColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap untuk pilih foto',
          style: TextStyle(
            color: AppConstants.textColorSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Format: JPG, PNG (Max 2MB)',
          style: TextStyle(
            color: AppConstants.textColorSecondary.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppConstants.primaryColor),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide:
            const BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: const BorderSide(color: AppConstants.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: const BorderSide(color: AppConstants.errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.kos == null ? 'Tambah Kos Baru' : 'Edit Kos',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Menyimpan data...',
                    style: TextStyle(
                      color: AppConstants.textColorSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header gradient
                  Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Card Informasi Dasar
                          Card(
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.largeBorderRadius),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                      'Informasi Dasar', Icons.home_outlined),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _namaKosController,
                                    decoration: _buildInputDecoration(
                                      label: 'Nama Kos',
                                      icon: Icons.apartment,
                                      hint: 'Masukkan nama kos',
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
                                    decoration: _buildInputDecoration(
                                      label: 'Alamat Lengkap',
                                      icon: Icons.location_on_outlined,
                                      hint: 'Masukkan alamat lengkap kos',
                                    ),
                                    maxLines: 2,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Alamat tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card Foto Utama
                          Card(
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.largeBorderRadius),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Foto Utama Kos',
                                      Icons.photo_camera_outlined),
                                  const SizedBox(height: 8),
                                  _buildImagePicker(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card Deskripsi & Fasilitas
                          Card(
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.largeBorderRadius),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Detail Tambahan',
                                      Icons.description_outlined),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _deskripsiController,
                                    decoration: _buildInputDecoration(
                                      label: 'Deskripsi Kos',
                                      icon: Icons.notes,
                                      hint: 'Jelaskan tentang kos Anda...',
                                    ),
                                    maxLines: 4,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _fasilitasUmumController,
                                    decoration: _buildInputDecoration(
                                      label: 'Fasilitas Umum',
                                      icon: Icons.wifi,
                                      hint: 'WiFi, Dapur Bersama, Parkir Motor',
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: AppConstants.textColorSecondary
                                            .withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Pisahkan fasilitas dengan koma',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppConstants.textColorSecondary
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tombol Submit
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius),
                              gradient: const LinearGradient(
                                colors: [
                                  AppConstants.primaryColor,
                                  AppConstants.accentColor,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.primaryColor
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.defaultBorderRadius),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.kos == null
                                        ? Icons.add_circle_outline
                                        : Icons.save_outlined,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.kos == null
                                        ? 'Tambah Kos'
                                        : 'Simpan Perubahan',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
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
