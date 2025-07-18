// lib/features/owner_dashboard/screens/my_kos_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/services/kos_service.dart';
import 'package:sewa_kos/core/models/kos_model.dart';
import 'package:sewa_kos/features/owner_dashboard/screens/add_edit_kos_screen.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/features/owner_dashboard/screens/kamar_management_screen.dart';

class MyKosScreen extends StatefulWidget {
  const MyKosScreen({super.key});

  @override
  State<MyKosScreen> createState() => _MyKosScreenState();
}

class _MyKosScreenState extends State<MyKosScreen> {
  final KosService _kosService = KosService();
  Future<List<Kos>>? _myKosFuture;

  @override
  void initState() {
    super.initState();
    _fetchMyKos();
  }

  Future<void> _fetchMyKos() async {
    setState(() {
      _myKosFuture = _kosService.getListKos();
    });
  }

  Future<void> _navigateToAddEditKos({Kos? kos}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditKosScreen(kos: kos)),
    );

    if (result == true) {
      _fetchMyKos();
    }
  }
  
  // <-- FUNGSI BARU: Navigasi ke manajemen kamar -->
  Future<void> _navigateToKamarManagement(Kos kos) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KamarManagementScreen(kos: kos)),
    );
    // Mungkin tidak perlu refresh daftar kos saat kembali dari manajemen kamar,
    // kecuali jika status kos berubah (misal semua kamar terisi/tersedia)
    // if (result == true) {
    //   _fetchMyKos(); 
    // }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kos Saya'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Kos>>(
        future: _myKosFuture,
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
                  Icon(Icons.home, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Anda belum memiliki properti kos.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddEditKos(),
                    icon: Icon(Icons.add_home),
                    label: Text('Tambah Kos Baru'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final kos = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: kos.fotoUtama != null && kos.fotoUtama!.isNotEmpty
                          ? NetworkImage(kos.fotoUtama!) as ImageProvider
                          : const AssetImage(AppConstants.imageAssetPlaceholderKos),
                      onBackgroundImageError: (exception, stackTrace) {
                        print('Error loading image for ${kos.namaKos}: $exception');
                      },
                      child: kos.fotoUtama == null || kos.fotoUtama!.isEmpty
                          ? Icon(Icons.apartment, size: 30, color: AppConstants.primaryColor)
                          : null,
                    ),
                    title: Text(
                      kos.namaKos,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(kos.alamat, style: const TextStyle(fontSize: 14)),
                        if (kos.fasilitasUmum != null && kos.fasilitasUmum!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Fasilitas: ${kos.fasilitasUmum}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol untuk manajemen Kamar
                        IconButton( // <-- TOMBOL BARU
                          icon: const Icon(Icons.meeting_room, color: Colors.indigo),
                          onPressed: () => _navigateToKamarManagement(kos),
                          tooltip: 'Kelola Kamar',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _navigateToAddEditKos(kos: kos),
                          tooltip: 'Edit Kos',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteKos(kos.id, kos.namaKos),
                          tooltip: 'Hapus Kos',
                        ),
                      ],
                    ),
                    onTap: () {
                      // Nanti bisa navigasi ke detail kos yang lebih lengkap (misal untuk penyewa)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Detail Kos: ${kos.namaKos}')),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditKos(),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _confirmDeleteKos(int kosId, String namaKos) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Kos'),
          content: Text('Apakah Anda yakin ingin menghapus kos "$namaKos"? Semua kamar dan pemesanan terkait juga akan terhapus.'),
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
      await _deleteKos(kosId);
    }
  }

  Future<void> _deleteKos(int kosId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menghapus kos...'), duration: Duration(seconds: 1)),
    );
    try {
      final response = await _kosService.deleteKos(kosId);
      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Kos berhasil dihapus.'), backgroundColor: Colors.green),
          );
          _fetchMyKos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal menghapus kos.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}