import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../helper/endpoint.dart';

class ItemController extends GetxController {
  RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;
  RxInt page = 1.obs;

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchItems();
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

    if (query.isNotEmpty) {
      page.value = 1;
      items.clear();
    }  
    final session = box.read('sessionId') ?? '';
    if (session.isEmpty) {
      Get.snackbar("Session Error", "Session login not found. Please login again.",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      box.erase();
      Get.offAllNamed('/login');
      isLoading.value = false;
      isLoadingMore.value = false;
      return;
    }

    try {
      final int skip = (page.value - 1) * 20; 
      // Sesuaikan dengan struktur API kamu
         final url = Uri.parse('$apiItem?skip=$skip&filter=$query'); 

      final res = await http.get(url, headers: {
        'session': session,
        'Accept': 'application/json',
      });

      if (res.statusCode == 200) {
        final firstDecoded = json.decode(res.body);
          final Map<String, dynamic> data = json.decode(firstDecoded); // hasilnya Map

        final List<dynamic> newItemsRaw = data['value'] ?? [];

        final List<Map<String, dynamic>> transformedItems = newItemsRaw
            .whereType<Map<String, dynamic>>()
            .toList();
        if (isLoadMore) {
          items.addAll(transformedItems);
        } else {
          items.value = transformedItems;
        }

        if (data['odata.nextLink'] != null && (data['odata.nextLink'] as String).isNotEmpty) {
          hasMore.value = true;
          page.value++;
        } else {
          hasMore.value = false;
        }
      } else if (res.statusCode == 401 || res.body.contains('Session expired')) {
        Get.snackbar("Session Expired", "Please login again.",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
        box.erase();
        Get.offAllNamed('/login');
      } else {
        Get.snackbar("Error", "Failed get data Items. Status: ${res.statusCode}",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Exception", "Terjadi kesalahan: ${e.toString()}",snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.redAccent, colorText: Colors.white);
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
}
