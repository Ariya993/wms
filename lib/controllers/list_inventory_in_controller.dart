import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import 'package:wms/services/sap_service.dart';

import 'item_controller.dart';

class ListInventoryInController extends GetxController {
  final SAPService service = Get.find<SAPService>();
  // ListInventoryInController({required this.service});
  final itemController = Get.find<ItemController>();

  RxList<String> warehouseList = <String>[].obs;
  RxMap<String, String> warehouseMap = <String, String>{}.obs;

  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;
  RxString searchText = ''.obs;
  RxString filterSource = ''.obs;
  String? currentSource;
  int _page = 0;
  int _pageSize = 1; // Mungkin perlu disesuaikan jika ingin fetch lebih banyak per halaman
  int _maxAutoFetch = 3;
  int _autoFetchCount = 0;
  int _loop = 0;
  RxBool hasMoreData = true.obs;
  RxBool isLoadMore = false.obs;
  RxString filterStatus = ''.obs;
  RxString filterWarehouse = ''.obs;

  final box = GetStorage();
  final RxList<Map<String, dynamic>> filteredItems =
      <Map<String, dynamic>>[].obs;
  @override
  void onInit() {
    super.onInit();
    warehouseList.assignAll(itemController.selectedWarehouses);
    warehouseMap.assignAll(itemController.warehouseCodeNameMap);
    filterWarehouse.value = box.read('warehouse_code');
     fetchData(reset: true,source: filterSource.value ,warehouse: filterWarehouse.value );
    everAll([ 
      filterStatus
    ], (_) => applyFilter());

    debounce<String>(
      searchText,
      (value) {
        if (value != null && value.trim().length >= 3) {
          fetchData(reset: true);
        }
      },
      time: Duration(milliseconds: 500),
    );

  }

  Future loadMore({String? source, String? warehouse}) async {
    if (isLoadMore.value) return;
    isLoadMore.value = true;
    _page++;
    warehouse ??= box.read('warehouse_code');
    final more = await service.getInventoryInList(
      _page * 10, // Offset untuk pagination
      source ?? currentSource ?? '',
      searchText.value,
      warehouse,filterStatus.value
    ); 
    
    final seenKeys = items.map((e) => '${e['DocEntry']}_${e['SourceType']}').toSet();
    final newItems = more.where((e) {
      final key = '${e['DocEntry']}_${e['SourceType']}';
      if (seenKeys.contains(key)) return false;
      seenKeys.add(key);
      return true;
    }).map((e) => e as Map<String, dynamic>).toList();

    items.addAll(newItems);
 
    isLoadMore.value = false;
  }
 
  void updateDocument(Map<String, dynamic> updatedData) async {
  // try {
  //   isLoading(true);
  //   final response = await ser.updateInventoryDocument(updatedData);
  //   if (response.success) {
  //     fetchData(reset: true);
  //     Get.snackbar("Success", "Document updated successfully");
  //   } else {
  //     Get.snackbar("Failed", response.message);
  //   }
  // } catch (e) {
  //   Get.snackbar("Error", "Failed to update document");
  // } finally {
  //   isLoading(false);
  // }
}

  void applyFilter() {
    final q = searchText.value.toLowerCase();
    final src = filterSource.value;
    final stat = filterStatus.value;
    final wh = filterWarehouse.value;

    filteredItems.assignAll(
      items.where((e) {
        final matchSearch =
            q.isEmpty ||
            (e['DocNum']?.toString().toLowerCase().contains(q) ?? false) ||
            (e['CardName']?.toString().toLowerCase().contains(q) ?? false);

        final matchSource =
            src.isEmpty ||
            (e['SourceType'] ?? '').toString().toLowerCase() == src;
        final matchWarehouse =
            wh.isEmpty ||
            (e['DocumentLine'] as List).any((l) => l['WarehouseCode'] == wh);

        // Status logic
        String statValue;
        if (e['Cancelled'] == 'Y') {
          statValue = "Canceled";
        } else if (e['DocumentStatus'] == 'C') {
          statValue = "Closed";
        } else {
          statValue = "Open";
        }
        final matchStatus = stat.isEmpty || stat == statValue;

        return matchSearch && matchSource && matchWarehouse && matchStatus;
      }),
    );
  }

  Future<void> fetchData({
    bool reset = false,
    String? source,
    String? warehouse,
  }) async {
    try {
      if (reset) {
        _page = 0;
        _pageSize = 1; // Reset juga pageSize
        _autoFetchCount = 0;
        hasMoreData.value = true;
        items.clear();
        currentSource = source;
      } else {
        if (!hasMoreData.value || isLoadMore.value) return;
        isLoadMore.value = true;
      }

      if (reset) isLoading.value = true;
      warehouse ??= box.read('warehouse_code');
      final data = await service.getInventoryInList(
        _page * 10, // Offset untuk pagination
        source ?? currentSource ?? '',
        searchText.value,
        warehouse,filterStatus.value
      );
 
      final seen = <String>{};
      final uniqueData = data.where((e) {
        final key = '${e['DocEntry']}_${e['SourceType']}';
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).map((e) => e as Map<String, dynamic>).toList();

      items.assignAll(uniqueData);
 
      if (items.length <= 7 && _autoFetchCount < _maxAutoFetch) {
        _autoFetchCount++;
          await loadMore(source: source, warehouse: warehouse);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
       isLoading.value = false;
      isLoadMore.value = false; 
    }
  }

  String getStatus(Map<String, dynamic> e) {
    if (e["Cancelled"] == "tYES") return "Canceled";
    if (e["DocumentStatus"] == "bost_Close") return "Closed";
    return "Open";
  }

  Future<void> edit(Map<String, dynamic> data) async {
    int docEntry = data['DocEntry'];
    String source =
        data['source']; // “InventoryGenEntries” atau “PurchaseDeliveryNotes”

    // isi body patch-nya sesuai kebutuhan kamu
    Map<String, dynamic> body = {"Comments": "Edited via mobile"};

    bool ok = await service.editInventoryIn(source, docEntry, body);
    if (ok) {
      Get.snackbar('Success', 'Edited successfully',backgroundColor:
            Colors
                .green, // Ganti dari merah ke orange karena mungkin sudah di-pick semua
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,);
      fetchData(reset: true);
    } else {
      Get.snackbar('Failed', 'Edit failed');
    }
  }

  Future<void> cancel(Map<String, dynamic> data) async {
    int docEntry = data['DocEntry'];
    String source = data['SourceType'];

    bool ok = await service.cancelInventoryIn(source, docEntry);
    if (ok) {
      Get.snackbar('Success', 'Canceled successfully',backgroundColor:
            Colors
                .green, // Ganti dari merah ke orange karena mungkin sudah di-pick semua
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,);
      fetchData(reset: true);
    } else {
      Get.snackbar('Failed', 'Cancel failed',backgroundColor:
            Colors
                .red, // Ganti dari merah ke orange karena mungkin sudah di-pick semua
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,);
    }
  }
}
