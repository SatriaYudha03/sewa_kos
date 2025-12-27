/// Layar untuk melihat riwayat pemesanan penyewa
library;

import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
import 'package:sewa_kos/core/services/pemesanan_service.dart';
import 'package:sewa_kos/features/tenant_dashboard/screens/upload_payment_proof_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final PemesananService _pemesananService = PemesananService();
  Future<List<Pemesanan>>? _bookingHistoryFuture;

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
  }

  Future<void> _fetchBookingHistory() async {
    setState(() {
      _bookingHistoryFuture = _pemesananService.getMyPemesanan();
    });
  }

  void _navigateToBookingDetail(Pemesanan pemesanan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Melihat detail pemesanan ${pemesanan.id} di ${pemesanan.namaKos}.')),
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
              'Status: ${pemesanan.statusPemesanan.displayName}',
              style: TextStyle(
                color: _getStatusColor(pemesanan.statusPemesanan),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: (pemesanan.statusPemesanan ==
                StatusPemesanan.menungguPembayaran)
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
}
