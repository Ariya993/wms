// lib/api/sap_b1_api_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../helper/encrypt.dart';
import '../helper/endpoint.dart';
import 'api_service.dart';

class SAPService extends GetConnect {
  // Ganti dengan base URL API SAP B1 Anda
  final String _baseUrl = apiB1;
  final ApiService _apiservice = ApiService();
  final box = GetStorage();
  @override
  void onInit() {
    httpClient.baseUrl = _baseUrl;
  }

  Future<bool> LoginSAP({
    String sap_db = '',
    String sap_username = '',
    String sap_pass = '',
  }) async {
    if (box.read('sap_username') == null) {
      Get.snackbar("Error", "SAP Login failed: sap username is required");
      return false;
    }
    if (box.read('sap_password') == null) {
      Get.snackbar("Error", "SAP Login failed: sap password is required");
      return false;
    }
    if (box.read('sap_db_name') == null) {
      Get.snackbar("Error", "SAP Login failed: sap db name is required");
      return false;
    }

    String body = '';
    if (sap_db == '') {
      body = jsonEncode({
        'UserName': box.read('sap_username'),
        'Password': box.read('sap_password'),
        'CompanyDB': box.read('sap_db_name'), // Ganti sesuai database SAP kamu
      });
    } else {
      body = jsonEncode({
        'UserName': sap_username,
        'Password': AESHelper.decryptData(sap_pass),
        'CompanyDB': sap_db, // Ganti sesuai database SAP kamu
      });
    }

    final sap_url = Uri.parse(apiLogin);
    final sap_response = await http.post(
      sap_url,
      headers: {'Content-Type': 'application/json'},
      body: body,
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
        //print(itemCode);
        final exactMatch = newItemsRaw.firstWhere(
          (item) =>
              item["ItemCode"]?.toString().toUpperCase() ==
              itemCode.toUpperCase(),
          orElse: () => null,
        );
        //print(exactMatch);
       if (exactMatch != null) {
          return (exactMatch["ItemName"]?.toString() ?? '-') +
                '|' +
                (exactMatch["InventoryUOM"]?.toString() ?? '-');
        }
        else {
          return "";
        }
      } else if (res.statusCode == 401 ||
          res.statusCode == 301 ||
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
          res.statusCode == 301 ||
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

  Future<List<Map<String, dynamic>>> getOutstandingPickList() async {
    try {
      final session = box.read('sessionId') ?? '';
      final url = Uri.parse(apiOutstandingPickList);
      final wms_user = box.read('username') ?? '';
      final res = await http.get(
        url,
        headers: {
          'session': session,
          'Accept': 'application/json',
          'wms_user': wms_user,
        },
      );

      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        return data.cast<Map<String, dynamic>>();
      } else if (res.statusCode == 401 ||
          res.statusCode == 301 ||
          res.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          // Retry getItem sekali lagi setelah login
          return await getOutstandingPickList();
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
          res.statusCode == 301 ||
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
          response.statusCode == 301 ||
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
      final wms_user = box.read('username') ?? '';
      final body = json.encode(goodsReceiptData);

      final response = await http.post(
        url,
        headers: {
          'session': session,
          'wms_user': wms_user,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await LoginSAP();
        return true;
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
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
    } finally {
      // final loginSuccess = await LoginSAP(
      //   sap_db: box.read('sap_db_name'),
      //   sap_username: box.read('sap_username'),
      //   sap_pass: box.read('sap_password'),
      // );
    }
  }

  // --- API untuk TR (Transfer Request) ---
  Future<Map<String, dynamic>?> fetchITRDetails(String docNum) async {
    try {
      final session = box.read('sessionId') ?? '';
      final body = json.encode({
        'DocNum': int.parse(docNum), // Mengirim Set sebagai List<int>
      });

      final url = Uri.parse(apiITR);

      final response = await http.post(
        url,
        headers: {'session': session, 'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first;  
        } else {
          Get.snackbar(
            'Not Found',
            'Transfer request not found.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return null;
        }
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await fetchITRDetails(docNum);
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
          'Failed to fetch transfer request details:',
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

  Future<bool> postGoodsReceiptITR(Map<String, dynamic> goodsReceiptData) async {
    try {
      
      final url = Uri.parse('$apiB1?path=StockTransfers');
      final session = box.read('sessionId') ?? '';
      final wms_user = box.read('username') ?? '';
      final body = json.encode(goodsReceiptData);

      final response = await http.post(
        url,
        headers: {
          'session': session,
          'wms_user': wms_user,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await LoginSAP();
        return true;
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          // Retry getItem sekali lagi setelah login
          return await postGoodsReceiptITR(goodsReceiptData);
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
          'Failed to post Transfer Request: $errorMessage',
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
    } finally {
      // final loginSuccess = await LoginSAP(
      //   sap_db: box.read('sap_db_name'),
      //   sap_username: box.read('sap_username'),
      //   sap_pass: box.read('sap_password'),
      // );
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
          res.statusCode == 301 ||
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

  Future<List<dynamic>?> getBussinesPartner({String? keyword}) async {
    try {
      final session = box.read('sessionId') ?? '';
      final filter =
          "Valid eq 'tYES'" +
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
          res.statusCode == 301 ||
          res.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          // Retry getItem sekali lagi setelah login
          return await getBussinesPartner(keyword: keyword);
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
          "Gagal mengambil data customer. Status: ${res.statusCode}",
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
  Future<bool> postAdjustment(
    Map<String, dynamic> postData,String mode
  ) async {
    try {
      Uri url;
      if(mode=="in")
      {
        url = Uri.parse('$apiB1?path=InventoryGenEntries');
      }
      else
      {
        url = Uri.parse('$apiB1?path=InventoryGenExits');
      }
      
      final session = box.read('sessionId') ?? '';
      final wms_user = box.read('username') ?? '';
      final body = json.encode(postData);

      final response = await http.post(
        url,
        headers: {
          'session': session,
          'wms_user': wms_user,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await LoginSAP();
        return true;
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await postAdjustment(postData,mode);
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
          'Failed to post Adjustment : $errorMessage',
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

  Future<Map<String, dynamic>?> fetchGIDetails(String poNumber) async {
    try {
      final session = box.read('sessionId') ?? '';
      final body = json.encode({
        'DocNum': int.parse(poNumber), // Mengirim Set sebagai List<int>
      });

      final url = Uri.parse(apiGI);

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
            'Goods issue tidak ditemukan.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return null;
        }
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await fetchGIDetails(poNumber);
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
          'Failed to fetch GI details:',
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

  // Mengembalikan List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> getPickPack(
    int skip,
    String? source,
    String? str,
    String? warehouse,
  ) async {
    try {
      
      final url = Uri.parse(apiPickPack);
      final session = box.read('sessionId') ?? '';
      if (warehouse == "") {
        warehouse = box.read('warehouse_code') ?? '';
      }
      // print ('warehouse hit : $warehouse');
      var mSource = "";
      if ((source ?? '').toUpperCase() != 'ALL') {
        mSource = source?.toLowerCase() ?? "";
      }
      mSource ??= "";
      //print('source : $mSource');
      final response = await http.get(
        url,
        headers: {
          'session': session,
          'Accept': 'application/json',
          'Cache-Control': 'max-age=300',
          'warehouse': warehouse.toString(),
          'source': mSource,
          'skip': skip.toString(),
          'str': str.toString(),
        },
      );
     // print(response.statusCode);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>(); // List of documents
        // final List<dynamic> data = json.decode(response.body)['value'];
        // return data.cast<Map<String, dynamic>>(); // Cast langsung ke Map
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
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
          getPickPack(skip, source, str, warehouse);
          return [];
        }
      } else if (response.body.contains('Request timed out')) {
        getPickPack(skip, source, str, warehouse);
        return [];
      } else {
        throw Exception('Failed to load pick pack managert: ${response.body}');
      }
    } catch (e) {
    //  print('Error getting pick pack managert: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getScanPickPack(
    int skip,
    String? source,
    String? str,
    String? warehouse,
  ) async {
    try {
      //print('str : $str');
      final url = Uri.parse(apiScanPickPack);
      final session = box.read('sessionId') ?? '';
      if (warehouse == "") {
        warehouse = box.read('warehouse_code') ?? '';
      }
      // print ('warehouse hit : $warehouse');
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
          'warehouse': warehouse.toString(),
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
          response.statusCode == 301 ||
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
          getPickPack(skip, source, str, warehouse);
          return [];
        }
      } else if (response.body.contains('Request timed out')) {
        getPickPack(skip, source, str, warehouse);
        return [];
      } else {
        throw Exception('Failed to load pick pack manager: ${response.body}');
      }
    } catch (e) {
     // print('Error getting pick pack manager: $e');
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
       // print('Failed to load ItemWarehouseInfo: ${response.body}');
      }
    } catch (e) {
     // print('Error getting ItemWarehouseInfo: $e');
    }
    return null;
  }

  // Menerima Map<String, dynamic> dan mengembalikan Map<String, dynamic>?
  Future<String> createPickList(
    Map<String, dynamic> pickListData,
    String warehouseCode,
  ) async {
    try {
      if (warehouseCode != box.read('warehouse_code')) {
        final warehouse_code = {'warehouse_code': warehouseCode};
        
        final data = await _apiservice.getWarehouseAuth(warehouse_code);
        final sapDb = data?['sap_db_name'] ?? box.read('sap_db_name');
        final sapUser = data?['sap_username'] ?? '';
        final sapPass = data?['sap_password'] ?? '';

        final loginSuccess = await LoginSAP(
          sap_db: sapDb,
          sap_username: sapUser,
          sap_pass: sapPass,
        );
        if (!loginSuccess) {
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return "Session Expired";
        }
      }

      final url = Uri.parse('$apiB1?path=PickLists');
      final session = box.read('sessionId') ?? '';
      final body = json.encode(pickListData);
      final wms_user = box.read('username') ?? '';
      final response = await http.post(
        url,
        headers: {
          'session': session,
          'wms_user': wms_user,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      //final response = await _apiService.post('PickLists', pickListData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return '';
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await createPickList(pickListData, warehouseCode);
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
        return errorMessage;
      }
    } catch (e) {
      //print('Error creating Pick List: $e');
      return 'Error creating Pick List: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getPickList(
    int skip,
    String? source,
    String? str,
    String? warehouse,
  ) async {
    try {
      final url = Uri.parse(apiPickList);
      final session = box.read('sessionId') ?? '';
      final wms_user = box.read('username') ?? '';
      if (warehouse == "") {
        warehouse = box.read('warehouse_code') ?? '';
      }
      // print(warehouse);
      var mSource = "";
      if (source.toString().toLowerCase() == "r") {
        mSource = "";
      } else {
        mSource = source.toString().toLowerCase();
      }
      mSource ??= "";
      //print('source picklist: $mSource');
      final response = await http.get(
        url,
        headers: {
          'session': session,
          'Accept': 'application/json',
          'warehouse': warehouse.toString(),
          'source': mSource,
          'skip': skip.toString(),
          'str': str.toString(),
          'wms_user': wms_user,
        },
      );

      if (response.statusCode == 200) {
        // var a = json.decode(response.body);
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>(); // List of documents
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
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
          getPickList(skip, mSource, str, warehouse);
          return [];
        }
      } else if (response.body.contains('Request timed out')) {
        getPickList(skip, mSource, str, warehouse);
        return [];
      } else {
        throw Exception('Failed to load pick list: ${response.body}');
      }
    } catch (e) {
      //print('Error getting pick list: $e');
      return [];
    }
  }

  Future<String> updatePickList(
    Map<String, dynamic> pickListData,
    String id,
    String warehouseCode,
  ) async {
    try {
      if (warehouseCode != box.read('warehouse_code')) {
        final warehouse_code = {'warehouse_code': warehouseCode};

        final data = await _apiservice.getWarehouseAuth(warehouse_code);

        final sapDb = data?['sap_db_name'] ?? box.read('sap_db_name');
        final sapUser = data?['sap_username'] ?? '';
        final sapPass = data?['sap_password'] ?? '';

        final loginSuccess = await LoginSAP(
          sap_db: sapDb,
          sap_username: sapUser,
          sap_pass: sapPass,
        );
        if (!loginSuccess) {
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return "Session Expired";
        }
      }

      final url = Uri.parse('$apiB1?path=PickLists($id)');
      final session = box.read('sessionId') ?? '';
      final wms_user = box.read('username') ?? '';
      final body = json.encode(pickListData);

      final response = await http.patch(
        url,
        headers: {
          'session': session,
          'wms_user': wms_user,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      //final response = await _apiService.post('PickLists', pickListData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return '';
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await updatePickList(pickListData,id, warehouseCode);
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
        return errorMessage;
      }
    } catch (e) {
     // print('Error update Pick List: $e');
      return 'Error update Pick List: $e';
    }
  }

  Future<String> cancelPickList(
    Map<String, dynamic> pickListData,
    String id,
    String warehouseCode,
  ) async {
    try {
      if (warehouseCode != box.read('warehouse_code')) {
        final warehouse_code = {'warehouse_code': warehouseCode};

        final data = await _apiservice.getWarehouseAuth(warehouse_code);

        final sapDb = data?['sap_db_name'] ?? box.read('sap_db_name');
        final sapUser = data?['sap_username'] ?? '';
        final sapPass = data?['sap_password'] ?? '';

        final loginSuccess = await LoginSAP(
          sap_db: sapDb,
          sap_username: sapUser,
          sap_pass: sapPass,
        );
        if (!loginSuccess) {
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return "Session Expired";
        }
      }

      final url = Uri.parse('$apiB1?path=PickLists($id)');
      final session = box.read('sessionId') ?? '';
      final wms_user = box.read('username') ?? '';
      final body = json.encode(pickListData);

      final response = await http.patch(
        url,
        headers: {
          'session': session,
          'wms_user': wms_user,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      //final response = await _apiService.post('PickLists', pickListData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return '';
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await createPickList(pickListData, warehouseCode);
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
        return errorMessage;
      }
    } catch (e) {
     // print('Error creating Pick List: $e');
      return 'Error creating Pick List: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getInventoryInList(
    int skip,
    String? source,
    String? str,
    String? warehouse,
    String? status,
  ) async {
    try {
      final url = Uri.parse(apiInventoryIn);
      final session = box.read('sessionId') ?? '';
      if (warehouse == "") {
        warehouse = box.read('warehouse_code') ?? '';
      }
      // print(warehouse);
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
          'warehouse': warehouse.toString(),
          'source': mSource,
          'skip': skip.toString(),
          'str': str.toString(),
          'docStat': status.toString().toLowerCase(),
        },
      );

      if (response.statusCode == 200) {
        // var a = json.decode(response.body);
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>(); // List of documents
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
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
          getInventoryInList(
            skip,
            source,
            str,
            warehouse,
            status.toString().toLowerCase(),
          );
          return [];
        }
      } else if (response.body.contains('Request timed out')) {
        getInventoryInList(
          skip,
          source,
          str,
          warehouse,
          status.toString().toLowerCase(),
        );
        return [];
      } else {
        throw Exception('Failed to load list inventory: ${response.body}');
      }
    } catch (e) {
      //print('Error getting list inventory: $e');
      return [];
    }
  }

  Future<bool> editInventoryIn(
    String source,
    int docEntry,
    Map<String, dynamic> data,
  ) async {
    // PATCH /InventoryGenEntries(<DocEntry>) atau PurchaseDeliveryNotes

    final url = Uri.parse('$baseUrl/$source($docEntry)');
    final resp = await http.patch(
      url,
      headers: {'session': '', 'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return resp.statusCode == 204; // SAP return 204 No Content on success
  }

  Future<bool> cancelInventoryIn(String source, int docEntry) async {
    // POST /InventoryGenEntries(<DocEntry>)/Cancel
    var endpoint = "";
    if (source == "po") {
      endpoint = "PurchaseDeliveryNotes";
    } else {
      endpoint = "InventoryGenEntries";
    }
    final session = box.read('sessionId') ?? '';
    final url = Uri.parse('$apiB1?path=$endpoint($docEntry)/Cancel');
    final resp = await http.post(
      url,
      headers: {'session': session, 'Content-Type': 'application/json'},
      body: '{}',
    );

    return true;
  }

  // --- API untuk Stock Opname  ---
  Future<Map<String, dynamic>?> fetchStockOpname(String docNum) async {
    try {
      final session = box.read('sessionId') ?? '';
      final body = json.encode({
        'DocNum': int.parse(docNum), // Mengirim Set sebagai List<int>
      });

      final url = Uri.parse(apiStockOpname);

      final response = await http.post(
        url,
        headers: {'session': session, 'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is List && decoded.isNotEmpty) {
          return decoded.first;
        } else {
          Get.snackbar(
            'Stock Opname Not Found',
            'data tidak ditemukan.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return null;
        }
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await fetchStockOpname(docNum);
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
          'Failed to fetch stock opname details:',
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

  Future<String> updateStockOpname(
    Map<String, dynamic> dataUpdate,
    String id,
    String warehouseCode,
  ) async {
    try {
      if (warehouseCode != box.read('warehouse_code')) {
        final warehouse_code = {'warehouse_code': warehouseCode};

        final data = await _apiservice.getWarehouseAuth(warehouse_code);

        final sapDb = data?['sap_db_name'] ?? box.read('sap_db_name');
        final sapUser = data?['sap_username'] ?? '';
        final sapPass = data?['sap_password'] ?? '';

        final loginSuccess = await LoginSAP(
          sap_db: sapDb,
          sap_username: sapUser,
          sap_pass: sapPass,
        );
        if (!loginSuccess) {
          Get.snackbar(
            "Session Expired",
            "Gagal login ulang. Silakan login manual.",
            snackPosition: SnackPosition.TOP,
          );
          box.erase();
          Get.offAllNamed('/login');
          return "Session Expired";
        }
      }

      final url = Uri.parse('$apiB1?path=InventoryCountings($id)');
      final session = box.read('sessionId') ?? '';
      final wms_user = box.read('username') ?? '';
      final body = json.encode(dataUpdate);
      print('complete SO : $body');
      final response = await http.patch(
        url,
        headers: {
          'session': session,
          'wms_user': wms_user,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      //final response = await _apiService.post('PickLists', pickListData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return '';
      } else if (response.statusCode == 401 ||
          response.statusCode == 301 ||
          response.body.contains('Session expired')) {
        final loginSuccess = await LoginSAP();
        if (loginSuccess) {
          return await updateStockOpname(dataUpdate,id, warehouseCode);
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
        return errorMessage;
      }
    } catch (e) {
     // print('Error update Stock Opname: $e');
      return 'Error update Stock Opname: $e';
    }
  }

}
