/// Model KamarKos yang merepresentasikan tabel `kamar_kos` di Supabase
///
/// Tabel kamar_kos menyimpan informasi kamar yang tersedia di setiap kos
library;

/// Enum untuk status kamar
enum StatusKamar {
  tersedia,
  terisi,
  perbaikan;

  /// Konversi dari string ke enum
  static StatusKamar fromString(String? value) {
    switch (value) {
      case 'tersedia':
        return StatusKamar.tersedia;
      case 'terisi':
        return StatusKamar.terisi;
      case 'perbaikan':
        return StatusKamar.perbaikan;
      default:
        return StatusKamar.tersedia;
    }
  }

  /// Konversi enum ke string untuk database
  String toDbString() => name;

  /// Label untuk ditampilkan di UI
  String get label {
    switch (this) {
      case StatusKamar.tersedia:
        return 'Tersedia';
      case StatusKamar.terisi:
        return 'Terisi';
      case StatusKamar.perbaikan:
        return 'Perbaikan';
    }
  }

  /// Alias untuk label (displayName)
  String get displayName => label;
}

class KamarKos {
  final int id;
  final int kosId;
  final String namaKamar;
  final double hargaSewa;
  final String? luasKamar;
  final String? fasilitas;
  final StatusKamar status;
  final String? fotoKamarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Data tambahan dari JOIN
  final String? namaKos;
  final String? alamatKos;

  const KamarKos({
    required this.id,
    required this.kosId,
    required this.namaKamar,
    required this.hargaSewa,
    this.luasKamar,
    this.fasilitas,
    required this.status,
    this.fotoKamarUrl,
    this.createdAt,
    this.updatedAt,
    this.namaKos,
    this.alamatKos,
  });

  /// Membuat instance KamarKos dari JSON/Map
  /// Mendukung format dari Supabase dengan nested kos
  factory KamarKos.fromJson(Map<String, dynamic> json) {
    // Handle nested kos object dari Supabase JOIN
    String? extractedNamaKos;
    String? extractedAlamatKos;
    if (json['kos'] != null && json['kos'] is Map) {
      extractedNamaKos = json['kos']['nama_kos'] as String?;
      extractedAlamatKos = json['kos']['alamat'] as String?;
    } else {
      extractedNamaKos = json['nama_kos'] as String?;
      extractedAlamatKos = json['alamat_kos'] as String?;
    }

    return KamarKos(
      id: json['id'] as int,
      kosId: json['kos_id'] as int,
      namaKamar: json['nama_kamar'] as String,
      hargaSewa: _parseDouble(json['harga_sewa']),
      luasKamar: json['luas_kamar'] as String?,
      fasilitas: json['fasilitas'] as String?,
      status: StatusKamar.fromString(json['status'] as String?),
      fotoKamarUrl: json['foto_kamar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      namaKos: extractedNamaKos,
      alamatKos: extractedAlamatKos,
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

  /// Mengkonversi KamarKos ke JSON/Map untuk insert/update ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'kos_id': kosId,
      'nama_kamar': namaKamar,
      'harga_sewa': hargaSewa,
      'luas_kamar': luasKamar,
      'fasilitas': fasilitas,
      'status': status.toDbString(),
      'foto_kamar_url': fotoKamarUrl,
    };
  }

  /// Mengecek apakah kamar memiliki foto
  bool get hasImage => fotoKamarUrl != null && fotoKamarUrl!.isNotEmpty;

  /// Mengecek apakah kamar tersedia untuk disewa
  bool get isTersedia => status == StatusKamar.tersedia;

  /// Membuat salinan KamarKos dengan nilai yang diperbarui
  KamarKos copyWith({
    int? id,
    int? kosId,
    String? namaKamar,
    double? hargaSewa,
    String? luasKamar,
    String? fasilitas,
    StatusKamar? status,
    String? fotoKamarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? namaKos,
    String? alamatKos,
  }) {
    return KamarKos(
      id: id ?? this.id,
      kosId: kosId ?? this.kosId,
      namaKamar: namaKamar ?? this.namaKamar,
      hargaSewa: hargaSewa ?? this.hargaSewa,
      luasKamar: luasKamar ?? this.luasKamar,
      fasilitas: fasilitas ?? this.fasilitas,
      status: status ?? this.status,
      fotoKamarUrl: fotoKamarUrl ?? this.fotoKamarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      namaKos: namaKos ?? this.namaKos,
      alamatKos: alamatKos ?? this.alamatKos,
    );
  }

  @override
  String toString() {
    return 'KamarKos(id: $id, namaKamar: $namaKamar, hargaSewa: $hargaSewa, status: ${status.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KamarKos && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
