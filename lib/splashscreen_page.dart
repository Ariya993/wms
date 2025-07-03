import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _checkAuth);
  }

  Future<void> _checkAuth() async {
    final token = box.read('token');
    final expires = box.read('refreshTokenExpiryTime');

    if (token != null && expires != null) {
      final expire = DateTime.tryParse(expires);
      if (expire != null &&
          !DateTime.now().isBefore(expire.subtract(const Duration(seconds: 300)))) {
        await Get.find<ApiService>().refreshToken();
      }

      Get.offAll(() => const HomePage());
    } else {
      Get.offAll(() => LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: AssetImage('assets/splash.png'),
          width: 250,
        ),
      ),
    );
  }
}
