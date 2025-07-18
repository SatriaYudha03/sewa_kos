// lib/core/models/kamar_kos_model.dart

class KamarKos {
  final int id;
  final int kosId; // ID kos tempat kamar ini berada
  final String namaKamar;
  final double hargaSewa;
  final String? luasKamar;
  final String? fasilitas; // Misal: "AC, Kamar Mandi Dalam, Kasur"
  final String status; // 'tersedia', 'terisi', 'perbaikan'

  KamarKos({
    required this.id,
    required this.kosId,
    required this.namaKamar,
    required this.hargaSewa,
    this.luasKamar,
    this.fasilitas,
    required this.status,
  });

  factory KamarKos.fromJson(Map<String, dynamic> json) {
    return KamarKos(
      id: json['id'] as int,
      kosId: json['kos_id'] as int,
      namaKamar: json['nama_kamar'] as String,
      // Pastikan hargaSewa di-parse sebagai double
      hargaSewa: double.parse(json['harga_sewa'].toString()), 
      luasKamar: json.containsKey('luas_kamar') ? json['luas_kamar'] as String? : null,
      fasilitas: json.containsKey('fasilitas') ? json['fasilitas'] as String? : null,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kos_id': kosId,
      'nama_kamar': namaKamar,
      'harga_sewa': hargaSewa,
      'luas_kamar': luasKamar,
      'fasilitas': fasilitas,
      'status': status,
    };
  }
}