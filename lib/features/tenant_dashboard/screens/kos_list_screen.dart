// lib/features/tenant_dashboard/screens/kos_list_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/kos_model.dart'; // Import KosModel
import 'package:sewa_kos/core/services/kos_service.dart'; // Import KosService
import 'package:sewa_kos/features/tenant_dashboard/screens/kos_detail_screen.dart'; // Import KosDetailScreen (akan dibuat)

class KosListScreen extends StatefulWidget {
  const KosListScreen({super.key});

  @override
  State<KosListScreen> createState() => _KosListScreenState();
}

class _KosListScreenState extends State<KosListScreen> {
  final KosService _kosService = KosService();
  Future<List<Kos>>? _kosListFuture;

  @override
  void initState() {
    super.initState();
    _fetchKosList();
  }

  // Fungsi untuk mengambil daftar kos
  Future<void> _fetchKosList() async {
    setState(() {
      _kosListFuture = _kosService.getListKos();
    });
  }

  // Fungsi untuk navigasi ke detail kos
  void _navigateToKosDetail(Kos kos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KosDetailScreen(kos: kos)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Kos'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchKosList, // Tombol refresh
            tooltip: 'Refresh Daftar Kos',
          ),
          // Nanti bisa ditambahkan tombol filter/search
          // IconButton(
          //   icon: const Icon(Icons.filter_list),
          //   onPressed: () { /* logika filter */ },
          // ),
        ],
      ),
      body: FutureBuilder<List<Kos>>(
        future: _kosListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 80, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'Error memuat daftar kos: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchKosList,
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
                  Icon(Icons.home_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Tidak ada kos ditemukan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchKosList,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          } else {
            // Tampilkan daftar kos
            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding / 2),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final kos = snapshot.data![index];

                ImageProvider? backgroundImage;
                // Construct full image URL for NetworkImage (meskipun kita hiraukan masalah CORS gambar)
                if (kos.fotoUtama != null && kos.fotoUtama!.isNotEmpty) {
                  final fullImageUrl = '${AppConstants.baseUrl}${kos.fotoUtama!}';
                  // print('DEBUG_TENANT_IMAGE_URL: Mencoba memuat gambar dari: $fullImageUrl'); // Tetap aktifkan untuk debugging jika perlu
                  backgroundImage = NetworkImage(fullImageUrl);
                } else {
                  backgroundImage = const AssetImage(AppConstants.imageAssetPlaceholderKos);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: AppConstants.defaultMargin / 2),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)),
                  child: InkWell( // Menggunakan InkWell agar Card bisa di-tap
                    onTap: () => _navigateToKosDetail(kos),
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gambar Kos
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius / 2),
                              image: DecorationImage(
                                image: backgroundImage,
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  print('ERROR_TENANT_IMAGE_LOAD: Gagal memuat gambar ${kos.namaKos}: $exception');
                                  // Fallback ke placeholder jika error
                                  setState(() {
                                    backgroundImage = const AssetImage(AppConstants.imageAssetPlaceholderKos);
                                  });
                                },
                              ),
                            ),
                            child: (kos.fotoUtama == null || kos.fotoUtama!.isEmpty) && backgroundImage is AssetImage
                                ? Icon(Icons.apartment, size: 50, color: AppConstants.primaryColor.withOpacity(0.7))
                                : null,
                          ),
                          const SizedBox(width: AppConstants.defaultPadding),
                          // Detail Kos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kos.namaKos,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kos.alamat,
                                  style: const TextStyle(fontSize: 14, color: AppConstants.textColorSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                if (kos.fasilitasUmum != null && kos.fasilitasUmum!.isNotEmpty)
                                  Text(
                                    'Fasilitas Umum: ${kos.fasilitasUmum}',
                                    style: const TextStyle(fontSize: 12, color: AppConstants.textColorSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    'oleh ${kos.ownerName ?? kos.ownerUsername}',
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppConstants.textColorSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}