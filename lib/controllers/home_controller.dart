import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:wms/helper/endpoint.dart';

import '../services/sap_service.dart';

class HomeController extends GetxController {
  final menus = [].obs;
  final isLoading = true.obs;
  final box = GetStorage();
  final SAPService _apiService = Get.find<SAPService>();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void logout() {
    box.erase(); // hapus semua
    Get.offAllNamed('/login');
  }

  Future<void> fetchMenus() async {
    try {
      // isLoading.value = true;
     

      final url = Uri.parse('$apiMenuWMS/${box.read('internalkey')}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${box.read('token') ?? ''}',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        menus.value = json.decode(response.body);
      } else {
        Get.snackbar("Error", "Failed to load menu: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
    } 
    // finally {
    //   isLoading.value = false;
    // }
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      final url = Uri.parse('$apiUserWMS/${box.read('internalkey')}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${box.read('token') ?? ''}',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        box.write('warehouse_code', data[0]['warehouse_code']);
        box.write('bpl_id', data[0]['BusinessPlaceID']);
        box.write('id_atasan', data[0]['id_atasan']);
        box.write('refreshToken', data[0]['RefreshToken']);
        box.write('refreshTokenExpiryTime', data[0]['RefreshTokenExpiryTime']);

        await fetchConfig(); // Pastikan SAP credential sudah siap
       final sapLoginSuccess = await _apiService.LoginSAP(); // Coba login SAP
        if (!sapLoginSuccess) {
          Get.snackbar("SAP Login", "Failed login to SAP. Some features may be limited.",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.orangeAccent, colorText: Colors.blueGrey);
          // Tapi kita tetap lanjut
        }
        await fetchMenus();
       
        // await Future.wait([fetchMenus(), fetchConfig()]);
        // await _apiService.LoginSAP();
      } else {
        Get.snackbar("Error", "Failed to load menu: ${response.statusCode}",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      return Future.error("Something went wrong: $e");
    }
    finally {
      isLoading.value = false; // Selesai proses fetchConfig
    }
  }

  Future<void> fetchConfig() async {
    try {
      // isLoading.value = true;
      final url = Uri.parse('$apiKonfigurasiWMS'); // Contoh endpoint
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        box.write('sap_username', data[0]['sap_username']);  
        box.write('sap_password', data[0]['sap_password']);  
        box.write('sap_db_name', data[0]['sap_db_name']);  
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load config: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    } 
    // finally {
    //   isLoading.value = false; // Selesai proses fetchConfig
    // }
  }


}
