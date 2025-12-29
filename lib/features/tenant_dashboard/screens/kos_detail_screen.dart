// lib/features/tenant_dashboard/screens/kos_detail_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/kos_model.dart';
import 'package:sewa_kos/core/models/kamar_kos_model.dart';
import 'package:sewa_kos/core/services/kamar_service.dart';
import 'package:sewa_kos/core/services/pembayaran_service.dart';
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
  final PembayaranService _pembayaranService = PembayaranService();
  final ImagePicker _imagePicker = ImagePicker();
  Future<List<KamarKos>>? _availableRoomsFuture;

  KamarKos? _selectedKamar;
  DateTime? _selectedTanggalMulai;
  int _durasiSewa = 1;
  
  // State untuk upload bukti pembayaran
  XFile? _buktiPembayaranFile;
  Uint8List? _buktiPembayaranBytes;
  bool _uploadBuktiSekarang = false;
  String _metodePembayaran = 'Transfer Bank';
  bool _isLoading = false;

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

  Future<void> _pickBuktiPembayaran() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _buktiPembayaranFile = pickedFile;
          _buktiPembayaranBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _clearBuktiPembayaran() {
    setState(() {
      _buktiPembayaranFile = null;
      _buktiPembayaranBytes = null;
    });
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
    
    // Validasi bukti pembayaran jika user memilih upload sekarang
    if (_uploadBuktiSekarang && _buktiPembayaranFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan upload bukti pembayaran terlebih dahulu.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Buat pemesanan terlebih dahulu
      final response = await _pemesananService.createPemesanan(
        kamarId: _selectedKamar!.id,
        tanggalMulai: _selectedTanggalMulai!,
        durasiSewa: _durasiSewa,
      );

      if (mounted) {
        if (response['status'] == 'success') {
          final pemesananId = response['data']?.id;
          
          // Jika user memilih upload bukti sekarang, upload bukti pembayaran
          if (_uploadBuktiSekarang && _buktiPembayaranFile != null && pemesananId != null) {
            final totalHarga = _selectedKamar!.hargaSewa * _durasiSewa;
            final uploadResponse = await _pembayaranService.uploadPaymentProof(
              pemesananId: pemesananId,
              jumlahBayar: totalHarga,
              metodePembayaran: _metodePembayaran,
              buktiPembayaranFile: _buktiPembayaranFile!,
              buktiPembayaranBytes: _buktiPembayaranBytes,
              jenisPembayaran: 'Pembayaran Awal',
            );
            
            if (uploadResponse['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pemesanan & bukti pembayaran berhasil diupload! Menunggu verifikasi.'),
                  backgroundColor: AppConstants.successColor,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pemesanan berhasil, tapi gagal upload bukti: ${uploadResponse['message']}'),
                  backgroundColor: AppConstants.warningColor,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Pemesanan berhasil dibuat!'),
                backgroundColor: AppConstants.successColor,
              ),
            );
          }
          
          // Reset state
          _clearBuktiPembayaran();
          _uploadBuktiSekarang = false;
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal membuat pemesanan.'),
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
            backgroundColor: AppConstants.errorColor,
          ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            final totalHarga = _selectedKamar!.hargaSewa * _durasiSewa;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header dengan icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bed_rounded,
                              color: AppConstants.primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pesan Kamar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppConstants.textColorSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedKamar!.namaKamar,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textColorPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Harga per bulan
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppConstants.primaryColor.withOpacity(0.1),
                              AppConstants.accentColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Harga per bulan',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppConstants.textColorSecondary,
                              ),
                            ),
                            Text(
                              'Rp ${_formatCurrency(_selectedKamar!.hargaSewa)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Pilih Tanggal
                      const Text(
                        'Tanggal Mulai Sewa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _uploadBuktiSekarang
                            ? null
                            : () async {
                                await _selectDate(context);
                                setStateInDialog(() {});
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _uploadBuktiSekarang ? Colors.grey[100] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedTanggalMulai == null
                                  ? Colors.grey[300]!
                                  : AppConstants.successColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedTanggalMulai == null
                                      ? Colors.grey[200]
                                      : AppConstants.successColor
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: _selectedTanggalMulai == null
                                      ? Colors.grey[600]
                                      : AppConstants.successColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedTanggalMulai == null
                                      ? 'Pilih tanggal mulai sewa'
                                      : _formatDate(_selectedTanggalMulai!),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _selectedTanggalMulai == null
                                        ? Colors.grey[600]
                                        : AppConstants.textColorPrimary,
                                    fontWeight: _selectedTanggalMulai == null
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Durasi Sewa
                      const Text(
                        'Durasi Sewa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppConstants.accentColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.access_time_rounded,
                                    color: AppConstants.accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Lama sewa',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppConstants.textColorSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _uploadBuktiSekarang
                                    ? Colors.grey[200]
                                    : AppConstants.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _durasiSewa,
                                  isDense: true,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: _uploadBuktiSekarang
                                        ? Colors.grey[400]
                                        : AppConstants.primaryColor,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _uploadBuktiSekarang
                                        ? Colors.grey[500]
                                        : AppConstants.primaryColor,
                                  ),
                                  items: List.generate(12, (index) => index + 1)
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text('$e bulan'),
                                          ))
                                      .toList(),
                                  onChanged: _uploadBuktiSekarang
                                      ? null
                                      : (value) {
                                          setStateInDialog(() {
                                            _durasiSewa = value!;
                                          });
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Total Estimasi
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.accentColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Estimasi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_durasiSewa bulan',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rp ${_formatCurrency(totalHarga)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Opsi Upload Bukti Pembayaran
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppConstants.successColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppConstants.successColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Upload Bukti Pembayaran',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.textColorPrimary,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _uploadBuktiSekarang,
                                  onChanged: (value) {
                                    setStateInDialog(() {
                                      _uploadBuktiSekarang = value;
                                      if (!value) {
                                        _clearBuktiPembayaran();
                                      }
                                    });
                                  },
                                  activeColor: AppConstants.successColor,
                                ),
                              ],
                            ),
                            if (_uploadBuktiSekarang) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppConstants.warningColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppConstants.warningColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: AppConstants.warningColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Tanggal dan durasi sewa tidak dapat diubah saat mode pembayaran aktif',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppConstants.textColorSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Upload bukti pembayaran sekarang untuk mempercepat proses verifikasi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textColorSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Metode Pembayaran
                              const Text(
                                'Metode Pembayaran',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.textColorPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _metodePembayaran,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppConstants.primaryColor,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppConstants.textColorPrimary,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Transfer Bank',
                                        child: Text('Transfer Bank'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'E-Wallet',
                                        child: Text('E-Wallet (GoPay, OVO, dll)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'QRIS',
                                        child: Text('QRIS'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setStateInDialog(() {
                                        _metodePembayaran = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Upload Bukti
                              const Text(
                                'Bukti Transfer',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.textColorPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_buktiPembayaranBytes != null)
                                Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppConstants.successColor
                                              .withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.memory(
                                          _buktiPembayaranBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setStateInDialog(() {
                                            _clearBuktiPembayaran();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppConstants.errorColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppConstants.successColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Siap diupload',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                InkWell(
                                  onTap: () async {
                                    await _pickBuktiPembayaran();
                                    setStateInDialog(() {});
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryColor
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.cloud_upload_rounded,
                                            color: AppConstants.primaryColor,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Tap untuk pilih gambar',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppConstants.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'JPG, PNG (Max. 5MB)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tombol Action
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textColorSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: (_selectedTanggalMulai == null || _isLoading || (_uploadBuktiSekarang && _buktiPembayaranFile == null))
                                  ? null
                                  : () {
                                      setStateInDialog(() {});
                                      _createBooking();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _uploadBuktiSekarang 
                                    ? AppConstants.successColor 
                                    : AppConstants.primaryColor,
                                disabledBackgroundColor: Colors.grey[300],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _uploadBuktiSekarang 
                                              ? Icons.payment_rounded
                                              : Icons.check_circle_outline_rounded,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _uploadBuktiSekarang 
                                              ? 'Pesan & Bayar'
                                              : 'Konfirmasi Pesanan',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
