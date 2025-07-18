// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/models/user_model.dart'; // Tambahkan ini
import '../../../core/services/auth_service.dart'; // Sesuaikan path import
import '../../tenant_dashboard/screens/tenant_home_screen.dart'; // Akan dibuat
import '../../owner_dashboard/screens/owner_home_screen.dart';   // Akan dibuat
import 'register_screen.dart'; // Import register screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Gunakan super.key

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin { // Tambahkan SingleTickerProviderStateMixin untuk animasi
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameEmailController = TextEditingController(); // Gunakan TextEditingController
  final TextEditingController _passwordController = TextEditingController(); // Gunakan TextEditingController

  bool loading = false;
  bool _isPasswordVisible = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameEmailController.dispose(); // Jangan lupa dispose controller
    _passwordController.dispose();     // Jangan lupa dispose controller
    super.dispose();
  }

  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final usernameEmail = _usernameEmailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await _authService.login(usernameEmail, password);

      // Cek jika widget masih ada di tree sebelum update state
      if (!mounted) return;

      setState(() => loading = false);

      if (response['status'] == 'success') {
        // Login berhasil, tampilkan SnackBar
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(response['message']!),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.green,
            ),
          );

        final User? user = response['user']; // Response['user'] sudah berupa objek User

        if (user != null) {
          if (user.roleName == 'penyewa') {
            Navigator.pushAndRemoveUntil(
              context,
              _createFadeRoute(const TenantHomeScreen()), // Arahkan ke TenantHome
              (route) => false,
            );
          } else if (user.roleName == 'pemilik_kos') {
            Navigator.pushAndRemoveUntil(
              context,
              _createFadeRoute(const OwnerHomeScreen()), // Arahkan ke OwnerHome
              (route) => false,
            );
          }
        } else {
             // Ini seharusnya tidak terjadi jika 'success'
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Data pengguna tidak ditemukan setelah login berhasil.'),
                    backgroundColor: Colors.orange,
                ),
            );
        }
      } else {
        // Login gagal, tampilkan pesan error dari API
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Terjadi kesalahan saat login.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      // Error jaringan atau error lain dari AuthService
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'), // Tampilkan pesan error dari exception
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => loading = false);
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
            padding: const EdgeInsets.all(24),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home_work_rounded,
                              size: 50,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Selamat Datang di SewaKos",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Masuk untuk melanjutkan",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _usernameEmailController, // Gunakan Controller
                              decoration: InputDecoration(
                                labelText: 'Username atau Email', // Sesuaikan label
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Username atau Email tidak boleh kosong' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController, // Gunakan Controller
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                              child: loading
                                  ? const CircularProgressIndicator(
                                      key: ValueKey('loader'),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        key: const ValueKey('button'),
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade600,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
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
                              onPressed: loading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        _createFadeRoute(const RegisterScreen()), // Gunakan const
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