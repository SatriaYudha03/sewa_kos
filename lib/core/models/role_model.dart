/// Model Role yang merepresentasikan tabel `roles` di Supabase
///
/// Tabel roles menyimpan jenis-jenis role pengguna:
/// - penyewa: Pengguna yang mencari dan menyewa kos
/// - pemilik_kos: Pengguna yang memiliki dan mengelola kos
library;

class Role {
  final int id;
  final String roleName;

  const Role({
    required this.id,
    required this.roleName,
  });

  /// Membuat instance Role dari JSON/Map
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      roleName: json['role_name'] as String,
    );
  }

  /// Mengkonversi Role ke JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': roleName,
    };
  }

  /// Role constants untuk kemudahan penggunaan
  static const String penyewa = 'penyewa';
  static const String pemilikKos = 'pemilik_kos';

  @override
  String toString() => 'Role(id: $id, roleName: $roleName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.id == id && other.roleName == roleName;
  }

  @override
  int get hashCode => id.hashCode ^ roleName.hashCode;
}
