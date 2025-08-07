import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wms/helper/endpoint.dart';
import 'package:wms/pages/unsupported_version.dart';
import '../services/api_service.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
// import 'home_page.dart';
// import 'login_page.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  final box = GetStorage();
   String? currentVersion;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _checkAuthAndVersion);
  }

  Future<void> _checkAuthAndVersion() async {
    try {
      // Ambil versi aplikasi
      if (!kIsWeb)
      {
        final info = await PackageInfo.fromPlatform(); 
        setState(() {
          currentVersion = info.version.toString().substring(0, 5);
        });
      }
      // Ambil versi dari API
      final response = await http.get(Uri.parse(apiVersionWMS));
      print(response.statusCode);
      if (response.statusCode != 200) {
        Get.toNamed('/unsupported');
        return;
      }
 
        List<dynamic> data = json.decode(response.body); 
        print(data);
      String latestVersion = data[0]['version'] ?? '0';

      // Bandingkan versi
      if (!kIsWeb)
      {
        if (currentVersion.toString().substring(0, 5) != latestVersion.substring(0, 5)) {
        Get.toNamed('/unsupported');
        // Get.offAll(() =>  UnsupportedVersionPage());
        return;
      }
      }
      

      // Auth check
      final token = box.read('token');
      final expires = box.read('refreshTokenExpiryTime');

      if (token != null && expires != null) {
        final expire = DateTime.tryParse(expires);
        if (expire != null &&
            !DateTime.now().isBefore(expire.subtract(const Duration(seconds: 300)))) {
          await Get.find<ApiService>().refreshToken();
        } 
        Get.toNamed('/home');
        //Get.offAll(() =>   HomePage());
      } else {
         Get.toNamed('/login');
        // Get.offAll(() => LoginPage());
      }
    } catch (e) {
      print("Error during splash check: $e");
      Get.toNamed('/unsupported');
    }
  }
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              const Spacer(), 
            const Image(
              image: AssetImage('assets/splash.png'),
              width: 250,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            if (currentVersion != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Versi: $currentVersion',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
