// lib/features/owner_dashboard/screens/incoming_bookings_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart'; // Import PemesananModel
import 'package:sewa_kos/core/services/pemesanan_service.dart'; // Import PemesananService

class IncomingBookingsScreen extends StatefulWidget {
  const IncomingBookingsScreen({super.key});

  @override
  State<IncomingBookingsScreen> createState() => _IncomingBookingsScreenState();
}

class _IncomingBookingsScreenState extends State<IncomingBookingsScreen> {
  final PemesananService _pemesananService = PemesananService();
  Future<List<Pemesanan>>? _incomingBookingsFuture;

  @override
  void initState() {
    super.initState();
    _fetchIncomingBookings();
  }

  // Fungsi untuk mengambil daftar pemesanan masuk
  Future<void> _fetchIncomingBookings() async {
    setState(() {
      // Panggil getListPemesanan, yang di sisi PHP akan memfilter untuk pemilik_kos
      _incomingBookingsFuture = _pemesananService.getListPemesanan();
    });
  }

  // Fungsi untuk navigasi ke detail pemesanan (opsional, bisa dibuat nanti)
  void _navigateToBookingDetail(Pemesanan pemesanan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Melihat detail pemesanan ${pemesanan.id} oleh ${pemesanan.tenantUsername}.')),
    );
    // TODO: Navigasi ke BookingDetailScreen jika ada
    // Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailScreen(pemesanan: pemesanan)));
  }

  // Fungsi untuk mengubah status pemesanan (misal: konfirmasi/tolak)
  Future<void> _updateBookingStatus(int pemesananId, String currentStatus, String newStatus) async {
    if (currentStatus == newStatus) return; // Tidak perlu update jika status sama

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ubah Status Pemesanan'),
          content: Text('Apakah Anda yakin ingin mengubah status pemesanan ini dari "$currentStatus" menjadi "$newStatus"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Ya', style: TextStyle(color: newStatus == 'dibatalkan' ? Colors.red : Colors.green)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mengubah status menjadi "$newStatus"...'), duration: Duration(seconds: 1)),
      );
      try {
        final response = await _pemesananService.updatePemesananStatus(
          pemesananId: pemesananId,
          newStatus: newStatus,
        );
        if (mounted) {
          if (response['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Status berhasil diubah.'), backgroundColor: AppConstants.successColor),
            );
            _fetchIncomingBookings(); // Refresh daftar
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Gagal mengubah status.'), backgroundColor: AppConstants.errorColor),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppConstants.errorColor),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemesanan Masuk'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Pemesanan>>(
        future: _incomingBookingsFuture,
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
                  const Icon(Icons.calendar_month, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'Tidak ada pemesanan masuk untuk kos Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchIncomingBookings, // Tombol refresh
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Tampilkan daftar pemesanan
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final pemesanan = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(
                      '${pemesanan.namaKamar ?? 'Kamar Tidak Dikenal'} di ${pemesanan.namaKos ?? 'Kos Tidak Dikenal'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Penyewa: ${pemesanan.tenantName ?? pemesanan.tenantUsername}'),
                        Text('Mulai Sewa: ${pemesanan.tanggalMulai.toLocal().toString().split(' ')[0]} (${pemesanan.durasiSewa} bulan)'),
                        Text('Total Harga: Rp ${pemesanan.totalHarga.toStringAsFixed(0)}'),
                        Text('Status: ${pemesanan.statusPemesanan.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(
                            color: _getStatusColor(pemesanan.statusPemesanan),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol konfirmasi jika status menunggu pembayaran
                        if (pemesanan.statusPemesanan == 'menunggu_pembayaran')
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _updateBookingStatus(
                                pemesanan.id, pemesanan.statusPemesanan, 'terkonfirmasi'),
                            tooltip: 'Konfirmasi Pemesanan',
                          ),
                        // Tombol batalkan jika status belum selesai/dibatalkan
                        if (pemesanan.statusPemesanan != 'dibatalkan' && pemesanan.statusPemesanan != 'selesai')
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _updateBookingStatus(
                                pemesanan.id, pemesanan.statusPemesanan, 'dibatalkan'),
                            tooltip: 'Batalkan Pemesanan',
                          ),
                      ],
                    ),
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

  // Helper untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return Colors.blue;
      case 'terkonfirmasi':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      case 'selesai':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}