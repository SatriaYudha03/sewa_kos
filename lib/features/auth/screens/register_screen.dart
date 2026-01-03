// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart'; // Sesuaikan path import jika perlu

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _namaLengkapController = TextEditingController();
  final TextEditingController _noTeleponController = TextEditingController();

  String _selectedRole = 'penyewa'; // Default role
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  // State untuk mengontrol visibilitas password
  bool _isPasswordVisible = false; // <-- Deklarasi di sini

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final namaLengkap = _namaLengkapController.text.trim();
    final noTelepon = _noTeleponController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Semua field wajib diisi.';
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Password dan konfirmasi password tidak cocok.';
        _isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      // Contoh validasi password
      setState(() {
        _errorMessage = 'Password minimal 6 karakter.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
        role: _selectedRole,
        namaLengkap: namaLengkap.isNotEmpty ? namaLengkap : null,
        noTelepon: noTelepon.isNotEmpty ? noTelepon : null,
      );

      if (!mounted) return; // Penting: Cek mounted sebelum setState

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Registrasi berhasil!'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke LoginScreen
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Terjadi kesalahan saat registrasi.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal terhubung ke server: ${e.toString()}';
      });
    } finally {
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
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
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
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              color: Colors.white.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 50,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Buat Akun Baru",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Daftar untuk menemukan atau menyewakan kos.",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      _buildTextField(
                          _usernameController, 'Username', Icons.person),
                      const SizedBox(height: 15),
                      _buildTextField(_emailController, 'Email', Icons.email,
                          TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      // Panggilan untuk password field, meneruskan state dan callback
                      _buildTextField(
                        _passwordController,
                        'Password',
                        Icons.lock,
                        null,
                        true, // isPassword: true
                        _isPasswordVisible, // currentPasswordVisibility
                        () {
                          // togglePasswordVisibility
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      // Panggilan untuk konfirmasi password field, menggunakan state dan callback yang sama
                      _buildTextField(
                        _confirmPasswordController,
                        'Konfirmasi Password',
                        Icons.lock,
                        null,
                        true, // isPassword: true
                        _isPasswordVisible, // currentPasswordVisibility (sama dengan password)
                        () {
                          // togglePasswordVisibility (sama dengan password)
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(_namaLengkapController,
                          'Nama Lengkap (Opsional)', Icons.badge),
                      const SizedBox(height: 15),
                      _buildTextField(
                          _noTeleponController,
                          'Nomor Telepon (Opsional)',
                          Icons.phone,
                          TextInputType.phone),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Daftar sebagai',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.group),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'penyewa', child: Text('Penyewa Kos')),
                          DropdownMenuItem(
                              value: 'pemilik_kos', child: Text('Pemilik Kos')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 10),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'DAFTAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for common TextField styling
  Widget _buildTextField(
    TextEditingController controller,
    String labelText,
    IconData icon, [
    TextInputType? keyboardType,
    bool isPassword = false, // Menentukan apakah ini field password
    bool? currentPasswordVisibility, // State visibilitas password saat ini
    VoidCallback?
        togglePasswordVisibility, // Callback untuk mengubah visibilitas password
  ]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      // Obscure text hanya jika ini field password DAN visibilitasnya TIDAK aktif
      obscureText: isPassword && !(currentPasswordVisibility ?? false),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        // Suffix icon hanya untuk field password
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (currentPasswordVisibility ?? false)
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed:
                    togglePasswordVisibility, // Menggunakan callback yang diteruskan
              )
            : null,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          if (labelText.contains('(Opsional)')) {
            return null; // Untuk field opsional, tidak perlu validasi jika kosong
          }
          return '$labelText tidak boleh kosong';
        }
        if (labelText == 'Email' &&
            !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
          return 'Masukkan format email yang valid';
        }
        // Tambahkan validasi password khusus jika diperlukan di sini (selain panjang di _register())
        return null;
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _namaLengkapController.dispose();
    _noTeleponController.dispose();
    super.dispose();
  }
}
