import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../helper/encrypt.dart';
import '../services/api_service.dart';

class WarehouseAuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  RxBool isLoading = false.obs;

  // Variabel untuk inputan SAP credentials
  var sapDbName = ''.obs;
var sapUsername = ''.obs;
var sapPassword = ''.obs;
  var warehouseUsernames = <String, String>{}.obs;
  var warehousePasswords = <String, String>{}.obs;

  final box = GetStorage();

  // List untuk menyimpan data warehouse
  var warehouses = <dynamic>[].obs;
  var filteredWarehouses = <dynamic>[].obs;

  String getUsername(String warehouseCode) {
    return warehouseUsernames[warehouseCode] ?? '';
  }

  String getPassword(String warehouseCode) {
    return warehousePasswords[warehouseCode] ?? '';
  }

  void setUsername(String warehouseCode, String username) {
    warehouseUsernames[warehouseCode] = username;
  }

  void setPassword(String warehouseCode, String password) {
    warehousePasswords[warehouseCode] = password;
  }

  @override
  void onInit() {
    super.onInit();
    loadWarehouses();
  }

  void loadWarehouses() async {
    isLoading.value = true;
    try {
      final fetchedWarehouses = await _apiService.getWarehouses();
      warehouses.value = fetchedWarehouses;
      filteredWarehouses.value =
          fetchedWarehouses; // Default filter is all warehouses
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load warehouse: $e",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi filter untuk mencari warehouse
  void filterWarehouses(String query) {
    if (query.isEmpty) {
      filteredWarehouses.value = warehouses;
    } else {
      filteredWarehouses.value =
          warehouses.where((warehouse) {
            return warehouse['warehouseName'].toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                warehouse['warehouseCode'].toLowerCase().contains(
                  query.toLowerCase(),
                );
          }).toList();
    }
  }

  Future<void> submitData() async {
    if (sapDbName.value.isEmpty) {
      Get.snackbar(
        "Error",
        "SAP DB Name cannot be empty",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      for (var warehouse in warehouses) {
        final warehouseCode = warehouse['warehouseCode'];
        final username = warehouseUsernames[warehouseCode] ?? '';
        final password = warehousePasswords[warehouseCode] ?? '';

        if (username.isEmpty || password.isEmpty) {
          // Get.snackbar("Error", "Username or Password cannot be empty for warehouse $warehouseCode",
          //     snackPosition: SnackPosition.TOP,
          //     snackStyle: SnackStyle.FLOATING,
          //     backgroundColor: Colors.red,
          //     colorText: Colors.white);
          continue;
        }
        var encPass = AESHelper.encryptData(password);
        final data = {
          'warehouse_code': warehouseCode,
          'sap_username': username,
          'sap_password': encPass,
          'sap_db_name': sapDbName.value,
          'user_created': box.read("username"),
        };

        final result = await _apiService.PostWarehouseAuth(data);

        if (result == true) {
          Get.snackbar(
            "Success",
            "Authentication submitted",
            snackPosition: SnackPosition.TOP,
            snackStyle: SnackStyle.FLOATING,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "An error occurred: $e",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getWarehouseAuth(String warehouseCode) async {
    try {
      final data = {'warehouse_code': warehouseCode};

      final result = await _apiService.getWarehouseAuth(data);
      return result;
    } catch (e) {
      Get.snackbar('Error', 'Gagal load data autentikasi: $e');
      return null;
    }
  }

  Future<void> submitSingleWarehouse({required String warehouseCode}) async {
    isLoading.value = true;
    try {
      // final username = getUsername(warehouseCode) ?? '';
      // final password = getPassword(warehouseCode) ?? '';

      if (sapUsername.value.isEmpty || sapPassword.value.isEmpty || sapDbName.value.isEmpty) {
        Get.snackbar(
          'Error',
          'SAP DB, Username, and Password must be fill.',
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      var encPass = AESHelper.encryptData(sapPassword.value);
      final data = {
        'warehouse_code': warehouseCode,
        'sap_username': sapUsername.value,
        'sap_password': encPass,
        'sap_db_name': sapDbName.value,
        'user_created': box.read("username"),
      };

      final result = await _apiService.PostWarehouseAuth(data);
      if (result == true) {
        box.write('sap_db_name', sapDbName.value);
        Get.snackbar(
          'Success',
          'Saved successfully',
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to save authorization',
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
