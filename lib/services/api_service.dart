import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:wms/helper/endpoint.dart';
import 'package:get_storage/get_storage.dart';

class ApiService extends GetxService {
  final box = GetStorage(); // Inisialisasi GetStorage

  Future<bool> refreshToken() async {
    final refreshToken = box.read('token');
    final url = Uri.parse(apiRefreshLoginWMS);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refreshToken': refreshToken, // Ganti sesuai database SAP kamu
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      await box.write('token', data['token']);
      await box.write('refreshToken', data['refreshToken']);
      await box.write('refreshTokenExpiryTime', data['expiresIn']);

      return true;
    } else {
      Get.snackbar("Error", " Refresh Token failed: ${response.statusCode}");
       box.erase();
          Get.offAllNamed('/login'); 
      return false;
    }
  }

  // Helper untuk mendapatkan headers dengan token
  Map<String, String> _getHeaders({bool includeToken = true}) {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (includeToken) {
      final token = box.read('token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {}
    }
    return headers;
  }

  Future<List<dynamic>> fetchUserMenus(int userId) async {
    final response = await http.get(
      Uri.parse('$apiMenuWMS/$userId'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil menu akses');
    }
  }

  Future<void> saveUserMenuAccess(int userId, Set<int> menuIds) async {
    final url = Uri.parse(apiMenuWMS); // Pastikan ini URL yang benar

    final body = json.encode({
      'internalKey': userId,
      'menuIds': menuIds.toList(), // Mengirim Set sebagai List<int>
    });
 
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 204) { // NoContent 
        return;
      } else {
        Get.snackbar(
          "Error",
          "Gagal menyimpan akses menu pengguna: ${response.statusCode} - ${response.body}",
         snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
        
      }
    } catch (e) { 
      throw Exception('Network or server error: $e'); // Lempar exception umum
    } 
  }
Future<List<Map<String, dynamic>>> getPickers() async {
  try {
    final response = await http.get(
        Uri.parse(apiWarehouseWMS),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        Get.snackbar(
          "Error",
          "Gagal mengambil data picker: ${response.statusCode}",
        );
        print("Response body: ${response.body}");
        return [];
      }
  } catch (e) {
    Get.snackbar(
      "Error", "Gagal mengambil data picker",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return [];
  }
}
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    try {
      final response = await http.get(
        Uri.parse(apiWarehouseWMS),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        Get.snackbar(
          "Error",
          "Gagal mengambil data Warehouse: ${response.statusCode}",
        );
        print("Response body: ${response.body}");
        return [];
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat mengambil Warehouse: $e");
      print("Error fetching warehouses: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWMSUsers() async {
    try {
      final response = await http.get(
        Uri.parse(apiUserWMS),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
        //return data.map((json) => WMSUser.fromJson(json)).toList();
      } else {
        Get.snackbar(
          "Error",
          "Gagal mengambil data User WMS: ${response.statusCode}",
        );
        print("Response body: ${response.body}");
        return [];
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat mengambil User WMS: $e");
      print("Error fetching WMS users: $e");
      return [];
    }
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse(apiUserWMS),
        headers: _getHeaders(),
        body: json.encode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Success", "User created!",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = "Error";

        if (errorData['errors'] != null) {
          // Ambil semua pesan error dari field 'errors'
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage = errors.entries
              .map((e) => "${e.key}: ${e.value.join(', ')}")
              .join('\n');
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        Get.snackbar("Error", errorMessage);
        print("Failed to create user: ${response.body}");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to create user: $e");
      print("Error creating user: $e");
      return false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUserWMS/$id'),
        headers: _getHeaders(),
        body: json.encode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Success", "User updated",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = "Error";

        if (errorData['errors'] != null) {
          // Ambil semua pesan error dari field 'errors'
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage = errors.entries
              .map((e) => "${e.key}: ${e.value.join(', ')}")
              .join('\n');
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        Get.snackbar("Error", errorMessage);
        print("Failed to update user: ${response.body}");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to updated user: $e");
      print("Error creating user: $e");
      return false;
    }
  }

  Future<bool> SendFCM(String username,String platform,String title, String descr,String path) async {
    try {
      final body = jsonEncode({
        "device": username, // Ambil username dari GetStorage
        "title": title,
        "message": descr,
        "type": platform,
        "path": path,
      });

      final response = await http.post(
        Uri.parse(apiSendFCM), 
        headers: {
        "Content-Type": "application/json", 
      },
        body: body,
      );
      if (response.statusCode==204)
      {
        return true;
      }
      else
      {
        var a = json.decode(response.body);
        print("Error creating user: $a");
      return false;
      }
      
       
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat: $e");
      print("Error creating user: $e");
      return false;
    }
  }
  Future<bool> PostWarehouseAuth(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiWarehouseWMS/auth'),
        headers: _getHeaders(),
        body: json.encode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
      
        return true;
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = "Error";

        if (errorData['errors'] != null) {
          // Ambil semua pesan error dari field 'errors'
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage = errors.entries
              .map((e) => "${e.key}: ${e.value.join(', ')}")
              .join('\n');
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        Get.snackbar("Error", errorMessage);
        print("Failed to submit authentication: ${response.body}");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to submit authentication: $e");
      print("Error creating user: $e");
      return false;
    }
  } 
  
  Future<Map<String, dynamic>?> getWarehouseAuth(Map<String, dynamic> data) async {
  try {
     final response = await http.post(
        Uri.parse('$apiWarehouseWMS/code'),
        headers: _getHeaders(),
        body:json.encode(data), 
      );

      if (response.statusCode == 200) {
       Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else { 
        return null;
      }
  } catch (e) {
    Get.snackbar('Error', 'Gagal load data auhorization: $e');
    return null;
  }
}

Future<bool> saveUserWarehouses(int userId, List<String> warehouseCodes) async {
  // final url = Uri.parse('$apiMenuWMS'); // Sesuaikan endpoint kamu
    final user = box.read('username');
    final body = {
      'appuser_id': userId,
      'warehouses': warehouseCodes,
      'user_created': user,
    };

try {
      final response = await http.post(
        Uri.parse(apiUserWarehouseWMS),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Success", "Setting warehouse success",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = "Error";

        if (errorData['errors'] != null) {
          // Ambil semua pesan error dari field 'errors'
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage = errors.entries
              .map((e) => "${e.key}: ${e.value.join(', ')}")
              .join('\n');
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        Get.snackbar("Error", errorMessage);
        print("Failed to setting warehouse: ${response.body}");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to setting warehouse: $e");
      print("Error setting warehouse: $e");
      return false;
    }


  // final response = await http.post(
  //   url,
  //   headers: {
  //     'Content-Type': 'application/json',
  //     'Authorization': 'Bearer ${getToken()}', // kalau pakai token
  //   },
  //   body: jsonEncode(body),
  // );

  // if (response.statusCode != 200) {
  //   throw Exception('Failed to save user warehouses: ${response.body}');
  // }
}

Future<List<Map<String, dynamic>>> getUserWarehouse(String appuser_id) async {
    try {
        final headers = _getHeaders(); 
// print (appuser_id);
// print(headers);
      final response = await http.get(
        Uri.parse('$apiUserWarehouseWMS?appuser_id=$appuser_id'),
        headers: headers,
      );

      if (response.statusCode == 200) { 
        
        final decoded = json.decode(response.body);
//         print(response.body);
// print(decoded.runtimeType); // cek apakah Map
// print(decoded['data'].runtimeType); // cek apakah List
// print(decoded['data']); // lihat isi list-nya

        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final dataList = decoded['data'];
          if (dataList is List) {
            return dataList
                .whereType<Map<String, dynamic>>()
                .toList(); // aman tanpa throw
          }
        } 

      return []; 
      } else {
        Get.snackbar(
          "Error",
          "Gagal mengambil data WMS user warehouse : ${response.statusCode}",
        );
        print("Response body: ${response.body}");
        return [];
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat mengambil user warehouse: $e");
      print("Error fetching user warehouse: $e");
      return [];
    }
  }


}