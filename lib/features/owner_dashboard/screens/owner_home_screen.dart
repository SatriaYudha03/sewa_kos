// lib/features/owner_dashboard/screens/owner_home_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/services/auth_service.dart'; // Import AuthService
import 'package:sewa_kos/features/auth/screens/login_screen.dart'; // Import LoginScreen
import 'package:sewa_kos/core/models/user_model.dart'; // Import UserModel

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  User? _currentUser;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getLoggedInUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
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
        title: const Text('Dashboard Pemilik Kos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: _currentUser == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selamat datang, ${_currentUser!.namaLengkap ?? _currentUser!.username}!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Anda login sebagai: ${_currentUser!.roleName}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  // Di sini nanti akan ada konten utama untuk pemilik kos,
                  // seperti manajemen kos, daftar pemesanan masuk, dll.
                  ElevatedButton(
                    onPressed: () {
                      // Contoh: Navigasi ke halaman manajemen kos
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => MyKosScreen()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur manajemen kos akan segera hadir!')),
                      );
                    },
                    child: const Text('Kelola Kos Anda'),
                  ),
                ],
              ),
      ),
    );
  }
}