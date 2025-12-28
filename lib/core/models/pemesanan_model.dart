/// Model Pemesanan yang merepresentasikan tabel `pemesanan` di Supabase
///
/// Tabel pemesanan menyimpan informasi pemesanan kamar kos oleh penyewa
library;

/// Enum untuk status pemesanan
enum StatusPemesanan {
  menungguPembayaran,
  terkonfirmasi,
  dibatalkan,
  selesai;

  /// Konversi dari string database ke enum
  static StatusPemesanan fromString(String? value) {
    switch (value) {
      case 'menunggu_pembayaran':
        return StatusPemesanan.menungguPembayaran;
      case 'terkonfirmasi':
        return StatusPemesanan.terkonfirmasi;
      case 'dibatalkan':
        return StatusPemesanan.dibatalkan;
      case 'selesai':
        return StatusPemesanan.selesai;
      default:
        return StatusPemesanan.menungguPembayaran;
    }
  }

  /// Konversi enum ke string untuk database
  String toDbString() {
    switch (this) {
      case StatusPemesanan.menungguPembayaran:
        return 'menunggu_pembayaran';
      case StatusPemesanan.terkonfirmasi:
        return 'terkonfirmasi';
      case StatusPemesanan.dibatalkan:
        return 'dibatalkan';
      case StatusPemesanan.selesai:
        return 'selesai';
    }
  }

  /// Label untuk ditampilkan di UI
  String get label {
    switch (this) {
      case StatusPemesanan.menungguPembayaran:
        return 'Menunggu Pembayaran';
      case StatusPemesanan.terkonfirmasi:
        return 'Terkonfirmasi';
      case StatusPemesanan.dibatalkan:
        return 'Dibatalkan';
      case StatusPemesanan.selesai:
        return 'Selesai';
    }
  }

  /// Alias untuk label (displayName)
  String get displayName => label;
}

class Pemesanan {
  final int id;
  final int userId;
  final int kamarId;
  final DateTime tanggalMulai;
  final int durasiSewa; // Dalam bulan
  final DateTime tanggalSelesai;
  final double totalHarga;
  final StatusPemesanan statusPemesanan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Data tambahan dari JOIN
  final String? namaKamar;
  final double? hargaSewaKamar;
  final String? namaKos;
  final String? alamatKos;
  final String? tenantUsername;
  final String? tenantName;
  final String? ownerUsername;
  final String? ownerName;
  final int? kosOwnerId;

  const Pemesanan({
    required this.id,
    required this.userId,
    required this.kamarId,
    required this.tanggalMulai,
    required this.durasiSewa,
    required this.tanggalSelesai,
    required this.totalHarga,
    required this.statusPemesanan,
    this.createdAt,
    this.updatedAt,
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

  /// Membuat instance Pemesanan dari JSON/Map
  /// Mendukung format dari Supabase dengan nested relations
  factory Pemesanan.fromJson(Map<String, dynamic> json) {
    // Handle nested kamar_kos -> kos -> users dari Supabase JOIN
    String? extractedNamaKamar;
    double? extractedHargaSewa;
    String? extractedNamaKos;
    String? extractedAlamatKos;
    String? extractedTenantUsername;
    String? extractedTenantName;
    String? extractedOwnerUsername;
    String? extractedOwnerName;
    int? extractedKosOwnerId;

    // Extract dari nested kamar_kos
    if (json['kamar_kos'] != null && json['kamar_kos'] is Map) {
      final kamar = json['kamar_kos'] as Map<String, dynamic>;
      extractedNamaKamar = kamar['nama_kamar'] as String?;
      extractedHargaSewa = _parseDouble(kamar['harga_sewa']);

      // Extract dari nested kos dalam kamar_kos
      if (kamar['kos'] != null && kamar['kos'] is Map) {
        final kos = kamar['kos'] as Map<String, dynamic>;
        extractedNamaKos = kos['nama_kos'] as String?;
        extractedAlamatKos = kos['alamat'] as String?;
        extractedKosOwnerId = kos['user_id'] as int?;

        // Extract owner dari nested users dalam kos
        if (kos['users'] != null && kos['users'] is Map) {
          final owner = kos['users'] as Map<String, dynamic>;
          extractedOwnerUsername = owner['username'] as String?;
          extractedOwnerName = owner['nama_lengkap'] as String?;
        }
      }
    } else {
      extractedNamaKamar = json['nama_kamar'] as String?;
      extractedHargaSewa = _parseDoubleNullable(json['harga_sewa']);
      extractedNamaKos = json['nama_kos'] as String?;
      extractedAlamatKos = json['alamat'] as String?;
      extractedOwnerUsername = json['owner_username'] as String?;
      extractedOwnerName = json['owner_name'] as String?;
      extractedKosOwnerId = json['kos_owner_id'] as int?;
    }

    // Extract tenant/penyewa dari nested users
    if (json['users'] != null && json['users'] is Map) {
      final tenant = json['users'] as Map<String, dynamic>;
      extractedTenantUsername = tenant['username'] as String?;
      extractedTenantName = tenant['nama_lengkap'] as String?;
    } else {
      extractedTenantUsername = json['tenant_username'] as String?;
      extractedTenantName = json['tenant_name'] as String?;
    }

    return Pemesanan(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      kamarId: json['kamar_id'] as int,
      tanggalMulai: DateTime.parse(json['tanggal_mulai'] as String),
      durasiSewa: json['durasi_sewa'] as int,
      tanggalSelesai: DateTime.parse(json['tanggal_selesai'] as String),
      totalHarga: _parseDouble(json['total_harga']),
      statusPemesanan:
          StatusPemesanan.fromString(json['status_pemesanan'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      namaKamar: extractedNamaKamar,
      hargaSewaKamar: extractedHargaSewa,
      namaKos: extractedNamaKos,
      alamatKos: extractedAlamatKos,
      tenantUsername: extractedTenantUsername,
      tenantName: extractedTenantName,
      ownerUsername: extractedOwnerUsername,
      ownerName: extractedOwnerName,
      kosOwnerId: extractedKosOwnerId,
    );
  }

  /// Helper untuk parsing double dari berbagai format
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper untuk parsing double nullable
  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Mengkonversi Pemesanan ke JSON/Map untuk insert ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'kamar_id': kamarId,
      'tanggal_mulai': tanggalMulai.toIso8601String().split('T')[0],
      'durasi_sewa': durasiSewa,
      'tanggal_selesai': tanggalSelesai.toIso8601String().split('T')[0],
      'total_harga': totalHarga,
      'status_pemesanan': statusPemesanan.toDbString(),
    };
  }

  /// Mengecek apakah pemesanan masih menunggu pembayaran
  bool get isMenungguPembayaran =>
      statusPemesanan == StatusPemesanan.menungguPembayaran;

  /// Mengecek apakah pemesanan sudah terkonfirmasi
  bool get isTerkonfirmasi => statusPemesanan == StatusPemesanan.terkonfirmasi;

  /// Membuat salinan Pemesanan dengan nilai yang diperbarui
  Pemesanan copyWith({
    int? id,
    int? userId,
    int? kamarId,
    DateTime? tanggalMulai,
    int? durasiSewa,
    DateTime? tanggalSelesai,
    double? totalHarga,
    StatusPemesanan? statusPemesanan,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? namaKamar,
    double? hargaSewaKamar,
    String? namaKos,
    String? alamatKos,
    String? tenantUsername,
    String? tenantName,
    String? ownerUsername,
    String? ownerName,
    int? kosOwnerId,
  }) {
    return Pemesanan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      kamarId: kamarId ?? this.kamarId,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      durasiSewa: durasiSewa ?? this.durasiSewa,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      totalHarga: totalHarga ?? this.totalHarga,
      statusPemesanan: statusPemesanan ?? this.statusPemesanan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      namaKamar: namaKamar ?? this.namaKamar,
      hargaSewaKamar: hargaSewaKamar ?? this.hargaSewaKamar,
      namaKos: namaKos ?? this.namaKos,
      alamatKos: alamatKos ?? this.alamatKos,
      tenantUsername: tenantUsername ?? this.tenantUsername,
      tenantName: tenantName ?? this.tenantName,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerName: ownerName ?? this.ownerName,
      kosOwnerId: kosOwnerId ?? this.kosOwnerId,
    );
  }

  @override
  String toString() {
    return 'Pemesanan(id: $id, status: ${statusPemesanan.label}, totalHarga: $totalHarga)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pemesanan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
