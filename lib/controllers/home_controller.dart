import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:wms/helper/endpoint.dart';
 
import '../helper/encrypt.dart';
import '../services/sap_service.dart';

class HomeController extends GetxController {
  // final menus = [].obs;
  final isLoading = true.obs;
  final box = GetStorage();
  final SAPService _apiService = Get.find<SAPService>();
  final RxList<Map<String, dynamic>> menus = <Map<String, dynamic>>[].obs;
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
        final List<dynamic> rawData = json.decode(response.body);
        final List<Map<String, dynamic>> allMenus =
            rawData.cast<Map<String, dynamic>>();

        // Filter hanya yang akses == 1
        final List<Map<String, dynamic>> filteredMenus =
            allMenus.where((menu) => menu['akses'] == 1).toList();

        // Simpan ke observable jika kamu pakai GetX
        menus.value = filteredMenus;
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
         box.write('warehouse_name', data[0]['WarehouseName']);
        box.write('warehouse_code', data[0]['warehouse_code']);
        box.write('bpl_id', data[0]['BusinessPlaceID']);
        box.write('id_atasan', data[0]['id_atasan']);
        box.write('refreshToken', data[0]['RefreshToken']);
        box.write('refreshTokenExpiryTime', data[0]['RefreshTokenExpiryTime']);
         
        await box.save();
        final warehouseName = data[0]['WarehouseName'] ?? '';
        final cek = await fetchConfigUser(); // Pastikan SAP credential sudah siap
        if (!cek) {
          Get.snackbar(
            "Invalid Authorization ($warehouseName)",
            "Please setting warehouse authorization.",
            snackPosition: SnackPosition.TOP,
            snackStyle: SnackStyle.FLOATING,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          box.erase();
          Get.offAllNamed('/login');
          return;
        } 

        await Future.delayed(Duration(milliseconds: 300));
        // await fetchConfig();

        // await Future.delayed(Duration(milliseconds: 300));
        final sapLoginSuccess = await _apiService.LoginSAP(); // Coba login SAP
        if (!sapLoginSuccess) {
          Get.snackbar(
            "SAP Login",
            "Failed login to SAP. Some features may be limited.",
            snackPosition: SnackPosition.TOP,
            snackStyle: SnackStyle.FLOATING,
            backgroundColor: Colors.orangeAccent,
            colorText: Colors.blueGrey,
          );
          // Tapi kita tetap lanjut
        }
        await Future.delayed(Duration(milliseconds: 300));
        await fetchMenus();
      } else {
        Get.snackbar(
          "Error",
          "Failed to load menu: ${response.statusCode}",
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      return Future.error("Something went wrong: $e");
    } finally {
      isLoading.value = false; // Selesai proses fetchConfig
    }
  }

  Future<void> fetchConfig() async {
    try {
      // isLoading.value = true;
      final url = Uri.parse('$apiKonfigurasiWMS');
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
        await box.save();
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load config: $e",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
    // finally {
    //   isLoading.value = false; // Selesai proses fetchConfig
    // }
  }

  Future<bool> fetchConfigUser() async {
    try {
      // isLoading.value = true;
      final url = Uri.parse('$apiWarehouseWMS/code'); // Contoh endpoint

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'warehouse_code': box.read('warehouse_code')}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          return false;
        }
        var decPass = AESHelper.decryptData(data['sap_password']);
        //  print (decPass);
        // Menyimpan data ke GetStorage
        box.write('sap_username', data['sap_username']);
        box.write('sap_password', decPass);
        box.write('sap_db_name', data['sap_db_name']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
    // finally {
    //   isLoading.value = false; // Selesai proses fetchConfig
    // }
  }


  
}
