// lib/features/shared_features/screens/profile_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/services/auth_service.dart'; // Import AuthService
import 'package:sewa_kos/features/auth/screens/login_screen.dart'; // Import LoginScreen
import 'package:sewa_kos/core/models/user_model.dart'; // Import UserModel

class ProfileScreen extends StatefulWidget {
  final User currentUser; // Data user yang diterima dari MainAppShell
  final VoidCallback onProfileUpdated; // Callback jika profil diupdate (misal setelah edit)

  const ProfileScreen({super.key, required this.currentUser, required this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _displayUser; // User yang ditampilkan, bisa diupdate
  final AuthService _authService = AuthService();
  bool _isUpdating = false; // State untuk proses update profil (jika ada)

  @override
  void initState() {
    super.initState();
    _displayUser = widget.currentUser; // Inisialisasi dari widget.currentUser
  }

  // Fungsi untuk mengupdate profil (placeholder/simulasi)
  // Ini akan memanggil API /users/update_profile.php jika Anda membuatnya
  Future<void> _updateProfile() async {
    setState(() {
      _isUpdating = true;
    });
    // TODO: Implementasi update profil ke API
    // Misalnya:
    // final response = await _authService.updateUserProfile(
    //   userId: _displayUser.id,
    //   namaLengkap: newNamaLengkap,
    //   noTelepon: newNoTelepon,
    // );
    // if (response['status'] == 'success') {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Profil berhasil diupdate!')),
    //   );
    //   widget.onProfileUpdated(); // Panggil callback untuk refresh data di MainAppShell
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text(response['message'])),
    //   );
    // }

    await Future.delayed(const Duration(seconds: 1)); // Simulasi delay API

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur update profil akan segera hadir!')),
      );
    }
  }

  // Fungsi untuk logout
  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Hapus semua rute di bawahnya
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isUpdating ? null : _updateProfile, // Tombol edit/update
            tooltip: 'Edit Profil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isUpdating ? null : _logout, // Tombol logout
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppConstants.accentColor,
                      child: Text(
                        _displayUser.username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Informasi Profil
                  _buildProfileInfoCard(
                    context,
                    title: 'Informasi Akun',
                    children: [
                      _buildProfileInfoRow(Icons.person, 'Username', _displayUser.username),
                      _buildProfileInfoRow(Icons.email, 'Email', _displayUser.email),
                      _buildProfileInfoRow(Icons.info_outline, 'Role', _displayUser.roleName.toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildProfileInfoCard(
                    context,
                    title: 'Detail Pribadi',
                    children: [
                      _buildProfileInfoRow(Icons.badge, 'Nama Lengkap', _displayUser.namaLengkap ?? '- Belum diisi -'),
                      _buildProfileInfoRow(Icons.phone, 'Nomor Telepon', _displayUser.noTelepon ?? '- Belum diisi -'),
                    ],
                  ),
                  const Spacer(), // Mendorong logout ke bawah
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.errorColor,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper untuk baris informasi profil
  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat card informasi profil
  Widget _buildProfileInfoCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            ...children, // Memasukkan baris informasi
          ],
        ),
      ),
    );
  }
}