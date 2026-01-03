/// Halaman Detail Pemesanan untuk Penyewa
///
/// Menampilkan informasi lengkap tentang pemesanan kamar kos
library;

import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
import 'package:sewa_kos/core/models/pembayaran_model.dart';
import 'package:sewa_kos/core/services/pembayaran_service.dart';
import 'package:sewa_kos/features/tenant_dashboard/screens/upload_payment_proof_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class BookingDetailScreen extends StatefulWidget {
  final Pemesanan pemesanan;
  final VoidCallback? onRefresh;

  const BookingDetailScreen({
    super.key,
    required this.pemesanan,
    this.onRefresh,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isLocaleInitialized = false;
  final PembayaranService _pembayaranService = PembayaranService();
  List<Pembayaran> _pembayaranList = [];
  bool _isLoadingPembayaran = true;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadPembayaran();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    if (mounted) {
      setState(() {
        _isLocaleInitialized = true;
      });
    }
  }

  Future<void> _loadPembayaran() async {
    setState(() {
      _isLoadingPembayaran = true;
    });

    try {
      final pembayaranList = await _pembayaranService
          .getPaymentsByPemesananId(widget.pemesanan.id);
      if (mounted) {
        setState(() {
          _pembayaranList = pembayaranList;
          _isLoadingPembayaran = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPembayaran = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Pemesanan'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pemesanan'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Status
            _buildStatusHeader(context),

            // Informasi Kos dan Kamar
            _buildSection(
              context,
              title: 'Informasi Kamar',
              children: [
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Nama Kos',
                  value: widget.pemesanan.namaKos ?? 'Tidak tersedia',
                ),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Alamat',
                  value: widget.pemesanan.alamatKos ?? 'Tidak tersedia',
                ),
                _buildInfoRow(
                  icon: Icons.hotel,
                  label: 'Tipe Kamar',
                  value: widget.pemesanan.namaKamar ?? 'Tidak tersedia',
                ),
                _buildInfoRow(
                  icon: Icons.attach_money,
                  label: 'Harga Sewa/Bulan',
                  value: widget.pemesanan.hargaSewaKamar != null
                      ? _formatCurrency(widget.pemesanan.hargaSewaKamar!)
                      : 'Tidak tersedia',
                ),
              ],
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // Informasi Pemilik
            _buildSection(
              context,
              title: 'Informasi Pemilik Kos',
              children: [
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Nama',
                  value: widget.pemesanan.ownerName ?? 'Tidak tersedia',
                ),
                _buildInfoRow(
                  icon: Icons.account_circle,
                  label: 'Username',
                  value: widget.pemesanan.ownerUsername ?? 'Tidak tersedia',
                ),
              ],
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // Detail Pemesanan
            _buildSection(
              context,
              title: 'Detail Pemesanan',
              children: [
                _buildInfoRow(
                  icon: Icons.confirmation_number,
                  label: 'ID Pemesanan',
                  value: '#${widget.pemesanan.id}',
                ),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Tanggal Mulai',
                  value: _formatDate(widget.pemesanan.tanggalMulai),
                ),
                _buildInfoRow(
                  icon: Icons.calendar_month,
                  label: 'Durasi Sewa',
                  value: '${widget.pemesanan.durasiSewa} Bulan',
                ),
                _buildInfoRow(
                  icon: Icons.event,
                  label: 'Tanggal Selesai',
                  value: _formatDate(widget.pemesanan.tanggalSelesai),
                ),
                _buildInfoRow(
                  icon: Icons.payments,
                  label: 'Total Pembayaran',
                  value: _formatCurrency(widget.pemesanan.totalHarga),
                  isHighlight: true,
                ),
              ],
            ),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // Detail Pembayaran
            _buildPaymentSection(context),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // Informasi Tambahan
            _buildSection(
              context,
              title: 'Informasi Tambahan',
              children: [
                if (widget.pemesanan.createdAt != null)
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'Tanggal Pemesanan',
                    value: _formatDateTime(widget.pemesanan.createdAt!),
                  ),
                if (widget.pemesanan.updatedAt != null)
                  _buildInfoRow(
                    icon: Icons.update,
                    label: 'Terakhir Diperbarui',
                    value: _formatDateTime(widget.pemesanan.updatedAt!),
                  ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    // Gunakan status pembayaran jika ada dan pemesanan masih menunggu pembayaran
    String statusText;
    Color statusColor;
    IconData statusIcon;
    String statusDescription;

    if (widget.pemesanan.statusPemesanan ==
            StatusPemesanan.menungguPembayaran &&
        _pembayaranList.isNotEmpty) {
      // Jika ada pembayaran, gunakan status pembayaran
      final pembayaran = _pembayaranList.first;
      statusText = 'Status: ${pembayaran.statusPembayaran.displayName}';
      statusColor = _getPaymentStatusColor(pembayaran.statusPembayaran);
      statusIcon = _getPaymentStatusIcon(pembayaran.statusPembayaran);
      statusDescription =
          _getPaymentStatusDescription(pembayaran.statusPembayaran);
    } else {
      // Gunakan status pemesanan
      statusText = 'Status: ${widget.pemesanan.statusPemesanan.displayName}';
      statusColor = _getStatusColor(widget.pemesanan.statusPemesanan);
      statusIcon = _getStatusIcon(widget.pemesanan.statusPemesanan);
      statusDescription =
          _getStatusDescription(widget.pemesanan.statusPemesanan);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding * 1.5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 26),
        border: Border(
          bottom: BorderSide(
            color: statusColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 60,
            color: statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColorPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: isHighlight
                ? AppConstants.primaryColor
                : AppConstants.textColorSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.textColorSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    color: isHighlight
                        ? AppConstants.primaryColor
                        : AppConstants.textColorPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    if (_isLoadingPembayaran) {
      return Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColorPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    }

    if (_pembayaranList.isEmpty) {
      return _buildSection(
        context,
        title: 'Detail Pembayaran',
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.warningColor.withValues(alpha: 26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppConstants.warningColor.withValues(alpha: 77),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppConstants.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada pembayaran untuk pemesanan ini.',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Ambil pembayaran terbaru
    final pembayaran = _pembayaranList.first;

    return _buildSection(
      context,
      title: 'Detail Pembayaran',
      children: [
        // Status Pembayaran
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getPaymentStatusColor(pembayaran.statusPembayaran)
                .withValues(alpha: 26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getPaymentStatusColor(pembayaran.statusPembayaran)
                  .withValues(alpha: 77),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getPaymentStatusIcon(pembayaran.statusPembayaran),
                color: _getPaymentStatusColor(pembayaran.statusPembayaran),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Pembayaran',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pembayaran.statusPembayaran.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            _getPaymentStatusColor(pembayaran.statusPembayaran),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Informasi Pembayaran
        _buildInfoRow(
          icon: Icons.attach_money,
          label: 'Jumlah Pembayaran',
          value: _formatCurrency(pembayaran.jumlahBayar),
          isHighlight: true,
        ),
        if (pembayaran.jenisPembayaran != null)
          _buildInfoRow(
            icon: Icons.category,
            label: 'Jenis Pembayaran',
            value: pembayaran.jenisPembayaran!,
          ),
        if (pembayaran.metodePembayaran != null)
          _buildInfoRow(
            icon: Icons.payment,
            label: 'Metode Pembayaran',
            value: pembayaran.metodePembayaran!,
          ),
        if (pembayaran.tanggalPembayaran != null)
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Tanggal Upload',
            value: _formatDateTime(pembayaran.tanggalPembayaran!),
          ),

        // Bukti Pembayaran
        if (pembayaran.buktiTransferUrl != null &&
            pembayaran.buktiTransferUrl!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bukti Pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstants.textColorSecondary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  _showPaymentProofDialog(
                      context, pembayaran.buktiTransferUrl!);
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          AppConstants.textColorSecondary.withValues(alpha: 77),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      pembayaran.buktiTransferUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                size: 48,
                                color: AppConstants.textColorSecondary,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Gagal memuat gambar',
                                style: TextStyle(
                                  color: AppConstants.textColorSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ketuk untuk memperbesar',
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textColorSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _showPaymentProofDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentStatusColor(StatusPembayaran status) {
    switch (status) {
      case StatusPembayaran.menungguVerifikasi:
        return AppConstants.warningColor;
      case StatusPembayaran.terverifikasi:
        return AppConstants.successColor;
      case StatusPembayaran.gagal:
        return AppConstants.errorColor;
    }
  }

  IconData _getPaymentStatusIcon(StatusPembayaran status) {
    switch (status) {
      case StatusPembayaran.menungguVerifikasi:
        return Icons.pending_actions;
      case StatusPembayaran.terverifikasi:
        return Icons.check_circle;
      case StatusPembayaran.gagal:
        return Icons.cancel;
    }
  }

  String _getPaymentStatusDescription(StatusPembayaran status) {
    switch (status) {
      case StatusPembayaran.menungguVerifikasi:
        return 'Bukti pembayaran telah diupload. Menunggu verifikasi dari pemilik kos.';
      case StatusPembayaran.terverifikasi:
        return 'Pembayaran Anda telah diverifikasi oleh pemilik kos';
      case StatusPembayaran.gagal:
        return 'Pembayaran ditolak. Silakan upload ulang bukti pembayaran yang valid.';
    }
  }

  Widget? _buildBottomAction(BuildContext context) {
    if (widget.pemesanan.statusPemesanan ==
        StatusPemesanan.menungguPembayaran) {
      // Jika sudah ada pembayaran, tidak perlu tampilkan tombol upload lagi
      if (_pembayaranList.isNotEmpty) {
        return null;
      }

      return Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 51),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadPaymentProofScreen(
                  pemesanan: widget.pemesanan,
                  onProofUploaded: () {
                    _loadPembayaran(); // Reload pembayaran setelah upload
                    if (widget.onRefresh != null) widget.onRefresh!();
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
          icon: const Icon(Icons.payment, size: 24),
          label: const Text(
            'Upload Bukti Pembayaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
          ),
        ),
      );
    }

    return null;
  }

  Color _getStatusColor(StatusPemesanan status) {
    switch (status) {
      case StatusPemesanan.menungguPembayaran:
        return AppConstants.warningColor;
      case StatusPemesanan.terkonfirmasi:
        return AppConstants.successColor;
      case StatusPemesanan.dibatalkan:
        return AppConstants.errorColor;
      case StatusPemesanan.selesai:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(StatusPemesanan status) {
    switch (status) {
      case StatusPemesanan.menungguPembayaran:
        return Icons.pending_actions;
      case StatusPemesanan.terkonfirmasi:
        return Icons.check_circle;
      case StatusPemesanan.dibatalkan:
        return Icons.cancel;
      case StatusPemesanan.selesai:
        return Icons.done_all;
    }
  }

  String _getStatusDescription(StatusPemesanan status) {
    switch (status) {
      case StatusPemesanan.menungguPembayaran:
        // Jika sudah ada pembayaran yang diupload, ubah deskripsinya
        if (_pembayaranList.isNotEmpty) {
          final pembayaran = _pembayaranList.first;
          if (pembayaran.statusPembayaran ==
              StatusPembayaran.menungguVerifikasi) {
            return 'Bukti pembayaran telah diupload. Menunggu verifikasi dari pemilik kos.';
          } else if (pembayaran.statusPembayaran == StatusPembayaran.gagal) {
            return 'Pembayaran ditolak. Silakan upload ulang bukti pembayaran yang valid.';
          }
        }
        return 'Silakan lakukan pembayaran dan upload bukti pembayaran';
      case StatusPemesanan.terkonfirmasi:
        return 'Pemesanan Anda telah dikonfirmasi oleh pemilik kos';
      case StatusPemesanan.dibatalkan:
        return 'Pemesanan ini telah dibatalkan';
      case StatusPemesanan.selesai:
        return 'Masa sewa telah berakhir';
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    return formatter.format(dateTime);
  }
}
