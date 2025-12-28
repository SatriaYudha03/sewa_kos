// lib/features/tenant_dashboard/screens/kos_list_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/kos_model.dart';
import 'package:sewa_kos/core/services/kos_service.dart';
import 'package:sewa_kos/features/tenant_dashboard/screens/kos_detail_screen.dart';
import 'dart:async'; // Import untuk Timer

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
  String _fasilitasFilter = '';

  // PageController untuk banner
  // InitialPage diatur ke nilai yang besar agar kita bisa scroll ke kiri/kanan dari awal
  final PageController _pageController = PageController(
    viewportFraction: 0.85,
    initialPage: 1000, // Nilai awal yang cukup besar
  );

  // --- Daftar gambar banner statis dari assets ---
  final List<String> _staticBannerImages = [
    'assets/images/banner1.png',
    'assets/images/banner2.png',
    'assets/images/banner3.png',
  ];

  Timer? _timer; // Deklarasi Timer

  @override
  void initState() {
    super.initState();
    _fetchKosList(); // Ambil daftar kos utama
    _startBannerAutoScroll(); // Mulai auto-scrolling banner
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose(); // Dispose PageController
    _timer?.cancel(); // Pastikan timer dibatalkan saat widget di-dispose
    super.dispose();
  }

  // Fungsi untuk memulai auto-scrolling banner dengan infinite loop
  void _startBannerAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int currentPage = _pageController.page!.round();
        int totalImages = _staticBannerImages.length;

        // Hitung halaman berikutnya
        int nextPage = currentPage + 1;

        // Jika sudah mencapai "akhir logis" dari loop gambar,
        // kita akan melompat kembali ke awal set gambar asli
        // tanpa terlihat oleh pengguna (mulus).
        // Kita menggunakan modulo untuk menentukan indeks gambar yang sebenarnya.
        if ((nextPage % totalImages) == 0 && nextPage != currentPage + 1) {
          // Jika kita akan kembali ke indeks 0 dari gambar asli,
          // kita bisa melakukan jumpToPage ke posisi yang sesuai
          // untuk mempertahankan ilusi scroll ke kanan.
          // Misalnya, jika kita di page 1002 (banner3) dan next is 1003 (banner1),
          // kita bisa jump ke page 1000 (banner1) untuk reset.
          _pageController.jumpToPage(currentPage -
              totalImages +
              1); // Lompat ke posisi awal set gambar
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _fetchKosList() async {
    setState(() {
      _kosListFuture = _kosService.searchKos(
        keyword: _currentKeyword.isEmpty ? null : _currentKeyword,
        minPrice: _minPriceFilter,
        maxPrice: _maxPriceFilter,
      );
    });
  }

  void _navigateToKosDetail(Kos kos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KosDetailScreen(kos: kos)),
    );
  }

  Future<void> _showFilterDialog() async {
    double tempMinPrice = _minPriceFilter ?? 0;
    double tempMaxPrice = _maxPriceFilter ?? 5000000;
    String tempFasilitas = _fasilitasFilter;

    final minPriceController =
        TextEditingController(text: tempMinPrice.toStringAsFixed(0));
    final maxPriceController =
        TextEditingController(text: tempMaxPrice.toStringAsFixed(0));
    final fasilitasController = TextEditingController(text: tempFasilitas);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filter Kos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Harga Min
                Text(
                  'Harga Minimum',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: minPriceController,
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: '0',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppConstants.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (val) {
                    tempMinPrice = double.tryParse(val) ?? 0;
                  },
                ),
                const SizedBox(height: 16),
                // Harga Max
                Text(
                  'Harga Maksimum',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: maxPriceController,
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: '5000000',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppConstants.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (val) {
                    tempMaxPrice = double.tryParse(val) ?? 5000000;
                  },
                ),
                const SizedBox(height: 16),
                // Fasilitas
                Text(
                  'Fasilitas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fasilitasController,
                  decoration: InputDecoration(
                    hintText: 'WiFi, AC, Kamar Mandi Dalam...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: Colors.grey[500],
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppConstants.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (val) {
                    tempFasilitas = val;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Pisahkan dengan koma untuk beberapa fasilitas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _minPriceFilter = tempMinPrice;
                        _maxPriceFilter = tempMaxPrice;
                        _fasilitasFilter = tempFasilitas;
                      });
                      _fetchKosList();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Terapkan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding, vertical: 8.0),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 0),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _currentKeyword = '';
                                });
                                _fetchKosList();
                              },
                            )
                          : const Icon(Icons.search, color: Colors.grey),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _currentKeyword = value;
                      });
                      if (value.isEmpty) {
                        _fetchKosList();
                      }
                    },
                    onSubmitted: (value) {
                      _fetchKosList();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list,
                      color: Colors.white, size: 28),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter Pencarian',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN BANNER CAROUSEL ---
            const SizedBox(height: AppConstants.defaultPadding),
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                itemCount:
                    999999, // Jumlah item yang sangat besar untuk efek infinite scrolling
                itemBuilder: (context, index) {
                  // Gunakan operator modulo untuk mendapatkan indeks gambar yang sebenarnya
                  final imageUrl =
                      _staticBannerImages[index % _staticBannerImages.length];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius),
                      image: DecorationImage(
                        image: AssetImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            // --- AKHIR BAGIAN BANNER CAROUSEL ---

            // --- BAGIAN DAFTAR KOS UTAMA ---
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding),
              child: Text(
                'Kos Pilihan',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            FutureBuilder<List<Kos>>(
              future: _kosListFuture,
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
                          'Error memuat daftar kos: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
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
                        const Icon(Icons.home_outlined,
                            size: 80, color: Colors.grey),
                        const SizedBox(height: 20),
                        Text(
                          _currentKeyword.isNotEmpty ||
                                  _minPriceFilter != null ||
                                  _maxPriceFilter != null ||
                                  _fasilitasFilter.isNotEmpty
                              ? 'Tidak ada kos ditemukan dengan kriteria pencarian ini.'
                              : 'Tidak ada kos ditemukan.',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(AppConstants.defaultPadding / 2),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final kos = snapshot.data![index];

                      ImageProvider backgroundImage;
                      if (kos.hasImage && kos.fotoUtamaUrl != null) {
                        backgroundImage = NetworkImage(kos.fotoUtamaUrl!);
                      } else {
                        backgroundImage = const AssetImage(
                            AppConstants.imageAssetPlaceholderKos);
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: AppConstants.defaultMargin / 2),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.defaultBorderRadius)),
                        child: InkWell(
                          onTap: () => _navigateToKosDetail(kos),
                          borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius),
                          child: Padding(
                            padding: const EdgeInsets.all(
                                AppConstants.defaultPadding),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.defaultBorderRadius / 2),
                                    image: DecorationImage(
                                      image: backgroundImage,
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) {
                                        debugPrint(
                                            'ERROR_TENANT_IMAGE_LOAD: Gagal memuat gambar ${kos.namaKos}: $exception');
                                      },
                                    ),
                                  ),
                                  child: !kos.hasImage
                                      ? const Icon(Icons.apartment,
                                          size: 50,
                                          color: AppConstants.primaryColor)
                                      : null,
                                ),
                                const SizedBox(
                                    width: AppConstants.defaultPadding),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kos.namaKos,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        kos.alamat ?? '',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: AppConstants
                                                .textColorSecondary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      if (kos.fasilitasUmum != null &&
                                          kos.fasilitasUmum!.isNotEmpty)
                                        Text(
                                          'Fasilitas Umum: ${kos.fasilitasUmum}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppConstants
                                                  .textColorSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          'oleh ${kos.ownerName ?? kos.ownerUsername}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: AppConstants
                                                  .textColorSecondary),
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
          ],
        ),
      ),
    );
  }
}
