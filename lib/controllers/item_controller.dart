import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../helper/endpoint.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart';

class ItemController extends GetxController {
  RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;
  final SAPService _apiService = Get.find<SAPService>();
  final ApiService _apiServices = Get.find<ApiService>();
 
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;
  RxInt page = 1.obs;
RxList<String> selectedWarehouses = <String>[].obs;
RxString selectedWarehouseFilter = ''.obs;
  RxList<String> filteredWarehouseList = <String>[].obs;
final TextEditingController filterSearchController = TextEditingController();
final RxString filterSearchTerm = ''.obs;
//RxMap<String, String> warehouseCodeNameMap = <String, String>{}.obs;
final RxMap<String, String> warehouseCodeNameMap = <String, String>{}.obs;
  final box = GetStorage();

  var filterType = "equals".obs; // default


  @override
  void onInit() {
    super.onInit();
    fetchItems();
    final userId = box.read('internalkey') ?? 0;
    loadUserWarehouses(userId);
   
  }

/// Filter warehouse berdasarkan pencarian user
void filterWarehouseSearch(String query) {
  filterSearchTerm.value = query;

  final filtered = selectedWarehouses
      .where((code) {
        final name = warehouseCodeNameMap[code] ?? '';
        return name.toLowerCase().contains(query.toLowerCase());
      })
      .toList();

  filteredWarehouseList.value = filtered;
}

/// Load semua warehouse milik user
Future<void> loadUserWarehouses(int userId) async {
  isLoading.value = true;
  try {
    final assigned = await _apiServices.getUserWarehouse(userId.toString());
    final allWarehouses = await _apiServices.getWarehouses();

    // Gabungkan data assigned dengan warehouse name
    final List<Map<String, dynamic>> transformed = assigned
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final code = item['warehouse_code'];
          final match = allWarehouses.firstWhere(
            (w) => w['warehouseCode'] == code,
            orElse: () => {'warehouseName': 'Unknown'},
          );
          return {
            'warehouseCode': code,
            'warehouseName': match['warehouseName'],
          };
        })
        .toList();

    // Update list kode & peta kode->nama
    final List<String> codes = [];
    final Map<String, String> codeNameMap = {};

    for (var item in transformed) {
      final code = item['warehouseCode'].toString();
      final name = item['warehouseName'].toString();
      codes.add(code);
      codeNameMap[code] = name;
    }

    selectedWarehouses.value = codes;
    warehouseCodeNameMap.value = codeNameMap;

    // Default: assign semua ke filtered list
    filteredWarehouseList.assignAll(codes);

    // Opsional: auto select 1st
    // if (selectedWarehouseFilter.value.isEmpty && codes.isNotEmpty) {
    //   selectedWarehouseFilter.value = codes.first;
    // }

  } catch (e) {
    Get.snackbar(
      "Error",
      "Failed to load warehouses: $e",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  } finally {
    isLoading.value = false;
  }
}


  @override
  void onClose() {
    super.onClose();
  }

  Future<void> fetchItems({bool isLoadMore = false}) async {
    if (!hasMore.value && isLoadMore) return;
    if (isLoading.value || isLoadingMore.value) return;
    final String query = searchQuery.value.trim();
    if (isLoadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      page.value = 1;
      items.clear();
    }
 
    final session = box.read('sessionId') ?? '';
    if (session.isEmpty) { 
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
        box.erase();
        Get.offAllNamed('/login');
        isLoading.value = false;
        isLoadingMore.value = false;
        return;
      }
    }

    try {
      final int skip = (page.value - 1) * 20;
       var code = box.read('warehouse_code') ?? '';
    //   final warehouseCode = selectedWarehouseFilter.value;
     
      if (selectedWarehouseFilter.value!='')
      {
          code=selectedWarehouseFilter.value;
      } 
     selectedWarehouseFilter.value=code;
      // Sesuaikan dengan struktur API kamu
      final url = Uri.parse('$apiItem?skip=$skip&filter=$query&code=$code&filterType=$filterType');

      final res = await http.get(
        url,
        headers: {'session': session, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
          final List<dynamic> data = json.decode(res.body); 
         final warehouses =await  _apiServices.getWarehouses();
       
      final List<Map<String, dynamic>> transformedItems = data
      .whereType<Map<String, dynamic>>()
      .map((item) {
        final warehouseCode = item['WarehouseCode'];
        final warehouse = warehouses.firstWhere(
          (w) => w['warehouseCode'] == warehouseCode,
          orElse: () => {'warehouseName': 'Unknown'},
        );

        return {
          ...item,
          'WarehouseName': warehouse['warehouseName'],
        };
      })
      .toList();
 
        // final List<Map<String, dynamic>> transformedItems =
        //     data.whereType<Map<String, dynamic>>().toList();
        if (isLoadMore) {
         
          items.addAll(transformedItems);
        } else {
          items.value = transformedItems;
        }

        if (transformedItems.length<=20) {
          hasMore.value = true;
          page.value++;
        } else {
          hasMore.value = false;
        }
      } else if (res.statusCode == 401 || res.statusCode == 301 ||
          res.body.contains('Session expired')) {
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
          box.erase();
          Get.offAllNamed('/login');
          isLoading.value = false;
          isLoadingMore.value = false;
          return;
        } 
      } else {
        var a = json.decode(res.body);
        // Get.snackbar(
        //   "Error",
        //   "Failed get data Items fetchItems. Status: ${a}",
        //   snackPosition: SnackPosition.TOP,
        //   snackStyle: SnackStyle.FLOATING,
        //   backgroundColor: Colors.redAccent,
        //   colorText: Colors.white,
        // );
      }
    } catch (e) {
      Get.snackbar(
        "Exception",
        "Terjadi kesalahan: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

Future<void> scanItems({bool isLoadMore = false}) async {
    if (!hasMore.value && isLoadMore) return;
    if (isLoading.value || isLoadingMore.value) return;
    final String query = searchQuery.value.trim();
    if (isLoadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      page.value = 1;
      items.clear();
    }
 
    final session = box.read('sessionId') ?? '';
    if (session.isEmpty) { 
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
        box.erase();
        Get.offAllNamed('/login');
        isLoading.value = false;
        isLoadingMore.value = false;
        return;
      }
    }

    try {
      final int skip = (page.value - 1) * 20;
       var code = box.read('warehouse_code') ?? '';
    //   final warehouseCode = selectedWarehouseFilter.value;
     
      if (selectedWarehouseFilter.value!='')
      {
          code=selectedWarehouseFilter.value;
      } 
     selectedWarehouseFilter.value=code;
      // Sesuaikan dengan struktur API kamu
      final url = Uri.parse('$apiScanItem?skip=$skip&filter=$query&code=$code');

      final res = await http.get(
        url,
        headers: {'session': session, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
          final List<dynamic> data = json.decode(res.body); 
         final warehouses =await  _apiServices.getWarehouses();
       
      final List<Map<String, dynamic>> transformedItems = data
      .whereType<Map<String, dynamic>>()
      .map((item) {
        final warehouseCode = item['WarehouseCode'];
        final warehouse = warehouses.firstWhere(
          (w) => w['warehouseCode'] == warehouseCode,
          orElse: () => {'warehouseName': 'Unknown'},
        );

        return {
          ...item,
          'WarehouseName': warehouse['warehouseName'],
        };
      })
      .toList();
 
        // final List<Map<String, dynamic>> transformedItems =
        //     data.whereType<Map<String, dynamic>>().toList();
        if (isLoadMore) {
         
          items.addAll(transformedItems);
        } else {
          items.value = transformedItems;
        }

        if (transformedItems.length<=20) {
          hasMore.value = true;
          page.value++;
        } else {
          hasMore.value = false;
        }
      } else if (res.statusCode == 401 || res.statusCode == 301 ||
          res.body.contains('Session expired')) {
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
          box.erase();
          Get.offAllNamed('/login');
          isLoading.value = false;
          isLoadingMore.value = false;
          return;
        } 
      } else {
        var a = json.decode(res.body);
        Get.snackbar(
          "Error",
          "Failed get data Items. Status: ${a}",
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Exception",
        "Terjadi kesalahan: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

 Future<void> fetchItemsBranch({bool isLoadMore = false}) async {
    if (!hasMore.value && isLoadMore) return;
    if (isLoading.value || isLoadingMore.value) return;
    final String query = searchQuery.value.trim();
    if (isLoadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      page.value = 1;
      items.clear();
    }

    if (query.isNotEmpty) {
      page.value = 1;
      items.clear();
    }
    final session = box.read('sessionId') ?? '';
    if (session.isEmpty) {
      // Get.snackbar("Session Error", "Session login not found. Please login again.",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      // box.erase();
      // Get.offAllNamed('/login');
      // isLoading.value = false;
      // isLoadingMore.value = false;
      // return;
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
        box.erase();
        Get.offAllNamed('/login');
        isLoading.value = false;
        isLoadingMore.value = false;
        return;
      }
    }

    try {
      final int skip = (page.value - 1) * 20;
      // Sesuaikan dengan struktur API kamu
      final url = Uri.parse('$apiItem?skip=$skip&filter=$query');

      final res = await http.get(
        url,
        headers: {'session': session, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final firstDecoded = json.decode(res.body);
        final Map<String, dynamic> data = json.decode(
          firstDecoded,
        ); // hasilnya Map

        final List<dynamic> newItemsRaw = data['value'] ?? [];

        final List<Map<String, dynamic>> transformedItems =
            newItemsRaw.whereType<Map<String, dynamic>>().toList();
        if (isLoadMore) {
          items.addAll(transformedItems);
        } else {
          items.value = transformedItems;
        }

        if (data['odata.nextLink'] != null &&
            (data['odata.nextLink'] as String).isNotEmpty) {
          hasMore.value = true;
          page.value++;
        } else {
          hasMore.value = false;
        }
      } else if (res.statusCode == 401 ||
          res.body.contains('Session expired')) {
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
          box.erase();
          Get.offAllNamed('/login');
          isLoading.value = false;
          isLoadingMore.value = false;
          return;
        }
        // Get.snackbar("Session Expired", "Please login again.",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
        // box.erase();
        // Get.offAllNamed('/login');
      } else {
          var a = json.decode(res.body);
        Get.snackbar(
          "Error",
          "Failed get data Items fetchItemsBranch. Status: ${a}",
          snackPosition: SnackPosition.TOP,
          snackStyle: SnackStyle.FLOATING,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Exception",
        "Terjadi kesalahan: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void resetItems() {
    items.clear();
    page.value = 1;
    hasMore.value = true;
    fetchItems();
  }

  Future<bool> updateBinLocation({
  required String itemCode,
  required String warehouseCode,
  required String lokasiBaru,
}) async {
  final session = box.read('sessionId') ?? '';
  if (session.isEmpty) {
    final sapLoginSuccess = await _apiService.LoginSAP(); // Auto-login
    if (!sapLoginSuccess) {
      Get.snackbar(
        "SAP Login",
        "Failed login to SAP. Cannot update lokasi.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      box.erase();
      Get.offAllNamed('/login');
      return false;
    }
  }

  try {
    final body = {
      "ItemWarehouseInfoCollection": [
        {
          "WarehouseCode": warehouseCode,
          "U_CST_BIN_LOC": lokasiBaru,
        }
      ]
    };
    String path="?path=Items('$itemCode')";
    final url = Uri.parse('$apiB1$path '); // pastikan endpoint benar

    final res = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'session': session,
      },
      body: json.encode(body),
    );

    if (res.statusCode == 200) {
     return true;
    } else {
      return false;
    }
  } catch (e) {
     return false;
  }
}

}
