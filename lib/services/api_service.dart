import 'dart:convert';
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
          snackPosition: SnackPosition.TOP,
        ); 
      }
    } catch (e) { 
      throw Exception('Network or server error: $e'); // Lempar exception umum
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
        Get.snackbar("Sukses", "User berhasil ditambahkan!");
        return true;
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = "Terjadi kesalahan";

        if (errorData['errors'] != null) {
          // Ambil semua pesan error dari field 'errors'
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage = errors.entries
              .map((e) => "${e.key}: ${e.value.join(', ')}")
              .join('\n');
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        Get.snackbar("Gagal", errorMessage);
        print("Failed to create user: ${response.body}");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat membuat user: $e");
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
        Get.snackbar("Sukses", "User berhasil di update!");
        return true;
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = "Terjadi kesalahan";

        if (errorData['errors'] != null) {
          // Ambil semua pesan error dari field 'errors'
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage = errors.entries
              .map((e) => "${e.key}: ${e.value.join(', ')}")
              .join('\n');
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        Get.snackbar("Gagal", errorMessage);
        print("Failed to update user: ${response.body}");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat mengupdate user: $e");
      print("Error creating user: $e");
      return false;
    }
  }
}
