// lib/features/owner_dashboard/screens/my_kos_screen.dart
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
  int _refreshKey =
      0; // Tambahkan refresh key untuk FutureBuilder dan cache-busting gambar

  @override
  void initState() {
    super.initState();
    print('DEBUG: MyKosScreenState initState called.');
    _fetchMyKos();
  }

  @override
  void dispose() {
    print('DEBUG: MyKosScreenState dispose called.');
    super.dispose();
  }

  Future<void> _fetchMyKos() async {
    print('DEBUG: _fetchMyKos triggered. Old refreshKey: $_refreshKey');
    // Langkah 1: Set Future ke null untuk memaksa FutureBuilder ke state waiting
    setState(() {
      _myKosFuture = null;
      _refreshKey++; // Tingkatkan key untuk memastikan rebuild
      print('DEBUG: _myKosFuture set to null, new refreshKey: $_refreshKey');
    });

    // Langkah 2: Ambil data baru
    final newFuture = _kosService.getListKos();

    // Langkah 3: Set Future yang baru setelah data diambil
    setState(() {
      _myKosFuture = newFuture;
      print('DEBUG: _myKosFuture assigned new Future.');
    });
  }

  Future<void> _navigateToAddEditKos({Kos? kos}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditKosScreen(kos: kos)),
    );

    if (result == true) {
      print('DEBUG: AddEditKosScreen mengembalikan true, memicu _fetchMyKos.');
      _fetchMyKos(); // Refresh daftar setelah berhasil simpan/edit
    }
  }

  Future<void> _navigateToKamarManagement(Kos kos) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KamarManagementScreen(kos: kos)),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        'DEBUG: MyKosScreen build method called. Current refreshKey: $_refreshKey');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kos Saya'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _fetchMyKos, // Tombol refresh memanggil fungsi _fetchMyKos
            tooltip: 'Refresh Daftar Kos',
          ),
        ],
      ),
      body: FutureBuilder<List<Kos>>(
        key: ValueKey(
            _refreshKey), // Gunakan ValueKey di sini untuk memaksa rebuild FutureBuilder
        future: _myKosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchMyKos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'Anda belum memiliki properti kos.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddEditKos(),
                    icon: const Icon(Icons.add_home),
                    label: const Text('Tambah Kos Baru'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding / 2),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final kos = snapshot.data![index];

                ImageProvider? backgroundImage;
                if (kos.hasImage && kos.fotoUtamaUrl != null) {
                  // Gunakan URL dari Supabase Storage
                  backgroundImage = NetworkImage(kos.fotoUtamaUrl!);
                } else {
                  backgroundImage =
                      const AssetImage(AppConstants.imageAssetPlaceholderKos);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: AppConstants.defaultMargin / 2),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(AppConstants.defaultPadding),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: backgroundImage,
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint(
                            'ERROR_IMAGE_LOAD: Gagal memuat gambar untuk ${kos.namaKos}: $exception');
                      },
                      child: !kos.hasImage
                          ? const Icon(Icons.apartment,
                              size: 30, color: AppConstants.primaryColor)
                          : null,
                    ),
                    title: Text(
                      kos.namaKos,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(kos.alamat ?? '',
                            style: const TextStyle(fontSize: 14)),
                        if (kos.fasilitasUmum != null &&
                            kos.fasilitasUmum!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Fasilitas: ${kos.fasilitasUmum}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.meeting_room,
                              color: Colors.indigo),
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
                          onPressed: () =>
                              _confirmDeleteKos(kos.id, kos.namaKos),
                          tooltip: 'Hapus Kos',
                        ),
                      ],
                    ),
                    onTap: () {
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
          content: Text(
              'Apakah Anda yakin ingin menghapus kos "$namaKos"? Semua kamar dan pemesanan terkait juga akan terhapus.'),
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
      const SnackBar(
          content: Text('Menghapus kos...'), duration: Duration(seconds: 1)),
    );
    try {
      final response = await _kosService.deleteKos(kosId);
      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Kos berhasil dihapus.'),
                backgroundColor: AppConstants.successColor),
          );
          _fetchMyKos(); // Refresh daftar setelah penghapusan
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Gagal menghapus kos.'),
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
}
