import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserManageController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Rx<Map<String, dynamic>?> selectedWarehouse = Rx<Map<String, dynamic>?>(null);
  Rx<Map<String, dynamic>?> selectedSuperior = Rx<Map<String, dynamic>?>(null);

  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> warehouses = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> wmsUsers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    isLoading.value = true;
    try {
      final fetchedWarehouses = await _apiService.getWarehouses();
      final fetchedWMSUsers = await _apiService.getWMSUsers();

      warehouses.assignAll(fetchedWarehouses);
      wmsUsers.assignAll(fetchedWMSUsers);
    } catch (e) {
      Get.snackbar("Error", "Failed to load dropdown: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createUser() async {
    if (_validateInputs()) {
      isLoading.value = true;
      try {
        final userData = {
          'username': usernameController.text,
          'nama': nameController.text,
          'password': passwordController.text,
          'warehouse_code': selectedWarehouse.value?['warehouseCode'], // SESUAIKAN DENGAN KEY JSON ANDA
          'id_atasan': selectedSuperior.value?['id'], // SESUAIKAN DENGAN KEY JSON ANDA
        };

        bool success = await _apiService.createUser(userData);
        if (success) {
          _clearForm();
        }
      } catch (e) {
        Get.snackbar("Error", "Falied to create user: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      } finally {
        isLoading.value = false;
      }
    }
  }
Future<void> updateUser(int id) async {
    if (_validateUpdate()) {
      isLoading.value = true;
      try {
        final userData = {
          'id': id, // Tambahkan ID untuk update
          'username': usernameController.text,
          'nama': nameController.text,
          'password': passwordController.text,
          'warehouse_code': selectedWarehouse.value?['warehouseCode'], // SESUAIKAN DENGAN KEY JSON ANDA
          'id_atasan': selectedSuperior.value?['id'], // SESUAIKAN DENGAN KEY JSON ANDA
        };

        bool success = await _apiService.updateUser(id,userData);
        if (success) {
          _clearForm();
        }
      } catch (e) {
        Get.snackbar("Error", "Failed to update user: $e",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      } finally {
        isLoading.value = false;
      }
    }
  }
  bool _validateInputs() {
    if (usernameController.text.isEmpty ||
        nameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        selectedWarehouse.value == null ||
        selectedSuperior.value == null) {
      Get.snackbar("Warning", "All field must be filled!",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return false;
    }
    return true;
  }
 bool _validateUpdate() {
    if (usernameController.text.isEmpty ||
        nameController.text.isEmpty || 
        selectedWarehouse.value == null ||
        selectedSuperior.value == null) {
      Get.snackbar("Warning", "All field must be filled!",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
    return true;
  }
  void _clearForm() {
    usernameController.clear();
    nameController.clear();
    passwordController.clear();
    selectedWarehouse.value = null;
    selectedSuperior.value = null;
  }

  @override
  void onClose() {
    usernameController.dispose();
    nameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}