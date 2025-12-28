// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/models/user_model.dart'; // Import UserModel
import 'package:sewa_kos/core/services/auth_service.dart'; // Import AuthService
import 'package:sewa_kos/features/shared_features/screens/main_app_shell.dart'; // Import MainAppShell (dashboard utama)
import 'package:sewa_kos/features/auth/screens/register_screen.dart'; // Import RegisterScreen
import 'package:sewa_kos/core/constants/app_constants.dart'; // Import AppConstants

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin { // Mixin untuk AnimationController
  final _formKey = GlobalKey<FormState>(); // Kunci untuk form validation
  final TextEditingController _usernameEmailController = TextEditingController(); // Controller untuk input username/email
  final TextEditingController _passwordController = TextEditingController();     // Controller untuk input password

  bool _isLoading = false; // Status loading saat proses login
  bool _isPasswordVisible = false; // Status visibilitas password

  late AnimationController _controller; // Controller untuk animasi
  late Animation<double> _fadeAnimation; // Animasi fade
  late Animation<Offset> _slideAnimation; // Animasi slide

  final AuthService _authService = AuthService(); // Instance AuthService untuk komunikasi API

  @override
  void initState() {
    super.initState();
    // Setup AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), // Durasi animasi
      vsync: this, // Menghubungkan controller dengan VSync provider
    );

    // Setup Fade Animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Setup Slide Animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Mulai dari bawah
      end: Offset.zero, // Berakhir di posisi asli
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(); // Mulai animasi saat widget diinisialisasi
  }

  @override
  void dispose() {
    _controller.dispose(); // Pastikan AnimationController di-dispose
    _usernameEmailController.dispose(); // Pastikan TextEditingController di-dispose
    _passwordController.dispose();     // Pastikan TextEditingController di-dispose
    super.dispose();
  }

  // Fungsi helper untuk membuat rute dengan transisi fade
  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // Fungsi untuk menangani proses login
  void _login() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Set loading true saat proses dimulai
    });

    final usernameEmail = _usernameEmailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await _authService.login(usernameEmail, password);

      // Pastikan widget masih mounted sebelum memanggil setState
      if (!mounted) return;

      setState(() {
        _isLoading = false; // Set loading false setelah proses selesai
      });

      if (response['status'] == 'success') {
        // Tampilkan SnackBar sukses
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(response['message']!),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppConstants.successColor, // Menggunakan konstanta warna
            ),
          );

        final User? user = response['user']; // Ambil objek User dari respon

        if (user != null) {
          // Navigasi ke MainAppShell dan hapus semua rute sebelumnya dari stack
          Navigator.pushAndRemoveUntil(
            context,
            _createFadeRoute(MainAppShell(initialUserData: user)), // Kirim objek User
            (route) => false,
          );
        } else {
             // Ini seharusnya tidak terjadi jika status 'success' tapi user null
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Data pengguna tidak ditemukan setelah login berhasil.'),
                    backgroundColor: AppConstants.errorColor, // Menggunakan konstanta warna
                ),
            );
        }
      } else {
        // Login gagal, tampilkan pesan error dari API
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? AppConstants.loginFailedMessage), // Menggunakan konstanta pesan
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppConstants.errorColor, // Menggunakan konstanta warna
            ),
          );
      }
    } catch (e) {
      // Tangani error jaringan atau error lain dari AuthService
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'), // Tampilkan pesan error dari exception
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: AppConstants.errorColor, // Menggunakan konstanta warna
          ),
        );
    } finally {
      // Pastikan loading dimatikan bahkan jika ada error tak terduga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding), // Menggunakan konstanta padding
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius), // Menggunakan konstanta border radius
                  ),
                  elevation: 16,
                  shadowColor: Colors.black.withOpacity(0.5),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey, // Menggunakan GlobalKey untuk form
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_work_rounded,
                              size: 50,
                              color: AppConstants.primaryColor, // Menggunakan konstanta warna
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Selamat Datang di ${AppConstants.appName}", // Menggunakan konstanta nama aplikasi
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textColorPrimary, // Menggunakan konstanta warna
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Masuk untuk melanjutkan",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppConstants.textColorSecondary), // Menggunakan konstanta warna
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _usernameEmailController,
                              decoration: InputDecoration(
                                labelText: 'Username atau Email',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Username atau Email tidak boleh kosong' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible, // Mengontrol visibilitas password
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                                  },
                                ),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Password tidak boleh kosong' : null,
                            ),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: _isLoading // Menampilkan CircularProgressIndicator saat loading
                                  ? const CircularProgressIndicator(
                                      key: ValueKey('loader'), // Kunci untuk AnimatedSwitcher
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        key: const ValueKey('button'), // Kunci untuk AnimatedSwitcher
                                        onPressed: _login, // Panggil fungsi login
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppConstants.primaryColor, // Menggunakan konstanta warna
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                          ),
                                          elevation: 5,
                                        ),
                                        child: const Text(
                                          "LOGIN",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading // Nonaktifkan tombol saat loading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        _createFadeRoute(const RegisterScreen()), // Navigasi ke RegisterScreen
                                      );
                                    },
                              child: const Text("Belum punya akun? Daftar di sini"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}