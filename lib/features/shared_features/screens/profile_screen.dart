// lib/features/shared_features/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/services/auth_service.dart';
import 'package:sewa_kos/features/auth/screens/login_screen.dart';
import 'package:sewa_kos/core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onProfileUpdated; // Callback untuk memberitahu shell ada update

  const ProfileScreen({super.key, required this.currentUser, required this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _displayUser; // User yang ditampilkan, bisa diupdate
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _displayUser = widget.currentUser; // Inisialisasi dari widget.currentUser
  }

  // Fungsi untuk mengupdate profil (simulasi atau panggil API update user)
  Future<void> _updateProfile() async {
    // TODO: Implementasi update profil ke API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur update profil akan segera hadir!')),
    );
    // Setelah update berhasil, panggil callback untuk memberitahu MainAppShell
    // widget.onProfileUpdated(); 
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppConstants.accentColor,
                      child: Text(
                        _displayUser.username[0].toUpperCase(), // Menggunakan _displayUser
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileInfoRow(Icons.person, 'Username', _displayUser.username),
                  _buildProfileInfoRow(Icons.email, 'Email', _displayUser.email),
                  if (_displayUser.namaLengkap != null && _displayUser.namaLengkap!.isNotEmpty)
                    _buildProfileInfoRow(Icons.badge, 'Nama Lengkap', _displayUser.namaLengkap!),
                  if (_displayUser.noTelepon != null && _displayUser.noTelepon!.isNotEmpty)
                    _buildProfileInfoRow(Icons.phone, 'Nomor Telepon', _displayUser.noTelepon!),
                  _buildProfileInfoRow(Icons.info_outline, 'Role', _displayUser.roleName.toUpperCase()),
                  const Divider(height: 40),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.errorColor,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textColorSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColorPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}