// lib/features/tenant_dashboard/screens/booking_history_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
import 'package:sewa_kos/core/services/pemesanan_service.dart';
import 'package:sewa_kos/features/tenant_dashboard/screens/upload_payment_proof_screen.dart'; // Import layar baru

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
      _bookingHistoryFuture = _pemesananService.getListPemesanan();
    });
  }

  void _navigateToBookingDetail(Pemesanan pemesanan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Melihat detail pemesanan ${pemesanan.id} di ${pemesanan.namaKos}.')),
    );
    // TODO: Navigasi ke BookingDetailScreen jika ada, atau PaymentDetailScreen
  }

  // Fungsi baru untuk navigasi ke layar upload bukti pembayaran
  void _navigateToUploadProofScreen(Pemesanan pemesanan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadPaymentProofScreen(
          pemesanan: pemesanan,
          onProofUploaded: () {
            _fetchBookingHistory(); // Refresh daftar setelah upload berhasil
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
                  Icon(Icons.error, size: 80, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'Error memuat riwayat pemesanan: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  SizedBox(height: 20),
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
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Anda belum memiliki riwayat pemesanan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 20),
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
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: AppConstants.defaultMargin / 2),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius / 2)),
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
                        Text('Mulai Sewa: ${pemesanan.tanggalMulai.toLocal().toString().split(' ')[0]}'),
                        Text('Durasi: ${pemesanan.durasiSewa} bulan'),
                        Text('Total: Rp ${pemesanan.totalHarga.toStringAsFixed(0)}'),
                        const SizedBox(height: 4),
                        Text('Status: ${pemesanan.statusPemesanan.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(
                            color: _getStatusColor(pemesanan.statusPemesanan),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: (pemesanan.statusPemesanan == 'menunggu_pembayaran')
                        ? IconButton(
                            icon: const Icon(Icons.payment, color: AppConstants.accentColor),
                            onPressed: () {
                              _navigateToUploadProofScreen(pemesanan); // Panggil fungsi navigasi baru
                            },
                            tooltip: 'Upload Bukti Pembayaran',
                          )
                        : null,
                    onTap: () => _navigateToBookingDetail(pemesanan),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return Colors.orange;
      case 'terkonfirmasi':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      case 'selesai':
        return Colors.grey;
      case 'menunggu_verifikasi': // Tambahkan status ini
        return Colors.blue; // Warna untuk status menunggu verifikasi
      default:
        return Colors.black;
    }
  }
}