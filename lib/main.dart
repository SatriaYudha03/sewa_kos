// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Pastikan sudah ada di pubspec.yaml
import 'package:sewa_kos/core/services/auth_service.dart'; // Import AuthService
import 'package:sewa_kos/features/auth/screens/login_screen.dart'; // Import LoginScreen
import 'package:sewa_kos/features/shared_features/screens/main_app_shell.dart'; // Import MainAppShell
import 'package:sewa_kos/core/models/user_model.dart'; // Import UserModel

void main() {
  // Pastikan Flutter binding terinisialisasi sebelum mengakses platform services
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const SewaKosApp());
}

class SewaKosApp extends StatelessWidget {
  const SewaKosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Sewa Kos',
      debugShowCheckedModeBanner: false, // Untuk menyembunyikan banner "DEBUG"
      theme: ThemeData(
        primarySwatch: Colors.blue, // Tema warna utama aplikasi
        visualDensity: VisualDensity.adaptivePlatformDensity, // Mengatur kepadatan visual sesuai platform
      ),
      home: const SplashScreen(), // Aplikasi dimulai dari SplashScreen
      // Named routes (opsional, tapi bagus untuk navigasi kompleks)
      routes: {
        '/login': (context) => const LoginScreen(),
        // Rute lain bisa ditambahkan di sini, misalnya untuk register jika tidak langsung dari login
        // '/register': (context) => const RegisterScreen(), 
      },
    );
  }
}

// ======================= SPLASH SCREEN ==========================
// Widget SplashScreen untuk menampilkan animasi pembuka
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin { // Mixin untuk AnimationController
  late AnimationController _controller;
  late Animation<double> _pinDropAnimation;
  late Animation<double> _pinBounceAnimation;
  late Animation<double> _circleScaleAnimation;
  late Animation<double> _houseFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  final AuthService _authService = AuthService(); // Instance AuthService untuk cek login

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000), // Total durasi animasi
      vsync: this, // Menghubungkan controller dengan VSync provider
    );

    // Fase 1: Pin Jatuh (0% - 40% durasi)
    _pinDropAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    // Efek memantul untuk pin
    _pinBounceAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval( // Hapus 'const' karena .flipped bukanlah konstanta kompilasi
        0.0,
        0.4,
        curve: Curves.elasticOut.flipped, // Efek memantul terbalik
      ),
    );

    // Fase 2: Lingkaran Membesar & Pin Menghilang (30% - 60% durasi)
    _circleScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
    );

    // Fase 3: Rumah dan Teks Muncul (50% - 90% durasi)
    _houseFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Mulai dari bawah sedikit
      end: Offset.zero, // Berakhir di posisi aslinya
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );

    // Tambahkan listener untuk navigasi setelah animasi selesai
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen(); // Panggil fungsi navigasi
      }
    });

    _controller.forward(); // Mulai animasi
  }

  // Fungsi untuk mengecek status login dan navigasi ke layar selanjutnya
  Future<void> _navigateToNextScreen() async {
    final user = await _authService.getLoggedInUser(); // Cek user yang tersimpan
    Widget nextScreen; // Widget layar tujuan

    if (user != null) {
      // Jika user sudah login, arahkan ke MainAppShell dengan data user
      nextScreen = MainAppShell(initialUserData: user); 
    } else {
      // Jika user belum login, arahkan ke LoginScreen
      nextScreen = const LoginScreen();
    }

    // Navigasi ke layar berikutnya dan hapus semua rute sebelumnya dari stack
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child); // Transisi fade
        },
        transitionDuration: const Duration(milliseconds: 800), // Durasi transisi
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Pastikan controller di-dispose
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
                // Elemen Branding (Teks "SewaKos" dan slogan)
                Positioned(
                  top: screenHeight / 2 + 80, // Posisikan di bawah logo
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
                              const Text( // Menggunakan const jika teks statis
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
                          const Text(
                            "Temukan Kos Impianmu",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white, // Gunakan Colors.white langsung atau withOpacity
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Elemen Logo (Pin, Lingkaran, Rumah)
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lingkaran yang membesar
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
                      // Ikon rumah di dalam lingkaran
                      FadeTransition(
                        opacity: _houseFadeAnimation,
                        child: Icon(
                          Icons.home_rounded,
                          size: 70,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      // Ikon Pin Lokasi yang jatuh
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