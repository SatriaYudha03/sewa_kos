// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Pastikan sudah di pubspec.yaml

import 'core/services/auth_service.dart'; // Import AuthService
import 'features/auth/screens/login_screen.dart'; // Import LoginScreen
import 'features/tenant_dashboard/screens/tenant_home_screen.dart'; // Akan dibuat nanti
import 'features/owner_dashboard/screens/owner_home_screen.dart';   // Akan dibuat nanti
import 'core/models/user_model.dart'; // Import UserModel

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Penting untuk inisialisasi SharedPreferences
  runApp(const SewaKosApp());
}

class SewaKosApp extends StatelessWidget {
  const SewaKosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sewa Kos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue, // Sesuaikan dengan tema aplikasi Anda
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(), // Mulai dengan SplashScreen
      // Named routes (opsional, tapi bagus untuk navigasi kompleks)
      routes: {
        '/login': (context) => const LoginScreen(),
        // Anda bisa menambahkan rute untuk register_screen, home_penyewa, home_pemilik di sini
        // '/register': (context) => const RegisterScreen(),
        // '/tenant_home': (context) => const TenantHomeScreen(),
        // '/owner_home': (context) => const OwnerHomeScreen(),
      },
    );
  }
}

// ======================= SPLASH SCREEN ==========================
// Kita ambil SplashScreen dari kode teman Anda dan sesuaikan
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pinDropAnimation;
  late Animation<double> _pinBounceAnimation;
  late Animation<double> _circleScaleAnimation;
  late Animation<double> _houseFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000), // Total durasi animasi
      vsync: this,
    );

    // ... (Animasi lainnya tetap sama seperti kode teman Anda)
    // Fase 1: Pin Jatuh dan Memantul (0ms - 1200ms)
    _pinDropAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _pinBounceAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.0,
        0.4,
        curve: Curves.elasticOut.flipped,
      ), // Efek memantul
    );

    // Fase 2: Lingkaran Membesar & Pin Menghilang (1000ms - 1800ms)
    _circleScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
    );

    // Fase 3: Rumah dan Teks Muncul (1500ms - 2500ms)
    _houseFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );

    // Menjalankan navigasi setelah animasi selesai
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Pindahkan logika pengecekan login di sini
        _navigateToNextScreen();
      }
    });

    // Mulai animasi
    _controller.forward();
  }

  // --- Fungsi Baru: Mengecek status login dan navigasi ---
  Future<void> _navigateToNextScreen() async {
    final user = await _authService.getLoggedInUser();
    Widget nextScreen;

    if (user != null) {
      // User sudah login, arahkan ke dashboard sesuai role
      if (user.roleName == 'penyewa') {
        nextScreen = const TenantHomeScreen();
      } else if (user.roleName == 'pemilik_kos') {
        nextScreen = const OwnerHomeScreen();
      } else {
        // Fallback jika role tidak dikenali (jarang terjadi jika role dibatasi di registrasi)
        nextScreen = const LoginScreen();
      }
    } else {
      // User belum login, arahkan ke LoginScreen
      nextScreen = const LoginScreen();
    }

    // Navigasi dengan transisi fade
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: screenHeight / 2 + 80,
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SlideTransition(
                      position: _textSlideAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Sewa",
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                "Kos",
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Temukan Kos Impianmu",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: _circleScaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: _houseFadeAnimation,
                        child: Icon(
                          Icons.home_rounded,
                          size: 70,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            (-screenHeight / 2) +
                                (_pinDropAnimation.value * (screenHeight / 2)) -
                                (_pinBounceAnimation.value * 30),
                          ),
                          child: Opacity(
                            opacity: 1.0 - _circleScaleAnimation.value,
                            child: Icon(
                              Icons.location_on,
                              size: 120,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}