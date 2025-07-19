// lib/core/models/kos_model.dart (DIUPDATE: Gunakan has_image)

class Kos {
  final int id;
  final int userId;
  final String namaKos;
  final String alamat;
  final String? deskripsi;
  final bool hasImage; // <--- UBAH INI: Flag apakah ada gambar
  final String? fasilitasUmum;
  final String? ownerUsername;
  final String? ownerName;

  Kos({
    required this.id,
    required this.userId,
    required this.namaKos,
    required this.alamat,
    this.deskripsi,
    required this.hasImage, // <--- UBAH INI
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
      hasImage: (json['has_image'] as int) == 1, // <--- LOGIKA BARU: Convert int (0/1) to bool
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
      // hasImage tidak perlu dikirim dalam toJson ini
      'fasilitas_umum': fasilitasUmum,
    };
  }
}