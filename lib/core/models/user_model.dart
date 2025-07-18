// lib/core/models/user_model.dart

class User {
  final int id;
  final String username;
  final String email;
  final String roleName; // Ini akan berisi 'penyewa' atau 'pemilik_kos'
  final String? namaLengkap; // Nullable
  final String? noTelepon; // Nullable

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.roleName,
    this.namaLengkap,
    this.noTelepon,
  });

  // Factory constructor untuk membuat objek User dari JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      roleName: json['role_name'] as String, // Pastikan nama kunci sesuai dengan respon API PHP
      namaLengkap: json['containsKey']('nama_lengkap') ? json['nama_lengkap'] as String? : null,
      noTelepon: json.containsKey('no_telepon') ? json['no_telepon'] as String? : null,
    );
  }

  // Method untuk mengonversi objek User ke JSON (misal untuk mengirim data update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role_name': roleName,
      'nama_lengkap': namaLengkap,
      'no_telepon': noTelepon,
    };
  }
}