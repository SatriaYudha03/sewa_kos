// lib/core/models/kos_model.dart

class Kos {
  final int id;
  final int userId; // ID pemilik kos
  final String namaKos;
  final String alamat;
  final String? deskripsi;
  final String? fotoUtama; // URL atau path ke foto
  final String? fasilitasUmum;
  final String? ownerUsername; // Dari JOIN di API list/detail
  final String? ownerName; // Dari JOIN di API list/detail

  Kos({
    required this.id,
    required this.userId,
    required this.namaKos,
    required this.alamat,
    this.deskripsi,
    this.fotoUtama,
    this.fasilitasUmum,
    this.ownerUsername,
    this.ownerName,
  });

  factory Kos.fromJson(Map<String, dynamic> json) {
    return Kos(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      namaKos: json['nama_kos'] as String,
      alamat: json['alamat'] as String,
      deskripsi: json.containsKey('deskripsi') ? json['deskripsi'] as String? : null,
      fotoUtama: json.containsKey('foto_utama') ? json['foto_utama'] as String? : null,
      fasilitasUmum: json.containsKey('fasilitas_umum') ? json['fasilitas_umum'] as String? : null,
      ownerUsername: json.containsKey('owner_username') ? json['owner_username'] as String? : null,
      ownerName: json.containsKey('owner_name') ? json['owner_name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nama_kos': namaKos,
      'alamat': alamat,
      'deskripsi': deskripsi,
      'foto_utama': fotoUtama,
      'fasilitas_umum': fasilitasUmum,
    };
  }
}