// lib/core/models/pemesanan_model.dart

class Pemesanan {
  final int id;
  final int userId; // ID penyewa
  final int kamarId;
  final DateTime tanggalMulai;
  final int durasiSewa; // Dalam bulan
  final double totalHarga;
  final String statusPemesanan; // 'menunggu_pembayaran', 'terkonfirmasi', 'dibatalkan', 'selesai'
  
  // Detail tambahan dari JOIN
  final String? namaKamar;
  final double? hargaSewaKamar;
  final String? namaKos;
  final String? alamatKos;
  final String? tenantUsername;
  final String? tenantName;
  final String? ownerUsername;
  final String? ownerName;
  final int? kosOwnerId; // ID pemilik kos dari pemesanan ini

  Pemesanan({
    required this.id,
    required this.userId,
    required this.kamarId,
    required this.tanggalMulai,
    required this.durasiSewa,
    required this.totalHarga,
    required this.statusPemesanan,
    this.namaKamar,
    this.hargaSewaKamar,
    this.namaKos,
    this.alamatKos,
    this.tenantUsername,
    this.tenantName,
    this.ownerUsername,
    this.ownerName,
    this.kosOwnerId,
  });

  factory Pemesanan.fromJson(Map<String, dynamic> json) {
    return Pemesanan(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      kamarId: json['kamar_id'] as int,
      tanggalMulai: DateTime.parse(json['tanggal_mulai'] as String),
      durasiSewa: json['durasi_sewa'] as int,
      totalHarga: double.parse(json['total_harga'].toString()),
      statusPemesanan: json['status_pemesanan'] as String,
      
      namaKamar: json.containsKey('nama_kamar') ? json['nama_kamar'] as String? : null,
      hargaSewaKamar: json.containsKey('harga_sewa') ? double.tryParse(json['harga_sewa'].toString()) : null,
      namaKos: json.containsKey('nama_kos') ? json['nama_kos'] as String? : null,
      alamatKos: json.containsKey('alamat') ? json['alamat'] as String? : null,
      tenantUsername: json.containsKey('tenant_username') ? json['tenant_username'] as String? : null,
      tenantName: json.containsKey('tenant_name') ? json['tenant_name'] as String? : null,
      ownerUsername: json.containsKey('owner_username') ? json['owner_username'] as String? : null,
      ownerName: json.containsKey('owner_name') ? json['owner_name'] as String? : null,
      kosOwnerId: json.containsKey('kos_owner_id') ? json['kos_owner_id'] as int? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kamar_id': kamarId,
      'tanggal_mulai': tanggalMulai.toIso8601String().split('T')[0], // Hanya tanggal
      'durasi_sewa': durasiSewa,
      'total_harga': totalHarga,
      'status_pemesanan': statusPemesanan,
    };
  }
}