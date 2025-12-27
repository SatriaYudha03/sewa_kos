/// Layar untuk melihat dan mengelola pemesanan masuk (untuk pemilik kos)
library;

import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
import 'package:sewa_kos/core/models/pembayaran_model.dart';
import 'package:sewa_kos/core/services/pemesanan_service.dart';
import 'package:sewa_kos/core/services/pembayaran_service.dart';

class IncomingBookingsScreen extends StatefulWidget {
  const IncomingBookingsScreen({super.key});

  @override
  State<IncomingBookingsScreen> createState() => _IncomingBookingsScreenState();
}

class _IncomingBookingsScreenState extends State<IncomingBookingsScreen> {
  final PemesananService _pemesananService = PemesananService();
  final PembayaranService _pembayaranService = PembayaranService();
  Future<List<Pemesanan>>? _incomingBookingsFuture;

  @override
  void initState() {
    super.initState();
    _fetchIncomingBookings();
  }

  Future<void> _fetchIncomingBookings() async {
    setState(() {
      _incomingBookingsFuture = _pemesananService.getIncomingPemesanan();
    });
  }

  void _navigateToBookingDetail(Pemesanan pemesanan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Melihat detail pemesanan ${pemesanan.id} oleh ${pemesanan.tenantUsername}')),
    );
  }

  Future<void> _updateBookingStatus(int pemesananId,
      StatusPemesanan currentStatus, StatusPemesanan newStatus) async {
    if (currentStatus == newStatus) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubah Status Pemesanan'),
          content: Text(
              'Apakah Anda yakin ingin mengubah status pemesanan ini dari "${currentStatus.displayName}" menjadi "${newStatus.displayName}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Ya',
                  style: TextStyle(
                      color: newStatus == StatusPemesanan.dibatalkan
                          ? Colors.red
                          : Colors.green)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Mengubah status menjadi "${newStatus.displayName}"...'),
            duration: const Duration(seconds: 1)),
      );
      try {
        final response = await _pemesananService.updatePemesananStatus(
          pemesananId: pemesananId,
          newStatus: newStatus,
        );
        if (mounted) {
          if (response['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(response['message'] ?? 'Status berhasil diubah.'),
                  backgroundColor: AppConstants.successColor),
            );
            _fetchIncomingBookings();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(response['message'] ?? 'Gagal mengubah status.'),
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
      }
    }
  }

  /// Menampilkan dialog verifikasi pembayaran
  Future<void> _showPaymentVerificationDialog(Pemesanan pemesanan) async {
    List<Pembayaran> payments = [];
    bool isLoadingPayments = true;

    try {
      payments =
          await _pembayaranService.getPaymentsByPemesananId(pemesanan.id);
    } catch (e) {
      debugPrint('Error fetching payment details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat detail pembayaran: ${e.toString()}'),
              backgroundColor: AppConstants.errorColor),
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
                Text(
                    'Penyewa: ${pemesanan.tenantName ?? pemesanan.tenantUsername}'),
                Text(
                    'Total Pesanan: Rp ${pemesanan.totalHarga.toStringAsFixed(0)}'),
                const Divider(),
                const Text('Riwayat Pembayaran:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                isLoadingPayments
                    ? const Center(child: CircularProgressIndicator())
                    : (payments.isEmpty
                        ? const Text('Belum ada bukti pembayaran diunggah.')
                        : Column(
                            children: payments.map((payment) {
                              return _buildPaymentCard(payment);
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
            if (payments.any((p) =>
                p.statusPembayaran == StatusPembayaran.menungguVerifikasi))
              ElevatedButton(
                onPressed: () async {
                  final pendingPayment = payments.firstWhere((p) =>
                      p.statusPembayaran ==
                      StatusPembayaran.menungguVerifikasi);
                  await _verifyPaymentStatus(
                      pendingPayment.id, StatusPembayaran.terverifikasi);
                  if (mounted) Navigator.of(context).pop();
                  _fetchIncomingBookings();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.successColor),
                child: const Text('Verifikasi Pembayaran',
                    style: TextStyle(color: Colors.white)),
              ),
            if (payments.any((p) =>
                p.statusPembayaran == StatusPembayaran.menungguVerifikasi))
              ElevatedButton(
                onPressed: () async {
                  final pendingPayment = payments.firstWhere((p) =>
                      p.statusPembayaran ==
                      StatusPembayaran.menungguVerifikasi);
                  await _verifyPaymentStatus(
                      pendingPayment.id, StatusPembayaran.gagal);
                  if (mounted) Navigator.of(context).pop();
                  _fetchIncomingBookings();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.errorColor),
                child: const Text('Tolak Pembayaran',
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard(Pembayaran payment) {
    Widget imageWidget;
    if (payment.hasBuktiTransfer && payment.buktiTransferUrl != null) {
      imageWidget = Image.network(
        payment.buktiTransferUrl!,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 50),
      );
    } else {
      imageWidget = const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah: Rp ${payment.jumlahBayar.toStringAsFixed(0)}'),
            Text('Metode: ${payment.metodePembayaran ?? '-'}'),
            Text(
                'Tanggal: ${payment.tanggalPembayaran?.toLocal().toString().split(' ')[0] ?? '-'}'),
            Text(
              'Status: ${payment.statusPembayaran.displayName}',
              style: TextStyle(
                color: _getPaymentStatusColor(payment.statusPembayaran),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (payment.hasBuktiTransfer) ...[
              const SizedBox(height: 8),
              imageWidget,
              TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Lihat Gambar Penuh'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Fitur lihat gambar penuh akan segera hadir!')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _verifyPaymentStatus(
      int pembayaranId, StatusPembayaran newStatus) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Memverifikasi pembayaran...'),
          duration: Duration(seconds: 1)),
    );
    try {
      final response = await _pembayaranService.verifyPayment(
        pembayaranId: pembayaranId,
        status: newStatus,
      );
      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Verifikasi berhasil.'),
                backgroundColor: AppConstants.successColor),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Verifikasi gagal.'),
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
                  const Icon(Icons.error, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Error memuat daftar pemesanan: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
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
                  const Icon(Icons.calendar_month,
                      size: 80, color: Colors.grey),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          '${pemesanan.namaKamar ?? 'Kamar Tidak Dikenal'} di ${pemesanan.namaKos ?? 'Kos Tidak Dikenal'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Penyewa: ${pemesanan.tenantName ?? pemesanan.tenantUsername}'),
            Text(
                'Mulai Sewa: ${pemesanan.tanggalMulai.toLocal().toString().split(' ')[0]} (${pemesanan.durasiSewa} bulan)'),
            Text('Total Harga: Rp ${pemesanan.totalHarga.toStringAsFixed(0)}'),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pemesanan.statusPemesanan == StatusPemesanan.menungguPembayaran)
              IconButton(
                icon:
                    const Icon(Icons.payment, color: AppConstants.primaryColor),
                onPressed: () => _showPaymentVerificationDialog(pemesanan),
                tooltip: 'Verifikasi Pembayaran',
              ),
            if (pemesanan.statusPemesanan == StatusPemesanan.menungguPembayaran)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _updateBookingStatus(pemesanan.id,
                    pemesanan.statusPemesanan, StatusPemesanan.terkonfirmasi),
                tooltip: 'Konfirmasi Pemesanan',
              ),
            if (pemesanan.statusPemesanan != StatusPemesanan.dibatalkan &&
                pemesanan.statusPemesanan != StatusPemesanan.selesai)
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _updateBookingStatus(pemesanan.id,
                    pemesanan.statusPemesanan, StatusPemesanan.dibatalkan),
                tooltip: 'Batalkan Pemesanan',
              ),
            if (pemesanan.statusPemesanan == StatusPemesanan.terkonfirmasi)
              IconButton(
                icon: const Icon(Icons.done_all, color: Colors.blueGrey),
                onPressed: () => _updateBookingStatus(pemesanan.id,
                    pemesanan.statusPemesanan, StatusPemesanan.selesai),
                tooltip: 'Tandai Selesai',
              ),
          ],
        ),
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
