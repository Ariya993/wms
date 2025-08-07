import 'package:flutter/material.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_off, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Tidak ada koneksi internet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Periksa koneksi Anda dan coba lagi'),
          ],
        ),
      ),
    );
  }
}
