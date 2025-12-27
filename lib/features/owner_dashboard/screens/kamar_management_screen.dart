// lib/features/owner_dashboard/screens/kamar_management_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/models/kos_model.dart'; // Import KosModel
import 'package:sewa_kos/core/models/kamar_kos_model.dart'; // Import KamarKosModel
import 'package:sewa_kos/core/services/kamar_service.dart'; // Import KamarService
import 'package:sewa_kos/features/owner_dashboard/screens/add_edit_kamar_screen.dart'; // Import AddEditKamarScreen (akan dibuat)
import 'package:sewa_kos/core/constants/app_constants.dart'; // Import AppConstants

class KamarManagementScreen extends StatefulWidget {
  final Kos kos; // Kos yang kamar-kamarnya akan dikelola

  const KamarManagementScreen({super.key, required this.kos});

  @override
  State<KamarManagementScreen> createState() => _KamarManagementScreenState();
}

class _KamarManagementScreenState extends State<KamarManagementScreen> {
  final KamarService _kamarService = KamarService();
  Future<List<KamarKos>>? _kamarListFuture;

  @override
  void initState() {
    super.initState();
    _fetchKamarList();
  }

  // Fungsi untuk mengambil daftar kamar untuk kos ini
  Future<void> _fetchKamarList() async {
    setState(() {
      _kamarListFuture = _kamarService.getKamarByKosId(widget.kos.id);
    });
  }

  // Fungsi untuk navigasi ke Add/Edit Kamar dan refresh daftar
  Future<void> _navigateToAddEditKamar({KamarKos? kamar}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              AddEditKamarScreen(kosId: widget.kos.id, kamar: kamar)),
    );

    if (result == true) {
      _fetchKamarList(); // Refresh daftar kamar setelah menambah/mengedit
    }
  }

  // Fungsi untuk konfirmasi dan hapus kamar
  Future<void> _confirmDeleteKamar(int kamarId, String namaKamar) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Kamar'),
          content: Text(
              'Apakah Anda yakin ingin menghapus kamar "$namaKamar"? Semua pemesanan terkait juga akan terhapus.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteKamar(kamarId);
    }
  }

  Future<void> _deleteKamar(int kamarId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Menghapus kamar...'), duration: Duration(seconds: 1)),
    );
    try {
      final response = await _kamarService.deleteKamar(kamarId);
      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Kamar berhasil dihapus.'),
                backgroundColor: AppConstants.successColor),
          );
          _fetchKamarList(); // Refresh daftar kamar
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Gagal menghapus kamar.'),
                backgroundColor: AppConstants.errorColor),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kamar Kos "${widget.kos.namaKos}"'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<KamarKos>>(
        future: _kamarListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Belum ada kamar di kos ini.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddEditKamar(),
                    icon: Icon(Icons.add),
                    label: Text('Tambah Kamar Baru'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Tampilkan daftar kamar
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final kamar = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(
                      kamar.namaKamar,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Harga: Rp ${kamar.hargaSewa.toStringAsFixed(0)} / bulan'),
                        if (kamar.luasKamar != null &&
                            kamar.luasKamar!.isNotEmpty)
                          Text('Ukuran: ${kamar.luasKamar}'),
                        if (kamar.fasilitas != null &&
                            kamar.fasilitas!.isNotEmpty)
                          Text('Fasilitas: ${kamar.fasilitas}'),
                        Text(
                          'Status: ${kamar.status.displayName}',
                          style: TextStyle(
                            color: _getStatusColor(kamar.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () =>
                              _navigateToAddEditKamar(kamar: kamar),
                          tooltip: 'Edit Kamar',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDeleteKamar(kamar.id, kamar.namaKamar),
                          tooltip: 'Hapus Kamar',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditKamar(),
        backgroundColor:
            AppConstants.accentColor, // Warna berbeda dari FAB Kos utama
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(StatusKamar status) {
    switch (status) {
      case StatusKamar.tersedia:
        return Colors.green;
      case StatusKamar.terisi:
        return Colors.orange;
      case StatusKamar.perbaikan:
        return Colors.red;
    }
  }
}
