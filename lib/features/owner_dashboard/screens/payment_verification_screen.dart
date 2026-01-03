/// Halaman untuk verifikasi pembayaran (untuk pemilik kos)
library;

import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
import 'package:sewa_kos/core/models/pembayaran_model.dart';
import 'package:sewa_kos/core/services/pembayaran_service.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final Pemesanan pemesanan;

  const PaymentVerificationScreen({
    super.key,
    required this.pemesanan,
  });

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  final PembayaranService _pembayaranService = PembayaranService();
  List<Pembayaran> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payments = await _pembayaranService
          .getPaymentsByPemesananId(widget.pemesanan.id);
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat detail pembayaran: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyPayment(
      int pembayaranId, StatusPembayaran newStatus) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(newStatus == StatusPembayaran.terverifikasi
              ? 'Verifikasi Pembayaran'
              : 'Tolak Pembayaran'),
          content: Text(
            newStatus == StatusPembayaran.terverifikasi
                ? 'Apakah Anda yakin ingin memverifikasi pembayaran ini?'
                : 'Apakah Anda yakin ingin menolak pembayaran ini?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Ya',
                style: TextStyle(
                  color: newStatus == StatusPembayaran.terverifikasi
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _pembayaranService.verifyPayment(
          pembayaranId: pembayaranId,
          status: newStatus,
        );

        if (!mounted) return;

        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Verifikasi berhasil.'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          // Kembali ke halaman sebelumnya dengan hasil
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Verifikasi gagal.'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _viewFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
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

  IconData _getPaymentStatusIcon(StatusPembayaran status) {
    switch (status) {
      case StatusPembayaran.menungguVerifikasi:
        return Icons.hourglass_empty;
      case StatusPembayaran.terverifikasi:
        return Icons.check_circle;
      case StatusPembayaran.gagal:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPendingPayment = _payments
        .any((p) => p.statusPembayaran == StatusPembayaran.menungguVerifikasi);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pembayaran'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 80, color: Colors.red),
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadPayments,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informasi Pemesanan
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informasi Pemesanan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow(
                                  'ID Pemesanan', '#${widget.pemesanan.id}'),
                              _buildInfoRow(
                                'Penyewa',
                                widget.pemesanan.tenantName ??
                                    widget.pemesanan.tenantUsername ??
                                    'N/A',
                              ),
                              _buildInfoRow(
                                'Kamar',
                                '${widget.pemesanan.namaKamar ?? 'N/A'} - ${widget.pemesanan.namaKos ?? 'N/A'}',
                              ),
                              _buildInfoRow(
                                'Durasi Sewa',
                                '${widget.pemesanan.durasiSewa} bulan',
                              ),
                              _buildInfoRow(
                                'Tanggal Mulai',
                                widget.pemesanan.tanggalMulai
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0],
                              ),
                              _buildInfoRow(
                                'Total Harga',
                                'Rp ${widget.pemesanan.totalHarga.toStringAsFixed(0)}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Riwayat Pembayaran
                      const Text(
                        'Riwayat Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _payments.isEmpty
                          ? Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 60,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Belum ada bukti pembayaran yang diunggah',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: _payments
                                  .map((payment) => _buildPaymentCard(payment))
                                  .toList(),
                            ),
                    ],
                  ),
                ),
      bottomNavigationBar: hasPendingPayment && !_isLoading
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final pendingPayment = _payments.firstWhere((p) =>
                            p.statusPembayaran ==
                            StatusPembayaran.menungguVerifikasi);
                        _verifyPayment(
                            pendingPayment.id, StatusPembayaran.gagal);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final pendingPayment = _payments.firstWhere((p) =>
                            p.statusPembayaran ==
                            StatusPembayaran.menungguVerifikasi);
                        _verifyPayment(
                            pendingPayment.id, StatusPembayaran.terverifikasi);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Verifikasi Pembayaran',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Pembayaran payment) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Icon(
                  _getPaymentStatusIcon(payment.statusPembayaran),
                  color: _getPaymentStatusColor(payment.statusPembayaran),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  payment.statusPembayaran.displayName,
                  style: TextStyle(
                    color: _getPaymentStatusColor(payment.statusPembayaran),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Informasi Pembayaran
            _buildInfoRow(
              'Jumlah Bayar',
              'Rp ${payment.jumlahBayar.toStringAsFixed(0)}',
              isBold: true,
            ),
            _buildInfoRow(
              'Metode',
              payment.metodePembayaran ?? '-',
            ),
            _buildInfoRow(
              'Tanggal',
              payment.tanggalPembayaran != null
                  ? payment.tanggalPembayaran!
                      .toLocal()
                      .toString()
                      .split(' ')[0]
                  : '-',
            ),
            if (payment.jenisPembayaran != null)
              _buildInfoRow(
                'Jenis',
                payment.jenisPembayaran!,
              ),

            // Bukti Transfer
            if (payment.hasBuktiTransfer) ...[
              const SizedBox(height: 12),
              const Text(
                'Bukti Transfer:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _viewFullImage(payment.buktiTransferUrl!),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          payment.buktiTransferUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                        // Overlay untuk indikasi tap
                        Container(
                          color: Colors.black.withValues(alpha: 0.1),
                          child: const Center(
                            child: Icon(
                              Icons.zoom_in,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.fullscreen),
                label: const Text('Lihat Gambar Penuh'),
                onPressed: () => _viewFullImage(payment.buktiTransferUrl!),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan gambar dalam ukuran penuh
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  bool _showAppBar = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text('Bukti Pembayaran'),
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showAppBar = !_showAppBar;
          });
        },
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Gagal memuat gambar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
