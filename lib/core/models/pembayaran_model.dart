/// Model Pembayaran yang merepresentasikan tabel `detail_pembayaran` di Supabase
///
/// Tabel detail_pembayaran menyimpan informasi pembayaran untuk setiap pemesanan

/// Enum untuk status pembayaran
enum StatusPembayaran {
  menungguVerifikasi,
  terverifikasi,
  gagal;

  /// Konversi dari string database ke enum
  static StatusPembayaran fromString(String? value) {
    switch (value) {
      case 'menunggu_verifikasi':
        return StatusPembayaran.menungguVerifikasi;
      case 'terverifikasi':
        return StatusPembayaran.terverifikasi;
      case 'gagal':
        return StatusPembayaran.gagal;
      default:
        return StatusPembayaran.menungguVerifikasi;
    }
  }

  /// Konversi enum ke string untuk database
  String toDbString() {
    switch (this) {
      case StatusPembayaran.menungguVerifikasi:
        return 'menunggu_verifikasi';
      case StatusPembayaran.terverifikasi:
        return 'terverifikasi';
      case StatusPembayaran.gagal:
        return 'gagal';
    }
  }

  /// Label untuk ditampilkan di UI
  String get label {
    switch (this) {
      case StatusPembayaran.menungguVerifikasi:
        return 'Menunggu Verifikasi';
      case StatusPembayaran.terverifikasi:
        return 'Terverifikasi';
      case StatusPembayaran.gagal:
        return 'Gagal';
    }
  }

  /// Alias untuk label (displayName)
  String get displayName => label;
}

class Pembayaran {
  final int id;
  final int pemesananId;
  final double jumlahBayar;
  final String? jenisPembayaran;
  final DateTime? tanggalPembayaran;
  final String? metodePembayaran;
  final StatusPembayaran statusPembayaran;
  final String? buktiTransferUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Pembayaran({
    required this.id,
    required this.pemesananId,
    required this.jumlahBayar,
    this.jenisPembayaran,
    this.tanggalPembayaran,
    this.metodePembayaran,
    required this.statusPembayaran,
    this.buktiTransferUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Membuat instance Pembayaran dari JSON/Map
  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id'] as int,
      pemesananId: json['pemesanan_id'] as int,
      jumlahBayar: _parseDouble(json['jumlah_bayar']),
      jenisPembayaran: json['jenis_pembayaran'] as String?,
      tanggalPembayaran: json['tanggal_pembayaran'] != null
          ? DateTime.tryParse(json['tanggal_pembayaran'] as String)
          : null,
      metodePembayaran: json['metode_pembayaran'] as String?,
      statusPembayaran:
          StatusPembayaran.fromString(json['status_pembayaran'] as String?),
      buktiTransferUrl: json['bukti_transfer_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
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

  /// Mengkonversi Pembayaran ke JSON/Map untuk insert ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'pemesanan_id': pemesananId,
      'jumlah_bayar': jumlahBayar,
      'jenis_pembayaran': jenisPembayaran,
      'metode_pembayaran': metodePembayaran,
      'status_pembayaran': statusPembayaran.toDbString(),
      'bukti_transfer_url': buktiTransferUrl,
    };
  }

  /// Mengecek apakah pembayaran memiliki bukti transfer
  bool get hasBuktiTransfer =>
      buktiTransferUrl != null && buktiTransferUrl!.isNotEmpty;

  /// Mengecek apakah pembayaran menunggu verifikasi
  bool get isMenungguVerifikasi =>
      statusPembayaran == StatusPembayaran.menungguVerifikasi;

  /// Mengecek apakah pembayaran sudah terverifikasi
  bool get isTerverifikasi =>
      statusPembayaran == StatusPembayaran.terverifikasi;

  /// Membuat salinan Pembayaran dengan nilai yang diperbarui
  Pembayaran copyWith({
    int? id,
    int? pemesananId,
    double? jumlahBayar,
    String? jenisPembayaran,
    DateTime? tanggalPembayaran,
    String? metodePembayaran,
    StatusPembayaran? statusPembayaran,
    String? buktiTransferUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pembayaran(
      id: id ?? this.id,
      pemesananId: pemesananId ?? this.pemesananId,
      jumlahBayar: jumlahBayar ?? this.jumlahBayar,
      jenisPembayaran: jenisPembayaran ?? this.jenisPembayaran,
      tanggalPembayaran: tanggalPembayaran ?? this.tanggalPembayaran,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
      buktiTransferUrl: buktiTransferUrl ?? this.buktiTransferUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Pembayaran(id: $id, jumlahBayar: $jumlahBayar, status: ${statusPembayaran.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pembayaran && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
