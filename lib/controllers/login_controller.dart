import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:network_info_plus/network_info_plus.dart'; 
import 'package:wms/main_common.dart';
import '../helper/endpoint.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'home_controller.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  RxString sessionId = ''.obs;
  var obscurePassword = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  final box = GetStorage();

  Future<void> loginUser() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Username dan Password is empty",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    isLoading.value = true;

    try {
      final url = Uri.parse(apiLoginWMS);
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text,
          'password': passwordController.text,
        }),
      );
      if (resp.statusCode == 200) {
        final result = jsonDecode(resp.body);
        await box.write('username', usernameController.text);
        await box.write('token', result['token']);
        await box.write('internalkey', result['internalKey']);
      try {
    await _sendFcmTokenToServer(usernameController.text);
  } catch (e) {
    debugPrint('Gagal kirim FCM token: $e');
  }

  // Kirim device info tapi juga jangan gagalkan login
  try {
    await sendDeviceInfoToBackend(result['internalKey']);
  } catch (e) {
    debugPrint('Gagal kirim device info: $e');
  }

        if (!Get.isRegistered<HomeController>()) {
          Get.put(HomeController());
        }
         Get.find<HomeController>().fetchData();
         
        Get.offNamed('/home');
      } else if (resp.statusCode == 401) {
        Get.snackbar(
          "Failed",
          "Invalid Username and Password",
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else if (resp.statusCode == 403) {
        Get.snackbar(
          "Failed",
          "Forbidden.. Please contact IT administrator",
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      } else {
        final Map<String, dynamic> errorData = jsonDecode(resp.body);
        Get.snackbar(
          "Failed",
          errorData['error']['message']['value'],
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print(e);
      Get.snackbar(
        "Error",
        "Gagal login: Koneksi ke server terputus",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Kirim token FCM ke server
  Future<void> _sendFcmTokenToServer(String username) async {
    String? fcmToken = "";
    String? platform = "";
    if (kIsWeb) {
     fcmToken = await FirebaseMessaging.instance.getToken(
        vapidKey: appEnvironment == Environment.dev
            ? 'BI7qGqr9oXMjuSm0c-pOCZT0tjp1muoVvujnylv_Il9SetT1sjfxsVXryVD6nFCfiHx4R6WR2drGe8lh6fh4MIA'
            : 'BHMcHDmIkSaB4le9XnSZQxQbmVkIQlnLoSI1yA1EiCjJ0ZHxAheoTZmtyafH4kzjbFuwdVFH1t-PhVcuAP0KK_k',
      );
      platform = 'web';
    } else {
      fcmToken = await FirebaseMessaging.instance.getToken();
      platform = 'mobile';
    }
    if (fcmToken == "") {
      Get.snackbar(
        "Error",
        "Failed get token FCM",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    box.write('fcmtoken', fcmToken); // Simpan token FCM ke GetStorage
    if (fcmToken != "") {
      final url = Uri.parse(
        apiFCMToken,
      ); // API endpoint untuk mengirim token FCM ke server
      final body = jsonEncode({
        "username": username,
        "Platform": platform, // Ambil username dari GetStorage
        "token_fcm": fcmToken,
      });

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: body,
        );

        if (response.statusCode == 200) {}
      } catch (e) {}
    }
  }

  Future<void> sendDeviceInfoToBackend(int userId) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final networkInfo = NetworkInfo();
    final box = GetStorage();

    String deviceModel = '';
    String osVersion = '';
    String platform = '';
    String ipLocal = '';
    String ipPublic = '';
    String androidId = '';
    if (kIsWeb) {
      // Untuk Web
      final webInfo = await deviceInfoPlugin.webBrowserInfo;
      deviceModel = webInfo.userAgent ?? 'Unknown Browser';
      osVersion = webInfo.appVersion ?? 'Unknown';
      platform = 'Web';
    } else {
      // Untuk Mobile/Desktop
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo; 
        deviceModel = androidInfo.model ?? 'Unknown';
        osVersion = androidInfo.version.release ?? 'Unknown';
        platform = 'Android'; 
        //print('id = ${PlatformDeviceId.getDeviceId}');
        // String? deviceId = await PlatformDeviceId.getDeviceId;
        // print('id = $deviceId');
        androidId = "${androidInfo.id}|${androidInfo.manufacturer}"?? 'Unknown';  

      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceModel = iosInfo.utsname.machine ?? 'Unknown';
        osVersion = iosInfo.systemVersion ?? 'Unknown';
        platform = 'iOS';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfoPlugin.windowsInfo;
        deviceModel = winInfo.computerName ?? 'Unknown';
        osVersion = '${winInfo.systemMemoryInMegabytes} MB';
        platform = 'Windows';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        deviceModel = macInfo.model ?? 'Mac';
        osVersion = macInfo.osRelease ?? 'Unknown';
        platform = 'macOS';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceModel = linuxInfo.name ?? 'Linux';
        osVersion = linuxInfo.version ?? 'Unknown';
        platform = 'Linux';
      }
    }

    // Simpan lokal jika mau
    box.write('device_model', deviceModel);
    box.write('os_version', osVersion);
    box.write('platform', platform);

    // 2. IP Lokal
    if(!kIsWeb)
    {
      ipLocal = await networkInfo.getWifiIP() ?? 'Unknown';
    }
    

    // 3. IP Publik
    final publicRes = await http.get(Uri.parse('https://api.ipify.org'));
    if (publicRes.statusCode == 200) {
      ipPublic = publicRes.body;
    }
    // Data yang dikirim ke backend
    final data = {
      'userId': userId,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'platform': platform,
      'androidId': androidId,
      'ipLocal': ipLocal,
      'ipPublic': ipPublic,
    };

    final token = box.read('token');
    final response = await http.post(
      Uri.parse(apiDeviceWMS),
      headers: {'Content-Type': 'application/json','Authorization' : 'Bearer $token'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      //print("Gagal kirim: ${response.statusCode} - ${response.body}");
      var err = json.decode(response.body);
      return (err);
    }
  }
}
