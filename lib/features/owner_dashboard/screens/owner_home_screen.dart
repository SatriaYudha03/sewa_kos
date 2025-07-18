// lib/features/owner_dashboard/screens/owner_home_screen.dart (DIUPDATE)
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/services/auth_service.dart'; // Sesuaikan import
import 'package:sewa_kos/features/auth/screens/login_screen.dart'; // Sesuaikan import
import 'package:sewa_kos/core/models/user_model.dart'; // Sesuaikan import
import 'package:sewa_kos/features/owner_dashboard/screens/my_kos_screen.dart'; // <-- Import MyKosScreen

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
                  ElevatedButton(
                    onPressed: () {
                      // Navigasi ke halaman manajemen kos saya
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyKosScreen()),
                      );
                    },
                    child: const Text('Kelola Kos Anda'),
                  ),
                  // Anda bisa menambahkan tombol lain di sini, seperti
                  // ElevatedButton(
                  //   onPressed: () { /* Navigasi ke daftar pemesanan masuk */ },
                  //   child: const Text('Lihat Pemesanan Masuk'),
                  // ),
                ],
              ),
      ),
    );
  }
}