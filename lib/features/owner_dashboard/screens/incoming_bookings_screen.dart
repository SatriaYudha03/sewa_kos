// lib/features/owner_dashboard/screens/incoming_bookings_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart'; // Import PemesananModel
import 'package:sewa_kos/core/models/pembayaran_model.dart'; // Import PembayaranModel
import 'package:sewa_kos/core/services/pemesanan_service.dart'; // Import PemesananService
import 'package:sewa_kos/core/services/pembayaran_service.dart'; // Import PembayaranService

class IncomingBookingsScreen extends StatefulWidget {
  const IncomingBookingsScreen({super.key});

  @override
  State<IncomingBookingsScreen> createState() => _IncomingBookingsScreenState();
}

class _IncomingBookingsScreenState extends State<IncomingBookingsScreen> {
  final PemesananService _pemesananService = PemesananService();
  final PembayaranService _pembayaranService = PembayaranService(); // Tambahkan PembayaranService
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
  }

  // Fungsi untuk mengubah status pemesanan (misal: konfirmasi/tolak)
  Future<void> _updateBookingStatus(int pemesananId, String currentStatus, String newStatus) async {
    if (currentStatus == newStatus) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ubah Status Pemesanan'),
          content: Text('Apakah Anda yakin ingin mengubah status pemesanan ini dari "${currentStatus.replaceAll('_', ' ')}" menjadi "${newStatus.replaceAll('_', ' ')}"?'),
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

  // Fungsi untuk menampilkan detail pembayaran dan opsi verifikasi
  Future<void> _showPaymentVerificationDialog(Pemesanan pemesanan) async {
    List<Pembayaran> payments = [];
    bool isLoadingPayments = true;

    // Ambil daftar pembayaran untuk pemesanan ini
    try {
      payments = await _pembayaranService.getPaymentsByPemesananId(pemesanan.id);
    } catch (e) {
      print('Error fetching payment details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail pembayaran: ${e.toString()}'), backgroundColor: AppConstants.errorColor),
        );
      }
    } finally {
      isLoadingPayments = false;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verifikasi Pembayaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pemesanan ID: ${pemesanan.id}'),
                Text('Penyewa: ${pemesanan.tenantName ?? pemesanan.tenantUsername}'),
                Text('Total Pesanan: Rp ${pemesanan.totalHarga.toStringAsFixed(0)}'),
                const Divider(),
                const Text('Riwayat Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                isLoadingPayments
                    ? const Center(child: CircularProgressIndicator())
                    : (payments.isEmpty
                        ? const Text('Belum ada bukti pembayaran diunggah.')
                        : Column(
                            children: payments.map((payment) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Jumlah: Rp ${payment.jumlahBayar.toStringAsFixed(0)}'),
                                      Text('Metode: ${payment.metodePembayaran ?? '-'}'),
                                      Text('Tanggal: ${payment.tanggalPembayaran.toLocal().toString().split(' ')[0]}'),
                                      Text('Status: ${payment.statusPembayaran.replaceAll('_', ' ').toUpperCase()}',
                                        style: TextStyle(
                                          color: _getStatusColor(payment.statusPembayaran),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (payment.buktiTransfer != null && payment.buktiTransfer!.isNotEmpty)
                                        Column(
                                          children: [
                                            const SizedBox(height: 8),
                                            Image.network(
                                              '${AppConstants.baseUrl}${payment.buktiTransfer!}', // URL lengkap gambar bukti
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(Icons.open_in_new),
                                              label: const Text('Lihat Gambar Penuh'),
                                              onPressed: () {
                                                // TODO: Buka gambar di browser atau viewer penuh
                                                // Misalnya menggunakan url_launcher
                                                // launchUrl(Uri.parse('${AppConstants.baseUrl}${payment.buktiTransfer!}'));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Fitur lihat gambar penuh akan segera hadir!')),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            // Tombol verifikasi hanya jika ada pembayaran yang menunggu verifikasi
            if (payments.any((p) => p.statusPembayaran == 'menunggu_verifikasi'))
              ElevatedButton(
                onPressed: () async {
                  // Temukan pembayaran yang 'menunggu_verifikasi'
                  final pendingPayment = payments.firstWhere((p) => p.statusPembayaran == 'menunggu_verifikasi');
                  await _verifyPaymentStatus(pendingPayment.id, 'terverifikasi');
                  if (mounted) Navigator.of(context).pop(); // Tutup dialog setelah verifikasi
                  _fetchIncomingBookings(); // Refresh daftar setelah verifikasi
                },
                child: const Text('Verifikasi Pembayaran', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.successColor),
              ),
            if (payments.any((p) => p.statusPembayaran == 'menunggu_verifikasi'))
              ElevatedButton(
                onPressed: () async {
                  final pendingPayment = payments.firstWhere((p) => p.statusPembayaran == 'menunggu_verifikasi');
                  await _verifyPaymentStatus(pendingPayment.id, 'gagal');
                  if (mounted) Navigator.of(context).pop();
                  _fetchIncomingBookings();
                },
                child: const Text('Tolak Pembayaran', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
              ),
          ],
        );
      },
    );
  }

  // Fungsi untuk memanggil PembayaranService.verifyPayment
  Future<void> _verifyPaymentStatus(int pembayaranId, String newStatus) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Memverifikasi pembayaran...'), duration: Duration(seconds: 1)),
    );
    try {
      final response = await _pembayaranService.verifyPayment(
        pembayaranId: pembayaranId,
        statusPembayaran: newStatus,
      );
      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Verifikasi berhasil.'), backgroundColor: AppConstants.successColor),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Verifikasi gagal.'), backgroundColor: AppConstants.errorColor),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 80, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'Error memuat daftar pemesanan: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchIncomingBookings,
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
                  const Icon(Icons.calendar_month, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'Tidak ada pemesanan masuk untuk kos Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchIncomingBookings,
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
                        const SizedBox(height: 4),
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
                        // Tombol Verifikasi Pembayaran (jika status memungkinkan)
                        if (pemesanan.statusPemesanan == 'menunggu_pembayaran' || pemesanan.statusPemesanan == 'menunggu_verifikasi')
                          IconButton(
                            icon: const Icon(Icons.payment, color: AppConstants.primaryColor),
                            onPressed: () => _showPaymentVerificationDialog(pemesanan),
                            tooltip: 'Verifikasi Pembayaran',
                          ),
                        // Tombol konfirmasi status pemesanan
                        if (pemesanan.statusPemesanan == 'menunggu_pembayaran')
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _updateBookingStatus(
                                pemesanan.id, pemesanan.statusPemesanan, 'terkonfirmasi'),
                            tooltip: 'Konfirmasi Pemesanan (Tanpa Verifikasi Pembayaran)',
                          ),
                        // Tombol batalkan jika status belum selesai/dibatalkan
                        if (pemesanan.statusPemesanan != 'dibatalkan' && pemesanan.statusPemesanan != 'selesai')
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _updateBookingStatus(
                                pemesanan.id, pemesanan.statusPemesanan, 'dibatalkan'),
                            tooltip: 'Batalkan Pemesanan',
                          ),
                        // Tombol Selesai jika status terkonfirmasi
                        if (pemesanan.statusPemesanan == 'terkonfirmasi')
                          IconButton(
                            icon: const Icon(Icons.done_all, color: Colors.blueGrey),
                            onPressed: () => _updateBookingStatus(
                                pemesanan.id, pemesanan.statusPemesanan, 'selesai'),
                            tooltip: 'Tandai Selesai',
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
        return Colors.orange;
      case 'menunggu_verifikasi':
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