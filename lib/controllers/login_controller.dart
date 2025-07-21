import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../helper/endpoint.dart';

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
      Get.snackbar("Error", "Username dan Password is empty",
          snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
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
           await _sendFcmTokenToServer(usernameController.text);
          Get.offNamed('/home');
        } else  if (resp.statusCode == 401) {
         Get.snackbar("Failed", "Invalid Username and Password",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
        } else if (resp.statusCode == 403) {
          Get.snackbar("Failed", "Forbidden.. Please contact IT administrator",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
        } else {
          final Map<String, dynamic> errorData = jsonDecode(resp.body);
          Get.snackbar("Failed", errorData['error']['message']['value'],snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
        }
      
    } catch (e) {
      Get.snackbar("Error", "Gagal login: Koneksi ke server terputus",
          snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Kirim token FCM ke server
  Future<void> _sendFcmTokenToServer(String username) async {
    String? fcmToken = "";
    if (kIsWeb) {
      fcmToken = await FirebaseMessaging.instance.getToken(
        vapidKey: 'BHMcHDmIkSaB4le9XnSZQxQbmVkIQlnLoSI1yA1EiCjJ0ZHxAheoTZmtyafH4kzjbFuwdVFH1t-PhVcuAP0KK_k',
      );
    } else {
      fcmToken = await FirebaseMessaging.instance.getToken();
    }
    if (fcmToken == "") {
      Get.snackbar("Error", "Failed get token FCM",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    
    box.write('fcmtoken', fcmToken); // Simpan token FCM ke GetStorage
    if (fcmToken != "") {
      final url = Uri.parse(
        apiFCMToken,
      ); // API endpoint untuk mengirim token FCM ke server
      final body = jsonEncode({
        "username": username, // Ambil username dari GetStorage
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
}
