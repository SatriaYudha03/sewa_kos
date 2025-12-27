/// Model Kos yang merepresentasikan tabel `kos` di Supabase
///
/// Tabel kos menyimpan informasi properti kos yang dimiliki oleh pemilik_kos

class Kos {
  final int id;
  final int userId;
  final String namaKos;
  final String? alamat;
  final String? deskripsi;
  final String? fotoUtamaUrl;
  final String? fasilitasUmum;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Data tambahan dari JOIN
  final String? ownerUsername;
  final String? ownerName;

  const Kos({
    required this.id,
    required this.userId,
    required this.namaKos,
    this.alamat,
    this.deskripsi,
    this.fotoUtamaUrl,
    this.fasilitasUmum,
    this.createdAt,
    this.updatedAt,
    this.ownerUsername,
    this.ownerName,
  });

  /// Membuat instance Kos dari JSON/Map
  /// Mendukung format dari Supabase dengan nested users
  factory Kos.fromJson(Map<String, dynamic> json) {
    // Handle nested users object dari Supabase JOIN
    String? extractedOwnerUsername;
    String? extractedOwnerName;
    if (json['users'] != null && json['users'] is Map) {
      extractedOwnerUsername = json['users']['username'] as String?;
      extractedOwnerName = json['users']['nama_lengkap'] as String?;
    } else {
      extractedOwnerUsername = json['owner_username'] as String?;
      extractedOwnerName = json['owner_name'] as String?;
    }

    return Kos(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      namaKos: json['nama_kos'] as String,
      alamat: json['alamat'] as String?,
      deskripsi: json['deskripsi'] as String?,
      fotoUtamaUrl: json['foto_utama_url'] as String?,
      fasilitasUmum: json['fasilitas_umum'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      ownerUsername: extractedOwnerUsername,
      ownerName: extractedOwnerName,
    );
  }

  /// Mengkonversi Kos ke JSON/Map untuk insert/update ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nama_kos': namaKos,
      'alamat': alamat,
      'deskripsi': deskripsi,
      'foto_utama_url': fotoUtamaUrl,
      'fasilitas_umum': fasilitasUmum,
    };
  }

  /// Mengecek apakah kos memiliki foto utama
  bool get hasImage => fotoUtamaUrl != null && fotoUtamaUrl!.isNotEmpty;

  /// Membuat salinan Kos dengan nilai yang diperbarui
  Kos copyWith({
    int? id,
    int? userId,
    String? namaKos,
    String? alamat,
    String? deskripsi,
    String? fotoUtamaUrl,
    String? fasilitasUmum,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerUsername,
    String? ownerName,
  }) {
    return Kos(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      namaKos: namaKos ?? this.namaKos,
      alamat: alamat ?? this.alamat,
      deskripsi: deskripsi ?? this.deskripsi,
      fotoUtamaUrl: fotoUtamaUrl ?? this.fotoUtamaUrl,
      fasilitasUmum: fasilitasUmum ?? this.fasilitasUmum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerName: ownerName ?? this.ownerName,
    );
  }

  @override
  String toString() {
    return 'Kos(id: $id, namaKos: $namaKos, alamat: $alamat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Kos && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
