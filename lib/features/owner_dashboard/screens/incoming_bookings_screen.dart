// lib/features/owner_dashboard/screens/incoming_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:sewa_kos/core/constants/app_constants.dart'; // Sesuaikan import

class IncomingBookingsScreen extends StatelessWidget { // Pastikan nama kelasnya ini
  const IncomingBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemesanan Masuk'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Daftar pemesanan yang masuk untuk kos Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}