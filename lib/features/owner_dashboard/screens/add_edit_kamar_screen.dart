// lib/features/owner_dashboard/screens/add_edit_kamar_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/models/kamar_kos_model.dart'; // Import KamarKosModel
import 'package:sewa_kos/core/services/kamar_service.dart'; // Import KamarService
import 'package:sewa_kos/core/constants/app_constants.dart'; // Import AppConstants

class AddEditKamarScreen extends StatefulWidget {
  final int kosId; // ID kos tempat kamar ini berada (wajib)
  final KamarKos? kamar; // Jika ada kamar, berarti mode edit

  const AddEditKamarScreen({super.key, required this.kosId, this.kamar});

  @override
  State<AddEditKamarScreen> createState() => _AddEditKamarScreenState();
}

class _AddEditKamarScreenState extends State<AddEditKamarScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaKamarController = TextEditingController();
  final TextEditingController _hargaSewaController = TextEditingController();
  final TextEditingController _luasKamarController = TextEditingController();
  final TextEditingController _fasilitasController = TextEditingController(); // Fasilitas string (misal: "AC, KM Dalam")

  String? _selectedStatus; // 'tersedia', 'terisi', 'perbaikan'

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.kamar != null) {
      // Jika mode edit, isi controller dengan data kamar yang ada
      _namaKamarController.text = widget.kamar!.namaKamar;
      _hargaSewaController.text = widget.kamar!.hargaSewa.toString();
      _luasKamarController.text = widget.kamar!.luasKamar ?? '';
      _fasilitasController.text = widget.kamar!.fasilitas ?? '';
      _selectedStatus = widget.kamar!.status;
    } else {
      _selectedStatus = 'tersedia'; // Default untuk kamar baru
    }
  }

  Future<void> _saveKamar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final kamarService = KamarService();
    dynamic response;

    // Ambil fasilitas dari input (misalnya: "AC, TV, KM Dalam")
    final String? fasilitasText = _fasilitasController.text.trim().isNotEmpty ? _fasilitasController.text.trim() : null;

    try {
      if (widget.kamar == null) {
        // Mode Tambah Kamar Baru
        response = await kamarService.addKamar(
          kosId: widget.kosId,
          namaKamar: _namaKamarController.text,
          hargaSewa: double.parse(_hargaSewaController.text),
          luasKamar: _luasKamarController.text.isNotEmpty ? _luasKamarController.text : null,
          fasilitas: fasilitasText,
        );
      } else {
        // Mode Edit Kamar
        response = await kamarService.updateKamar(
          kamarId: widget.kamar!.id,
          namaKamar: _namaKamarController.text,
          hargaSewa: double.parse(_hargaSewaController.text),
          luasKamar: _luasKamarController.text.isNotEmpty ? _luasKamarController.text : null,
          fasilitas: fasilitasText,
          status: _selectedStatus, // Update status juga
        );
      }

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Operasi kamar berhasil.'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          Navigator.pop(context, true); // Beri tahu KamarManagementScreen untuk refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Operasi kamar gagal.'),
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
        title: Text(widget.kamar == null ? 'Tambah Kamar Baru' : 'Edit Kamar'),
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
                      controller: _namaKamarController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kamar (misal: Kamar A1, Kamar Depan)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama Kamar tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hargaSewaController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Sewa per Bulan',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga Sewa tidak boleh kosong';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Masukkan harga yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _luasKamarController,
                      decoration: const InputDecoration(
                        labelText: 'Ukuran Kamar (misal: 3x4 meter, Opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fasilitasController,
                      decoration: const InputDecoration(
                        labelText: 'Fasilitas Kamar (Pisahkan dengan koma, Opsional)',
                        hintText: 'Misal: AC, Kamar Mandi Dalam, Kasur',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status Kamar',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'tersedia', child: Text('Tersedia')),
                        DropdownMenuItem(value: 'terisi', child: Text('Terisi')),
                        DropdownMenuItem(value: 'perbaikan', child: Text('Perbaikan')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Status kamar wajib dipilih';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveKamar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        widget.kamar == null ? 'Tambah Kamar' : 'Simpan Perubahan',
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
    _namaKamarController.dispose();
    _hargaSewaController.dispose();
    _luasKamarController.dispose();
    _fasilitasController.dispose();
    super.dispose();
  }
}