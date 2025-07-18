// lib/features/shared_features/screens/main_app_shell.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/models/user_model.dart'; // Import UserModel
import 'package:sewa_kos/core/services/auth_service.dart'; // Import AuthService
import 'package:sewa_kos/features/auth/screens/login_screen.dart'; // Import LoginScreen
import 'package:sewa_kos/core/constants/app_constants.dart'; // Import AppConstants

// Import halaman-halaman yang akan menjadi tab
// Untuk penyewa
import 'package:sewa_kos/features/tenant_dashboard/screens/kos_list_screen.dart'; // Akan dibuat: Daftar Kos untuk Penyewa
import 'package:sewa_kos/features/tenant_dashboard/screens/booking_history_screen.dart'; // Akan dibuat: Riwayat Pemesanan Penyewa
import 'package:sewa_kos/features/shared_features/screens/profile_screen.dart'; // Akan dibuat: Profil umum untuk kedua role

// Untuk pemilik kos
import 'package:sewa_kos/features/owner_dashboard/screens/my_kos_screen.dart'; // Sudah ada: Kos Saya
import 'package:sewa_kos/features/owner_dashboard/screens/incoming_bookings_screen.dart'; // Sudah ada: Pemesanan Masuk
// OwnerProfileScreen akan diganti dengan ProfileScreen (umum)

class MainAppShell extends StatefulWidget {
  final User initialUserData; // Data user saat login

  const MainAppShell({super.key, required this.initialUserData});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _pageIndex = 0;
  late User _currentUserData; // State untuk menyimpan data pengguna yang bisa di-update
  late List<Widget> _pages; // Daftar halaman/tab yang dinamis

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.initialUserData; // Inisialisasi dengan data awal
    _initializePages(); // Inisialisasi daftar halaman berdasarkan role
  }

  // Inisialisasi daftar halaman berdasarkan role pengguna
  void _initializePages() {
    if (_currentUserData.roleName == 'penyewa') {
      _pages = [
        const KosListScreen(), // Untuk mencari kos
        const BookingHistoryScreen(), // Riwayat pemesanan penyewa
        ProfileScreen(currentUser: _currentUserData, onProfileUpdated: _refreshUserData), // Profil umum
      ];
    } else if (_currentUserData.roleName == 'pemilik_kos') {
      _pages = [
        const MyKosScreen(), // Kos Saya
        const IncomingBookingsScreen(), // Pemesanan Masuk
        ProfileScreen(currentUser: _currentUserData, onProfileUpdated: _refreshUserData), // Profil umum
      ];
    } else {
      _pages = [
        const Text('Role tidak dikenal atau halaman tidak ditemukan.'), // Fallback
      ];
    }
  }

  // Fungsi untuk me-refresh data PADA LEVEL MainAppShell (jika profil diupdate)
  Future<void> _refreshUserData() async {
    try {
      final updatedUser = await _authService.getUserProfile(_currentUserData.id);
      if (mounted && updatedUser != null) {
        setState(() {
          _currentUserData = updatedUser; // Perbarui data user
          // Re-initialize pages to pass updated data (if needed by ProfileScreen)
          _initializePages(); 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      } else if (mounted && updatedUser == null) {
        // Jika gagal refresh, mungkin token expired atau masalah lain, logout saja
        _logout();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat ulang data profil: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  // Fungsi logout
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
    // Tentukan item BottomNavigationBar secara dinamis berdasarkan role
    List<BottomNavigationBarItem> navBarItems = [];
    if (_currentUserData.roleName == 'penyewa') {
      navBarItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari Kos'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else if (_currentUserData.roleName == 'pemilik_kos') {
      navBarItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_work), label: 'Kos Saya'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Pemesanan'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }

    return Scaffold(
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _pageIndex,
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        items: navBarItems, // Menggunakan item yang dinamis
      ),
    );
  }
}