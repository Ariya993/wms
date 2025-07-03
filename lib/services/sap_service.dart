// lib/api/sap_b1_api_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

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
      Get.snackbar("Error", "SAP Login failed: ${sap_response.statusCode}");
      return false;
    }
  }

  Future<String?> getItemName(String itemCode) async {
    try {
      final session = box.read('sessionId') ?? '';
      final url = Uri.parse('$apiItem?filter=$itemCode');

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

        final exactMatch = newItemsRaw.firstWhere(
          (item) =>
              item["ItemCode"]?.toString().toUpperCase() ==
              itemCode.toUpperCase(),
          orElse: () => null,
        );

        if (exactMatch != null) {
          return exactMatch["ItemName"]?.toString();
        } else {
          Get.snackbar(
            'Not Found',
            'Item dengan kode "$itemCode" tidak ditemukan.',
            snackPosition: SnackPosition.TOP,
          );
          return null;
        }
      } else if (res.statusCode == 401 ||
          res.body.contains('Session expired')) {
        Get.snackbar(
          "Session Expired",
          "Silakan login kembali.",
          snackPosition: SnackPosition.TOP,
        );
        box.erase();
        Get.offAllNamed('/login');
        return null;
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
}
