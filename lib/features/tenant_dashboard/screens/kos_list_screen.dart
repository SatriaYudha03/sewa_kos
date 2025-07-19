// lib/features/tenant_dashboard/screens/kos_list_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/kos_model.dart';
import 'package:sewa_kos/core/services/kos_service.dart';
import 'package:sewa_kos/features/tenant_dashboard/screens/kos_detail_screen.dart';

class KosListScreen extends StatefulWidget {
  const KosListScreen({super.key});

  @override
  State<KosListScreen> createState() => _KosListScreenState();
}

class _KosListScreenState extends State<KosListScreen> {
  final KosService _kosService = KosService();
  Future<List<Kos>>? _kosListFuture;

  final TextEditingController _searchController = TextEditingController();
  String _currentKeyword = '';
  double? _minPriceFilter;
  double? _maxPriceFilter;
  String _fasilitasFilter = ''; // Contoh: "AC,KM Dalam"

  @override
  void initState() {
    super.initState();
    _fetchKosList(); // Ambil semua kos awalnya
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil daftar kos dengan filter
  Future<void> _fetchKosList() async {
    setState(() {
      _kosListFuture = _kosService.searchKos(
        keyword: _currentKeyword.isEmpty ? null : _currentKeyword,
        minPrice: _minPriceFilter,
        maxPrice: _maxPriceFilter,
        fasilitas: _fasilitasFilter.isEmpty ? null : _fasilitasFilter,
      );
    });
  }

  // Fungsi untuk navigasi ke detail kos
  void _navigateToKosDetail(Kos kos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KosDetailScreen(kos: kos)),
    );
  }

  // Fungsi untuk menampilkan dialog filter
  Future<void> _showFilterDialog() async {
    double tempMinPrice = _minPriceFilter ?? 0;
    double tempMaxPrice = _maxPriceFilter ?? 5000000; // Contoh maks harga
    String tempFasilitas = _fasilitasFilter;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Kos'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Harga Min (Rp)'),
                  controller: TextEditingController(text: tempMinPrice.toStringAsFixed(0)),
                  onChanged: (val) {
                    tempMinPrice = double.tryParse(val) ?? 0;
                  },
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Harga Max (Rp)'),
                  controller: TextEditingController(text: tempMaxPrice.toStringAsFixed(0)),
                  onChanged: (val) {
                    tempMaxPrice = double.tryParse(val) ?? 5000000;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Fasilitas (pisahkan koma)'),
                  controller: TextEditingController(text: tempFasilitas),
                  onChanged: (val) {
                    tempFasilitas = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _minPriceFilter = tempMinPrice;
                  _maxPriceFilter = tempMaxPrice;
                  _fasilitasFilter = tempFasilitas;
                });
                _fetchKosList(); // Ambil ulang daftar dengan filter baru
                Navigator.pop(context); // Tutup dialog
              },
              child: const Text('Terapkan Filter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Kos'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama kos, alamat, atau deskripsi...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _currentKeyword = '';
                                });
                                _fetchKosList(); // Refresh tanpa keyword
                              },
                            )
                          : const Icon(Icons.search, color: Colors.grey),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _currentKeyword = value;
                      });
                      if (value.isEmpty) { // Langsung refresh jika search bar dikosongkan
                         _fetchKosList();
                      }
                    },
                    onSubmitted: (value) {
                      _fetchKosList(); // Trigger pencarian saat enter
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter Pencarian',
                ),
              ],
            ),
          ),
        ),
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
                    _currentKeyword.isNotEmpty || _minPriceFilter != null || _maxPriceFilter != null || _fasilitasFilter.isNotEmpty
                        ? 'Tidak ada kos ditemukan dengan kriteria pencarian ini.'
                        : 'Tidak ada kos ditemukan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchKosList,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
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
                if (kos.fotoUtama != null && kos.fotoUtama!.isNotEmpty) {
                  final fullImageUrl = '${AppConstants.baseUrl}${kos.fotoUtama!}';
                  // print('DEBUG_TENANT_IMAGE_URL: Mencoba memuat gambar dari: $fullImageUrl');
                  backgroundImage = NetworkImage(fullImageUrl);
                } else {
                  backgroundImage = const AssetImage(AppConstants.imageAssetPlaceholderKos);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: AppConstants.defaultMargin / 2),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)),
                  child: InkWell(
                    onTap: () => _navigateToKosDetail(kos),
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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