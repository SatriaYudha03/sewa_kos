// lib/core/models/detail_pembayaran_model.dart

class DetailPembayaran {
  final int id;
  final int pemesananId;
  final double jumlahBayar;
  final DateTime tanggalPembayaran;
  final String? metodePembayaran;
  final String statusPembayaran; // 'menunggu_verifikasi', 'terverifikasi', 'gagal'
  final String? buktiTransfer; // URL atau path bukti transfer

  DetailPembayaran({
    required this.id,
    required this.pemesananId,
    required this.jumlahBayar,
    required this.tanggalPembayaran,
    this.metodePembayaran,
    required this.statusPembayaran,
    this.buktiTransfer,
  });

  factory DetailPembayaran.fromJson(Map<String, dynamic> json) {
    return DetailPembayaran(
      id: json['id'] as int,
      pemesananId: json['pemesanan_id'] as int,
      jumlahBayar: double.parse(json['jumlah_bayar'].toString()),
      tanggalPembayaran: DateTime.parse(json['tanggal_pembayaran'] as String),
      metodePembayaran: json.containsKey('metode_pembayaran') ? json['metode_pembayaran'] as String? : null,
      statusPembayaran: json['status_pembayaran'] as String,
      buktiTransfer: json.containsKey('bukti_transfer') ? json['bukti_transfer'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pemesanan_id': pemesananId,
      'jumlah_bayar': jumlahBayar,
      'tanggal_pembayaran': tanggalPembayaran.toIso8601String(),
      'metode_pembayaran': metodePembayaran,
      'status_pembayaran': statusPembayaran,
      'bukti_transfer': buktiTransfer,
    };
  }
}