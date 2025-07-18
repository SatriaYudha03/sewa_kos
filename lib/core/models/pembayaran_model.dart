// lib/core/models/pembayaran_model.dart

class Pembayaran {
  final int id;
  final int pemesananId;
  final double jumlahBayar;
  final DateTime tanggalPembayaran;
  final String? metodePembayaran;
  final String statusPembayaran; // 'menunggu_verifikasi', 'terverifikasi', 'gagal'
  final String? buktiTransfer; // URL atau path bukti transfer

  Pembayaran({
    required this.id,
    required this.pemesananId,
    required this.jumlahBayar,
    required this.tanggalPembayaran,
    this.metodePembayaran,
    required this.statusPembayaran,
    this.buktiTransfer,
  });

  // Factory constructor untuk membuat objek Pembayaran dari JSON
  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id'] as int,
      pemesananId: json['pemesanan_id'] as int,
      // Penting: Pastikan parsing ke double
      jumlahBayar: double.parse(json['jumlah_bayar'].toString()), 
      // Penting: Pastikan parsing ke DateTime
      tanggalPembayaran: DateTime.parse(json['tanggal_pembayaran'] as String),
      metodePembayaran: json.containsKey('metode_pembayaran') ? json['metode_pembayaran'] as String? : null,
      statusPembayaran: json['status_pembayaran'] as String,
      buktiTransfer: json.containsKey('bukti_transfer') ? json['bukti_transfer'] as String? : null,
    );
  }

  // Method untuk mengonversi objek Pembayaran ke JSON (jika diperlukan untuk PUT/POST)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pemesanan_id': pemesananId,
      'jumlah_bayar': jumlahBayar,
      'tanggal_pembayaran': tanggalPembayaran.toIso8601String(), // ISO 8601 string untuk DateTime
      'metode_pembayaran': metodePembayaran,
      'status_pembayaran': statusPembayaran,
      'bukti_transfer': buktiTransfer,
    };
  }
}