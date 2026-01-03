/// Halaman Detail Pemesanan untuk Penyewa
///
/// Menampilkan informasi lengkap tentang pemesanan kamar kos
library;

import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/models/pemesanan_model.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    if (mounted) {
      setState(() {
        _isLocaleInitialized = true;
      });
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding * 1.5),
      decoration: BoxDecoration(
        color:
            _getStatusColor(widget.pemesanan.statusPemesanan).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _getStatusColor(widget.pemesanan.statusPemesanan),
            width: 3,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(widget.pemesanan.statusPemesanan),
            size: 60,
            color: _getStatusColor(widget.pemesanan.statusPemesanan),
          ),
          const SizedBox(height: 12),
          Text(
            'Status: ${widget.pemesanan.statusPemesanan.displayName}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(widget.pemesanan.statusPemesanan),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(widget.pemesanan.statusPemesanan),
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

  Widget? _buildBottomAction(BuildContext context) {
    if (widget.pemesanan.statusPemesanan ==
        StatusPemesanan.menungguPembayaran) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
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
