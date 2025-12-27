/// AuthService - Layanan autentikasi menggunakan Supabase
///
/// Mengelola login, register, logout, dan profil pengguna

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  // Keys untuk SharedPreferences
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Hash password menggunakan SHA-256
  /// Catatan: Dalam produksi, gunakan bcrypt atau argon2 di server side
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Login dengan username/email dan password
  Future<Map<String, dynamic>> login(
      String usernameOrEmail, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      // Debug: Print untuk melihat hash password
      debugPrint('🔐 Attempting login for: $usernameOrEmail');
      debugPrint('🔑 Hashed password: $hashedPassword');

      // Query ke Supabase untuk mencari user
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.usersTable)
          .select('*, roles(role_name)')
          .or('username.eq.$usernameOrEmail,email.eq.$usernameOrEmail')
          .eq('password', hashedPassword)
          .maybeSingle();

      debugPrint('📦 Supabase response: $response');

      if (response == null) {
        return {
          'status': 'error',
          'message': 'Username/email atau password salah.',
        };
      }

      final user = User.fromJson(response);
      await _saveUserData(user);

      return {
        'status': 'success',
        'message': 'Login berhasil! Selamat datang, ${user.username}.',
        'user': user,
      };
    } on PostgrestException catch (e) {
      debugPrint('❌ PostgrestException: ${e.message}');
      debugPrint('❌ Code: ${e.code}');
      debugPrint('❌ Details: ${e.details}');
      return {
        'status': 'error',
        'message': 'Database error: ${e.message}',
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Login error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return {
        'status': 'error',
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Register pengguna baru
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role, // 'penyewa' atau 'pemilik_kos'
    String? namaLengkap,
    String? noTelepon,
  }) async {
    try {
      debugPrint(
          '📝 Attempting registration for: $username, $email, role: $role');

      // Cek apakah username sudah ada
      final existingUsername = await SupabaseConfig.client
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (existingUsername != null) {
        debugPrint('❌ Username already exists');
        return {
          'status': 'error',
          'message': 'Username sudah digunakan.',
        };
      }

      // Cek apakah email sudah ada
      final existingEmail = await SupabaseConfig.client
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingEmail != null) {
        debugPrint('❌ Email already exists');
        return {
          'status': 'error',
          'message': 'Email sudah digunakan.',
        };
      }

      // Dapatkan role_id berdasarkan role_name
      debugPrint('🔍 Looking for role: $role');
      final roleData = await SupabaseConfig.client
          .from(SupabaseConfig.rolesTable)
          .select('id')
          .eq('role_name', role)
          .maybeSingle();

      debugPrint('📦 Role data: $roleData');

      if (roleData == null) {
        debugPrint('❌ Role not found: $role');
        return {
          'status': 'error',
          'message':
              'Role "$role" tidak ditemukan. Pastikan tabel roles sudah memiliki data.',
        };
      }

      final roleId = roleData['id'] as int;
      final hashedPassword = _hashPassword(password);

      debugPrint('✅ Inserting new user with role_id: $roleId');

      // Insert user baru
      await SupabaseConfig.client.from(SupabaseConfig.usersTable).insert({
        'username': username,
        'email': email,
        'password': hashedPassword,
        'role_id': roleId,
        'nama_lengkap': namaLengkap,
        'no_telepon': noTelepon,
      });

      debugPrint('✅ Registration successful!');

      return {
        'status': 'success',
        'message': 'Registrasi berhasil! Silakan login.',
      };
    } on PostgrestException catch (e) {
      debugPrint('❌ PostgrestException during registration: ${e.message}');
      debugPrint('❌ Code: ${e.code}');
      debugPrint('❌ Details: ${e.details}');
      return {
        'status': 'error',
        'message': 'Database error: ${e.message}',
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Registration error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return {
        'status': 'error',
        'message': 'Gagal melakukan registrasi: ${e.toString()}',
      };
    }
  }

  /// Menyimpan data user ke SharedPreferences
  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(user.toLocalJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Mengambil data user yang sedang login dari SharedPreferences
  Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (!isLoggedIn) return null;

    final userDataString = prefs.getString(_userDataKey);
    if (userDataString == null) return null;

    try {
      final userDataMap = jsonDecode(userDataString) as Map<String, dynamic>;
      return User.fromLocalJson(userDataMap);
    } catch (e) {
      return null;
    }
  }

  /// Logout dan hapus data user dari SharedPreferences
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Mengambil profil user dari database
  Future<User?> getUserProfile(int userId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.usersTable)
          .select('*, roles(role_name)')
          .eq('id', userId)
          .single();

      return User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update profil user
  Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? namaLengkap,
    String? noTelepon,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (namaLengkap != null) updateData['nama_lengkap'] = namaLengkap;
      if (noTelepon != null) updateData['no_telepon'] = noTelepon;

      if (updateData.length <= 1) {
        return {
          'status': 'info',
          'message': 'Tidak ada perubahan yang dikirim.',
        };
      }

      await SupabaseConfig.client
          .from(SupabaseConfig.usersTable)
          .update(updateData)
          .eq('id', userId);

      // Refresh data user yang tersimpan
      final updatedUser = await getUserProfile(userId);
      if (updatedUser != null) {
        await _saveUserData(updatedUser);
      }

      return {
        'status': 'success',
        'message': 'Profil berhasil diperbarui.',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal memperbarui profil. Silakan coba lagi.',
      };
    }
  }

  /// Mendapatkan token (user_id) dari SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}
