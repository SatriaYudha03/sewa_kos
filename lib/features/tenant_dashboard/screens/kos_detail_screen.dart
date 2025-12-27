// lib/features/tenant_dashboard/screens/kos_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/kos_model.dart';
import 'package:sewa_kos/core/models/kamar_kos_model.dart';
import 'package:sewa_kos/core/services/kamar_service.dart';
import 'package:sewa_kos/core/services/pemesanan_service.dart';

class KosDetailScreen extends StatefulWidget {
  final Kos kos;

  const KosDetailScreen({super.key, required this.kos});

  @override
  State<KosDetailScreen> createState() => _KosDetailScreenState();
}

class _KosDetailScreenState extends State<KosDetailScreen> {
  final KamarService _kamarService = KamarService();
  final PemesananService _pemesananService = PemesananService();
  Future<List<KamarKos>>? _availableRoomsFuture;

  KamarKos? _selectedKamar;
  DateTime? _selectedTanggalMulai;
  int _durasiSewa = 1;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRooms();
  }

  Future<void> _fetchAvailableRooms() async {
    setState(() {
      _availableRoomsFuture = _kamarService.getKamarByKosId(widget.kos.id);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedTanggalMulai) {
      setState(() {
        _selectedTanggalMulai = picked;
      });
    }
  }

  Future<void> _createBooking() async {
    if (_selectedKamar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kamar yang ingin Anda sewa.')),
      );
      return;
    }
    if (_selectedTanggalMulai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal mulai sewa.')),
      );
      return;
    }

    setState(() {
      // Atur loading state jika ada
    });

    try {
      final response = await _pemesananService.createPemesanan(
        kamarId: _selectedKamar!.id,
        tanggalMulai: _selectedTanggalMulai!,
        durasiSewa: _durasiSewa,
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Pemesanan berhasil dibuat!'),
                backgroundColor: AppConstants.successColor),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Gagal membuat pemesanan.'),
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
    } finally {
      if (mounted) {
        // Matikan loading state jika ada
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kos.namaKos),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Utama Kos
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
                image: DecorationImage(
                  image: (widget.kos.hasImage &&
                          widget.kos.fotoUtamaUrl != null)
                      ? NetworkImage(widget.kos.fotoUtamaUrl!)
                      : const AssetImage(AppConstants.imageAssetPlaceholderKos)
                          as ImageProvider,
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint(
                        'ERROR_DETAIL_IMAGE_LOAD: Gagal memuat gambar ${widget.kos.namaKos}: $exception');
                  },
                ),
              ),
              child: (!widget.kos.hasImage)
                  ? Icon(Icons.apartment,
                      size: 80,
                      color: AppConstants.primaryColor.withOpacity(0.7))
                  : null,
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Informasi Dasar Kos
            Text(
              widget.kos.namaKos,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 18, color: AppConstants.textColorSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.kos.alamat ?? '',
                    style: const TextStyle(
                        fontSize: 16, color: AppConstants.textColorSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Oleh: ${widget.kos.ownerName ?? widget.kos.ownerUsername}',
              style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppConstants.textColorSecondary),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Deskripsi Kos
            if (widget.kos.deskripsi != null &&
                widget.kos.deskripsi!.isNotEmpty) ...[
              const Text(
                'Deskripsi:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.kos.deskripsi!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],

            // Fasilitas Umum
            if (widget.kos.fasilitasUmum != null &&
                widget.kos.fasilitasUmum!.isNotEmpty) ...[
              const Text(
                'Fasilitas Umum:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.kos.fasilitasUmum!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],

            const Divider(),
            const SizedBox(height: AppConstants.defaultPadding),

            // Daftar Kamar Tersedia
            const Text(
              'Kamar Tersedia:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            FutureBuilder<List<KamarKos>>(
              future: _availableRoomsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error memuat kamar: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada kamar tersedia di kos ini.'),
                  );
                } else {
                  return Column(
                    children: snapshot.data!.map((kamar) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.defaultBorderRadius / 2)),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(AppConstants.defaultPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kamar.namaKamar,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  'Harga: Rp ${kamar.hargaSewa.toStringAsFixed(0)} / bulan'),
                              if (kamar.luasKamar != null &&
                                  kamar.luasKamar!.isNotEmpty)
                                Text('Ukuran: ${kamar.luasKamar}'),
                              if (kamar.fasilitas != null &&
                                  kamar.fasilitas!.isNotEmpty)
                                Text('Fasilitas: ${kamar.fasilitas}'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedKamar = kamar;
                                    _selectedTanggalMulai = null;
                                    _durasiSewa = 1;
                                  });
                                  _showBookingDialog(context);
                                },
                                icon: const Icon(Icons.book_online),
                                label: const Text('Pesan Kamar Ini'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.accentColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text('Pesan Kamar "${_selectedKamar!.namaKamar}"'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'Harga: Rp ${_selectedKamar!.hargaSewa.toStringAsFixed(0)} / bulan'),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_selectedTanggalMulai == null
                          ? 'Pilih Tanggal Mulai Sewa'
                          : 'Mulai: ${_selectedTanggalMulai!.toLocal().toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        await _selectDate(context);
                        setStateInDialog(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Durasi Sewa (bulan):'),
                        DropdownButton<int>(
                          value: _durasiSewa,
                          items: List.generate(12, (index) => index + 1)
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text('$e bulan')))
                              .toList(),
                          onChanged: (value) {
                            setStateInDialog(() {
                              _durasiSewa = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total Estimasi: Rp ${(_selectedKamar!.hargaSewa * _durasiSewa).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed:
                      _selectedTanggalMulai == null ? null : _createBooking,
                  child: const Text('Konfirmasi Pesanan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
