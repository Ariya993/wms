import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UnsupportedVersionPage extends StatelessWidget {
  const UnsupportedVersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                "Versi Tidak Didukung",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Versi aplikasi ini tidak lagi didukung. "
                "Silakan hubungi IT Anda untuk mendapatkan versi terbaru.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Keluar aplikasi, atau arahkan ke Play Store
                  // Contoh: SystemNavigator.pop()
                  SystemNavigator.pop();
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Tutup Aplikasi"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
