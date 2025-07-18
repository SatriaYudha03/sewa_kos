// lib/core/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk menyimpan data user
import '../../app_constants.dart'; // Import AppConstants
import '../models/user_model.dart'; // Import UserModel

class AuthService {
  final String _baseUrl = AppConstants.baseUrl; // Menggunakan base URL dari constants

  // Method untuk LOGIN
  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final url = Uri.parse("$_baseUrl/auth/login.php"); // Pastikan path sesuai
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // Penting: Kirim sebagai JSON
        body: json.encode({
          'username_or_email': usernameOrEmail,
          'password': password,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        // Login berhasil, simpan data user (termasuk role) secara lokal
        final user = User.fromJson(responseBody['user']);
        await _saveUserData(user); // Simpan ID dan Role untuk otorisasi selanjutnya

        return {'status': 'success', 'message': responseBody['message'], 'user': user};
      } else {
        // Login gagal
        return {'status': 'error', 'message': responseBody['message'] ?? 'Login failed.'};
      }
    } catch (e) {
      // Tangani error jaringan atau parsing
      print('Error during login: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // Method untuk REGISTER
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role, // 'penyewa' atau 'pemilik_kos'
    String? namaLengkap, // Opsional
    String? noTelepon, // Opsional
  }) async {
    final url = Uri.parse("$_baseUrl/auth/register.php"); // Pastikan path sesuai
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // Penting: Kirim sebagai JSON
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
          'nama_lengkap': namaLengkap,
          'no_telepon': noTelepon,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201 && responseBody['status'] == 'success') {
        return {'status': 'success', 'message': responseBody['message']};
      } else {
        // Registrasi gagal (misal: username/email sudah ada)
        return {'status': 'error', 'message': responseBody['message'] ?? 'Registration failed.'};
      }
    } catch (e) {
      print('Error during registration: $e');
      return {'status': 'error', 'message': 'Failed to connect to server. Please try again later.'};
    }
  }

  // --- Metode untuk menyimpan dan mengambil data user di Shared Preferences ---

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_role', user.roleName);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    // Simpan data lain jika diperlukan
  }

  Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final userRole = prefs.getString('user_role');
    final username = prefs.getString('username');
    final email = prefs.getString('email');

    if (userId != null && userRole != null && username != null && email != null) {
      return User(
        id: userId,
        username: username,
        email: email,
        roleName: userRole,
        // Nama lengkap dan no telepon mungkin perlu disimpan terpisah jika penting di UI
        // atau diambil ulang dari API profil user
      );
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('username');
    await prefs.remove('email');
    // Hapus semua data user yang tersimpan
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final user = await getLoggedInUser();
    if (user != null) {
      return {
        'Content-Type': 'application/json', // Untuk body JSON
        'X-User-ID': user.id.toString(),    // Header kustom untuk ID user
        'X-User-Role': user.roleName,       // Header kustom untuk role user
      };
    }
    return {'Content-Type': 'application/json'}; // Default jika belum login
  }

  Future<User?> getUserProfile(int userId) async {
    final url = Uri.parse("$_baseUrl/auth/profile.php"); // Gunakan endpoint profile
    
    try {
      final headers = await getAuthHeaders(); // Perlu header otorisasi
      final response = await http.get(url, headers: headers);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return User.fromJson(responseBody['data']); // Mengembalikan objek User
      } else {
        print('Error fetching user profile: ${responseBody['message']}');
        return null;
      }
    } catch (e) {
      print('Error during getUserProfile: $e');
      return null;
    }
  }
}