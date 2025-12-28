// lib/features/shared_features/screens/profile_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart';
import 'package:sewa_kos/core/services/auth_service.dart';
import 'package:sewa_kos/features/auth/screens/login_screen.dart';
import 'package:sewa_kos/core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onProfileUpdated; // Callback jika profil diupdate

  const ProfileScreen(
      {super.key, required this.currentUser, required this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _displayUser;
  final AuthService _authService = AuthService();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _displayUser = widget.currentUser;
  }

  // Fungsi untuk menampilkan dialog edit profil
  Future<void> _showEditProfileDialog() async {
    final TextEditingController namaLengkapController =
        TextEditingController(text: _displayUser.namaLengkap);
    final TextEditingController noTeleponController =
        TextEditingController(text: _displayUser.noTelepon);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profil'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaLengkapController,
                    decoration:
                        const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'Nama Lengkap tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: noTeleponController,
                    decoration:
                        const InputDecoration(labelText: 'Nomor Telepon'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'Nomor Telepon tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Panggil fungsi update profil
                  await _updateProfile(
                    namaLengkap: namaLengkapController.text,
                    noTelepon: noTeleponController.text,
                  );
                  if (mounted) Navigator.pop(context); // Tutup dialog
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    // Refresh data pengguna setelah dialog ditutup (jika ada perubahan)
    widget.onProfileUpdated();
  }

  // Fungsi untuk mengupdate profil ke API
  Future<void> _updateProfile({String? namaLengkap, String? noTelepon}) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await _authService.updateUserProfile(
        userId: _displayUser.id,
        namaLengkap: namaLengkap,
        noTelepon: noTelepon,
      );

      if (mounted) {
        if (response['status'] == 'success') {
          // Setelah berhasil update di server, _saveUserData sudah dipanggil di AuthService
          // _displayUser akan diupdate saat MainAppShell memanggil onProfileUpdated dan refresh data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Profil berhasil diperbarui!'),
                backgroundColor: AppConstants.successColor),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Gagal memperbarui profil.'),
                backgroundColor: AppConstants.errorColor),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppConstants.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // Fungsi untuk logout
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
    // Pastikan _displayUser diperbarui jika widget.currentUser berubah
    // Ini penting jika _refreshUserData() di MainAppShell mengubah User objek
    if (widget.currentUser != _displayUser) {
      _displayUser = widget.currentUser;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                _isUpdating ? null : _showEditProfileDialog, // <-- Tombol Edit
            tooltip: 'Edit Profil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isUpdating ? null : _logout,
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
                        style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Informasi Akun
                  _buildProfileInfoCard(
                    context,
                    title: 'Informasi Akun',
                    children: [
                      _buildProfileInfoRow(
                          Icons.person, 'Username', _displayUser.username),
                      _buildProfileInfoRow(
                          Icons.email, 'Email', _displayUser.email),
                      _buildProfileInfoRow(Icons.info_outline, 'Role',
                          (_displayUser.roleName ?? 'User').toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  // Detail Pribadi
                  _buildProfileInfoCard(
                    context,
                    title: 'Detail Pribadi',
                    children: [
                      _buildProfileInfoRow(Icons.badge, 'Nama Lengkap',
                          _displayUser.namaLengkap ?? '- Belum diisi -'),
                      _buildProfileInfoRow(Icons.phone, 'Nomor Telepon',
                          _displayUser.noTelepon ?? '- Belum diisi -'),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.errorColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius),
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
  Widget _buildProfileInfoCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.defaultBorderRadius)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}
