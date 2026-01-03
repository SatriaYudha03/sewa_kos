/// Layar untuk melihat riwayat pemesanan penyewa
library;

import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
import 'package:sewa_kos/core/models/pembayaran_model.dart';
import 'package:sewa_kos/core/services/pemesanan_service.dart';
import 'package:sewa_kos/core/services/pembayaran_service.dart';
import 'package:sewa_kos/features/tenant_dashboard/screens/upload_payment_proof_screen.dart';
import 'package:sewa_kos/features/tenant_dashboard/screens/booking_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final PemesananService _pemesananService = PemesananService();
  final PembayaranService _pembayaranService = PembayaranService();
  Future<List<Pemesanan>>? _bookingHistoryFuture;
  Map<int, List<Pembayaran>> _pembayaranMap =
      {}; // Map pemesananId -> List<Pembayaran>

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
  }

  Future<void> _fetchBookingHistory() async {
    setState(() {
      _bookingHistoryFuture = _pemesananService.getMyPemesanan();
    });

    // Load pembayaran untuk setiap pemesanan
    final bookings = await _bookingHistoryFuture;
    if (bookings != null) {
      for (var booking in bookings) {
        final pembayaranList =
            await _pembayaranService.getPaymentsByPemesananId(booking.id);
        _pembayaranMap[booking.id] = pembayaranList;
      }
      if (mounted) {
        setState(() {}); // Refresh untuk update status
      }
    }
  }

  void _navigateToBookingDetail(Pemesanan pemesanan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailScreen(
          pemesanan: pemesanan,
          onRefresh: _fetchBookingHistory,
        ),
      ),
    );
  }

  void _navigateToUploadProofScreen(Pemesanan pemesanan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadPaymentProofScreen(
          pemesanan: pemesanan,
          onProofUploaded: () {
            _fetchBookingHistory();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pemesanan'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookingHistory,
            tooltip: 'Refresh Riwayat Pemesanan',
          ),
        ],
      ),
      body: FutureBuilder<List<Pemesanan>>(
        future: _bookingHistoryFuture,
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
                    'Error memuat riwayat pemesanan: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchBookingHistory,
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
                  const Icon(Icons.bookmark_border,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'Anda belum memiliki riwayat pemesanan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchBookingHistory,
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
                final pemesanan = snapshot.data![index];
                return _buildPemesananCard(pemesanan);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildPemesananCard(Pemesanan pemesanan) {
    // Tentukan status yang akan ditampilkan
    String statusText;
    Color statusColor;
    bool showPaymentButton = false;

    // Ambil pembayaran jika ada
    final pembayaranList = _pembayaranMap[pemesanan.id] ?? [];

    if (pemesanan.statusPemesanan == StatusPemesanan.menungguPembayaran &&
        pembayaranList.isNotEmpty) {
      // Jika ada pembayaran, gunakan status pembayaran
      final pembayaran = pembayaranList.first;
      statusText = pembayaran.statusPembayaran.displayName;
      statusColor = _getPaymentStatusColor(pembayaran.statusPembayaran);
      // Tidak tampilkan tombol payment jika sudah ada bukti
      showPaymentButton = false;
    } else if (pemesanan.statusPemesanan ==
        StatusPemesanan.menungguPembayaran) {
      // Belum ada pembayaran
      statusText = pemesanan.statusPemesanan.displayName;
      statusColor = _getStatusColor(pemesanan.statusPemesanan);
      showPaymentButton = true;
    } else {
      // Status lainnya (terkonfirmasi, dibatalkan, selesai)
      statusText = pemesanan.statusPemesanan.displayName;
      statusColor = _getStatusColor(pemesanan.statusPemesanan);
      showPaymentButton = false;
    }

    return Card(
      margin:
          const EdgeInsets.symmetric(vertical: AppConstants.defaultMargin / 2),
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.defaultBorderRadius / 2)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
        title: Text(
          '${pemesanan.namaKamar ?? 'Kamar Tidak Dikenal'} di ${pemesanan.namaKos ?? 'Kos Tidak Dikenal'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Oleh: ${pemesanan.ownerName ?? pemesanan.ownerUsername}'),
            Text(
                'Mulai Sewa: ${pemesanan.tanggalMulai.toLocal().toString().split(' ')[0]}'),
            Text('Durasi: ${pemesanan.durasiSewa} bulan'),
            Text('Total: Rp ${pemesanan.totalHarga.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            Text(
              'Status: $statusText',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: showPaymentButton
            ? IconButton(
                icon:
                    const Icon(Icons.payment, color: AppConstants.accentColor),
                onPressed: () {
                  _navigateToUploadProofScreen(pemesanan);
                },
                tooltip: 'Upload Bukti Pembayaran',
              )
            : null,
        onTap: () => _navigateToBookingDetail(pemesanan),
      ),
    );
  }

  Color _getStatusColor(StatusPemesanan status) {
    switch (status) {
      case StatusPemesanan.menungguPembayaran:
        return Colors.orange;
      case StatusPemesanan.terkonfirmasi:
        return Colors.green;
      case StatusPemesanan.dibatalkan:
        return Colors.red;
      case StatusPemesanan.selesai:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(StatusPembayaran status) {
    switch (status) {
      case StatusPembayaran.menungguVerifikasi:
        return Colors.orange;
      case StatusPembayaran.terverifikasi:
        return Colors.green;
      case StatusPembayaran.gagal:
        return Colors.red;
    }
  }
}
