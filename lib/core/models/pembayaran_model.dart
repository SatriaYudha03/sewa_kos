// lib/core/models/pembayaran_model.dart (DIUPDATE)

class Pembayaran {
  final int id;
  final int pemesananId;
  final double jumlahBayar;
  final DateTime tanggalPembayaran;
  final String? metodePembayaran;
  final String statusPembayaran;
  final int? buktiTransferId; // <--- UBAH INI: sekarang menyimpan ID Pembayaran (untuk serve.php)

  Pembayaran({
    required this.id,
    required this.pemesananId,
    required this.jumlahBayar,
    required this.tanggalPembayaran,
    this.metodePembayaran,
    required this.statusPembayaran,
    this.buktiTransferId, // <--- UBAH INI
  });

  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id'] as int,
      pemesananId: json['pemesanan_id'] as int,
      jumlahBayar: double.parse(json['jumlah_bayar'].toString()),
      tanggalPembayaran: DateTime.parse(json['tanggal_pembayaran'] as String),
      metodePembayaran: json.containsKey('metode_pembayaran') ? json['metode_pembayaran'] as String? : null,
      statusPembayaran: json['status_pembayaran'] as String,
      buktiTransferId: json.containsKey('bukti_transfer') ? (json['bukti_transfer'] != null ? json['id'] as int? : null) : null, // <--- LOGIKA BARU
      // Jika bukti_transfer ada di JSON (berarti ada BLOB di DB), gunakan ID pembayaran itu sendiri untuk mengambil gambar
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
      // 'bukti_transfer_id': buktiTransferId, // Tidak relevan untuk dikirim
    };
  }
}