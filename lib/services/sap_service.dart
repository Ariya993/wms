// lib/api/sap_b1_api_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:wms/models/warehouse_model.dart';

import '../helper/endpoint.dart';

class SAPService extends GetConnect {
  // Ganti dengan base URL API SAP B1 Anda
  final String _baseUrl = apiB1;
  final box = GetStorage();
  @override
  void onInit() {
    httpClient.baseUrl = _baseUrl;
  }

  Future<bool> LoginSAP() async {
    if (box.read('sap_username')==null)
    {
        Get.snackbar("Error", "SAP Login failed: sap username is required");
      return false;
    }
    if (box.read('sap_password')==null)
    {
        Get.snackbar("Error", "SAP Login failed: sap password is required");
      return false;
    }
    if (box.read('sap_db_name')==null)
    {
        Get.snackbar("Error", "SAP Login failed: sap db name is required");
      return false;
    }
    final sap_url = Uri.parse(apiLogin);
    final sap_response = await http.post(
      sap_url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'UserName': box.read('sap_username'),
        'Password': box.read('sap_password'),
        'CompanyDB': box.read('sap_db_name'), // Ganti sesuai database SAP kamu
      }),
    );

    if (sap_response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(sap_response.body);
      await box.write('sessionId', data['SessionId']);
      return true;
    } else {
    //  Get.snackbar("Error", "SAP Login failed: ${sap_response.statusCode}");
      return false;
    }
  }

  Future<String?> getItemName(String itemCode) async {
    try {
      final session = box.read('sessionId') ?? '';
      final url = Uri.parse('$apiItemHeader?filter=$itemCode');

      final res = await http.get(
        url,
        headers: {'session': session, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final firstDecoded = json.decode(res.body);

        // Jika body langsung Map, tidak perlu decode dua kali
        final Map<String, dynamic> data =
            firstDecoded is String ? json.decode(firstDecoded) : firstDecoded;

        final List<dynamic> newItemsRaw = data['value'] ?? [];
        print(itemCode);
        final exactMatch = newItemsRaw.firstWhere(
          (item) =>
              item["ItemCode"]?.toString().toUpperCase() ==
              itemCode.toUpperCase(),
          orElse: () => null,
        );
        print(exactMatch);
        if (exactMatch != null) {
          return exactMatch["ItemName"]?.toString();
        } else {
          // Get.snackbar(
          //   'Not Found',
          //   'Item dengan kode "$itemCode" tidak ditemukan.',
          //   snackPosition: SnackPosition.TOP,
          //   backgroundColor: Colors.orangeAccent,
          // colorText: Colors.white,
          // );
          return "";
        }
      } else if (res.statusCode == 401 ||
          res.body.contains('Session expired')) {
        Get.snackbar(
          "Session Expired",
          "Silakan login kembali.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        box.erase();
        Get.offAllNamed('/login');
        return "";
      } else {
        Get.snackbar(
          "Error",
          "Gagal mengambil data Items. Status: ${res.statusCode}",
          snackPosition: SnackPosition.TOP,
        );
        return "";
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'API SAP call failed: $e',
        snackPosition: SnackPosition.TOP,
      );
      return "";
    }
  }

  Future<List<dynamic>> getItem(String itemCode) async {
    try {
      final session = box.read('sessionId') ?? '';
      final url = Uri.parse('$apiItem?filter=$itemCode');

      final res = await http.get(
        url,
        headers: {'session': session, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final firstDecoded = json.decode(res.body);

        // Jika firstDecoded masih String, decode lagi
        final Map<String, dynamic> data =
            firstDecoded is String ? json.decode(firstDecoded) : firstDecoded;

        final List<dynamic> newItemsRaw = data['value'] ?? [];
        return newItemsRaw;
      } else if (res.statusCode == 401 ||
          res.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          // Retry getItem sekali lagi setelah login
          return await getItem(itemCode);
        } else {
          // Gagal login ulang
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return [];
        }
        // Get.snackbar(
        //   "Session Expired",
        //   "Silakan login kembali.",
        //   snackPosition: SnackPosition.TOP,
        // );
        // box.erase();
        // Get.offAllNamed('/login');
        // return [];
      } else {
        Get.snackbar(
          "Error",
          "Gagal mengambil data Items. Status: ${res.statusCode}",
          snackPosition: SnackPosition.TOP,
        );
        return [];
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'API SAP call failed: $e',
        snackPosition: SnackPosition.TOP,
      );
      return [];
    }
  }
Future<List<dynamic>> getItemHeader(String itemCode) async {
    try {
      final session = box.read('sessionId') ?? '';
      final url = Uri.parse('$apiItemHeader?filter=$itemCode');

      final res = await http.get(
        url,
        headers: {'session': session, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final firstDecoded = json.decode(res.body);

        // Jika firstDecoded masih String, decode lagi
        final Map<String, dynamic> data =
            firstDecoded is String ? json.decode(firstDecoded) : firstDecoded;

        final List<dynamic> newItemsRaw = data['value'] ?? [];
        return newItemsRaw;
      } else if (res.statusCode == 401 ||
          res.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) { 
          return await getItemHeader(itemCode);
        } else {
          // Gagal login ulang
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return [];
        } 
      } else {
        Get.snackbar(
          "Error",
          "Gagal mengambil data Items. Status: ${res.statusCode}",
          snackPosition: SnackPosition.TOP,
        );
        return [];
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'API SAP call failed: $e',
        snackPosition: SnackPosition.TOP,
      );
      return [];
    }
  }
  // --- API untuk PO (Purchase Order) ---
  Future<Map<String, dynamic>?> fetchPoDetails(String poNumber) async {
    try {
      final session = box.read('sessionId') ?? '';
      final body = json.encode({
        'DocNum': int.parse(poNumber), // Mengirim Set sebagai List<int>
      });

      final url = Uri.parse(apiPO);

      final response = await http.post(
        url,
        headers: {'session': session, 'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first; // ✅ ambil PO pertama dari list
        } else {
          Get.snackbar(
            'Not Found',
            'PO tidak ditemukan.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return null;
        }
      } else if (response.statusCode == 401 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await fetchPoDetails(poNumber);
        } else {
          // Gagal login ulang
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return null;
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to fetch PO details:',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'API SAP call failed: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<bool> postGoodsReceiptPo(Map<String, dynamic> goodsReceiptData) async {
    try {
      final url = Uri.parse('$apiB1?path=PurchaseDeliveryNotes');
      final session = box.read('sessionId') ?? '';

      final body = json.encode(goodsReceiptData);

      final response = await http.post(
        url,
        headers: {'session': session, 'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          // Retry getItem sekali lagi setelah login
          return await postGoodsReceiptPo(goodsReceiptData);
        } else {
          // Gagal login ulang
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return false;
        }
      } else {
        final error = json.decode(response.body);
        final errorMessage =
            error["error"]?["message"]?["value"] ?? "Unknown Error";

        Get.snackbar(
          'Error',
          'Failed to post Goods Receipt (Non-PO): $errorMessage',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'API SAP call failed: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  Future<List<dynamic>?> getVendors({String? keyword}) async {
    try {
      final session = box.read('sessionId') ?? '';
      final filter =
          "CardType eq 'S' and Valid eq 'tYES'" +
          (keyword != null && keyword.isNotEmpty
              ? " and contains(CardName, '${keyword.replaceAll("'", "''")}')"
              : "");
      final encodedFilter = Uri.encodeComponent(filter);
      final url = Uri.parse(
        "$apiB1?str=BusinessPartners?\$filter=$encodedFilter&\$select=CardCode,CardName",
      );

      final res = await http.get(
        url,
        headers: {'session': session, 'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final data = decoded is String ? json.decode(decoded) : decoded;

        return data['value'] ?? [];
      } else if (res.statusCode == 401 ||
          res.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          // Retry getItem sekali lagi setelah login
          return await getVendors(keyword: keyword);
        } else {
          // Gagal login ulang
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return [];
        }
      } else {
        Get.snackbar(
          "Error",
          "Gagal mengambil data vendor. Status: \${res.statusCode}",
          snackPosition: SnackPosition.TOP,
        );
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'API SAP call failed: \$e',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    }
  }

  // --- API untuk Non-PO ---
  Future<bool> postGoodsReceiptNonPo(
    Map<String, dynamic> goodsReceiptData,
  ) async {
    try {
      final url = Uri.parse('$apiB1?path=InventoryGenEntries');
      final session = box.read('sessionId') ?? '';

      final body = json.encode(goodsReceiptData);

      final response = await http.post(
        url,
        headers: {'session': session, 'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await postGoodsReceiptNonPo(goodsReceiptData);
        } else {
          // Gagal login ulang
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return false;
        }
      } else {
        final error = json.decode(response.body);
        final errorMessage =
            error["error"]?["message"]?["value"] ?? "Unknown Error";

        Get.snackbar(
          'Error',
          'Failed to post Goods Receipt (Non-PO): $errorMessage',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'API SAP call failed: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Mengembalikan List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> getPickPack(
    int skip,
    String? source,
    String? str,
  ) async {
    try {
      final url = Uri.parse(apiPickPack);
      final session = box.read('sessionId') ?? '';
      final warehouse = box.read('warehouse_code') ?? '';
      var mSource = "";
      if (source == "ALL") {
        mSource = "";
      } else {
        mSource = source.toString().toLowerCase();
      }
      final response = await http.get(
        url,
        headers: {
          'session': session,
          'Accept': 'application/json',
          'warehouse': warehouse,
          'source': mSource,
          'skip': skip.toString(),
          'str': str.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>(); // List of documents
        // final List<dynamic> data = json.decode(response.body)['value'];
        // return data.cast<Map<String, dynamic>>(); // Cast langsung ke Map
      } else if (response.statusCode == 401 ||
          response.body.contains('Session expired')) {
        final sapLoginSuccess = await LoginSAP(); // Coba login SAP
        if (!sapLoginSuccess) {
          Get.snackbar(
            "SAP Login",
            "Failed login to SAP. Some features may be limited.",
            snackPosition: SnackPosition.TOP,
            snackStyle: SnackStyle.FLOATING,
            backgroundColor: Colors.orangeAccent,
            colorText: Colors.blueGrey,
          );
          Get.snackbar(
            "Session Expired",
            "Silakan login kembali.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          box.erase();
          Get.offAllNamed('/login');
          return [];
        } else {
          getPickPack(skip, source, str);
          return [];
        }
      } else {
        throw Exception('Failed to load Sales Orders: ${response.body}');
      }
    } catch (e) {
      print('Error getting Sales Orders: $e');
      return [];
    }
  }
 
  // Mengembalikan Map<String, dynamic>?
  Future<Map<String, dynamic>?> getItemWarehouseInfo(
    String itemCode,
    String warehouseCode,
  ) async {
    try {
      final url = Uri.parse(
        '$apiB1?path=ItemWarehouseInfoCollection?\$filter=ItemCode eq \'$itemCode\' and WarehouseCode eq \'$warehouseCode\'',
      );
      final session = box.read('sessionId') ?? '';
      final response = await http.get(
        url,
        headers: {'session': session, 'Accept': 'application/json'},
      );

      //   final response = await _apiService.get('ItemWarehouseInfoCollection?\$filter=ItemCode eq \'$itemCode\' and WarehouseCode eq \'$warehouseCode\'');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['value'];
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>; // Cast ke Map
        }
      } else {
        print('Failed to load ItemWarehouseInfo: ${response.body}');
      }
    } catch (e) {
      print('Error getting ItemWarehouseInfo: $e');
    }
    return null;
  }

  // Menerima Map<String, dynamic> dan mengembalikan Map<String, dynamic>?
  Future<String> createPickList(Map<String, dynamic> pickListData) async {
    try {
      final url = Uri.parse('$apiB1?path=PickLists');
      final session = box.read('sessionId') ?? '';
      final body = json.encode(pickListData);

      final response = await http.post(
        url,
        headers: {'session': session, 'Content-Type': 'application/json'},
        body: body,
      );

      //final response = await _apiService.post('PickLists', pickListData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return '';
      } else if (response.statusCode == 401 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await createPickList(pickListData);
        } else {
          // Gagal login ulang
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return "Session Expired";
        }
      } else {
        final error = json.decode(response.body);
        final errorMessage =
            error["error"]?["message"]?["value"] ?? "Unknown Error";

        // Get.snackbar(
        //   'Error',
        //   'Failed to generate picklist: $errorMessage',
        //   snackPosition: SnackPosition.TOP,
        // );
        return errorMessage;
      }
    } catch (e) {
      print('Error creating Pick List: $e');
      return 'Error creating Pick List: $e';
    }
  }


   Future<List<Map<String, dynamic>>> getPickList(
    int skip,
    String? source,
    String? str,
  ) async {
    try {
      final url = Uri.parse(apiPickList);
      final session = box.read('sessionId') ?? '';
      final warehouse = box.read('warehouse_code') ?? '';
      var mSource = "";
      if (source == "ALL") {
        mSource = "";
      } else {
        mSource = source.toString().toLowerCase();
      }
      final response = await http.get(
        url,
        headers: {
          'session': session,
          'Accept': 'application/json',
          'warehouse': warehouse,
          'source': mSource,
          'skip': skip.toString(),
          'str': str.toString(),
        },
      );

      if (response.statusCode == 200) {
       // var a = json.decode(response.body);
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>(); // List of documents 
      } else if (response.statusCode == 401 ||
          response.body.contains('Session expired')) {
        final sapLoginSuccess = await LoginSAP(); // Coba login SAP
        if (!sapLoginSuccess) {
          Get.snackbar(
            "SAP Login",
            "Failed login to SAP. Some features may be limited.",
            snackPosition: SnackPosition.TOP,
            snackStyle: SnackStyle.FLOATING,
            backgroundColor: Colors.orangeAccent,
            colorText: Colors.blueGrey,
          );
          Get.snackbar(
            "Session Expired",
            "Silakan login kembali.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          box.erase();
          Get.offAllNamed('/login');
          return [];
        } else {
          getPickPack(skip, source, str);
          return [];
        }
      } else {
        throw Exception('Failed to load Sales Orders: ${response.body}');
      }
    } catch (e) {
      print('Error getting Sales Orders: $e');
      return [];
    }
  }
 
  
}
