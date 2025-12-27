class Pembayaran {
  final int id;
  final int pemesananId;
  final double jumlahBayar;
  final DateTime tanggalPembayaran;
  final String? metodePembayaran;
  final String statusPembayaran;
  final bool hasBuktiTransfer; // <--- UBAH INI: Flag apakah ada bukti transfer

  Pembayaran({
    required this.id,
    required this.pemesananId,
    required this.jumlahBayar,
    required this.tanggalPembayaran,
    this.metodePembayaran,
    required this.statusPembayaran,
    required this.hasBuktiTransfer, // <--- UBAH INI
  });

  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id'] as int,
      pemesananId: json['pemesanan_id'] as int,
      jumlahBayar: double.parse(json['jumlah_bayar'].toString()),
      tanggalPembayaran: DateTime.parse(json['tanggal_pembayaran'] as String),
      metodePembayaran: json.containsKey('metode_pembayaran') ? json['metode_pembayaran'] as String? : null,
      statusPembayaran: json['status_pembayaran'] as String,
      hasBuktiTransfer: (json['has_bukti_transfer'] as int) == 1, // <--- LOGIKA BARU
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
    };
  }
}