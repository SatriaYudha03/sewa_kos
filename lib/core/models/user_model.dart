/// Model User yang merepresentasikan tabel `users` di Supabase
///
/// Tabel users menyimpan informasi pengguna aplikasi
/// dengan relasi ke tabel roles untuk menentukan jenis pengguna

class User {
  final int id;
  final String username;
  final String email;
  final int roleId;
  final String? roleName; // Dari JOIN dengan tabel roles
  final String? namaLengkap;
  final String? noTelepon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.roleId,
    this.roleName,
    this.namaLengkap,
    this.noTelepon,
    this.createdAt,
    this.updatedAt,
  });

  /// Membuat instance User dari JSON/Map
  /// Mendukung format dari Supabase dengan nested roles
  factory User.fromJson(Map<String, dynamic> json) {
    // Handle nested roles object dari Supabase JOIN
    String? extractedRoleName;
    if (json['roles'] != null && json['roles'] is Map) {
      extractedRoleName = json['roles']['role_name'] as String?;
    } else {
      extractedRoleName = json['role_name'] as String?;
    }

    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      roleId: json['role_id'] as int,
      roleName: extractedRoleName,
      namaLengkap: json['nama_lengkap'] as String?,
      noTelepon: json['no_telepon'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Mengkonversi User ke JSON/Map untuk insert/update ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'role_id': roleId,
      'nama_lengkap': namaLengkap,
      'no_telepon': noTelepon,
    };
  }

  /// Mengkonversi User ke JSON/Map untuk penyimpanan lokal (SharedPreferences)
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role_id': roleId,
      'role_name': roleName,
      'nama_lengkap': namaLengkap,
      'no_telepon': noTelepon,
    };
  }

  /// Membuat instance User dari data lokal (SharedPreferences)
  factory User.fromLocalJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      roleId: json['role_id'] as int,
      roleName: json['role_name'] as String?,
      namaLengkap: json['nama_lengkap'] as String?,
      noTelepon: json['no_telepon'] as String?,
    );
  }

  /// Membuat salinan User dengan nilai yang diperbarui
  User copyWith({
    int? id,
    String? username,
    String? email,
    int? roleId,
    String? roleName,
    String? namaLengkap,
    String? noTelepon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      noTelepon: noTelepon ?? this.noTelepon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mengecek apakah user adalah penyewa
  bool get isPenyewa => roleName == 'penyewa';

  /// Mengecek apakah user adalah pemilik kos
  bool get isPemilikKos => roleName == 'pemilik_kos';

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, roleName: $roleName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
