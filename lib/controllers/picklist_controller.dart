// lib/controllers/picklist_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart';

class PicklistController extends GetxController {
  final SAPService _sapB1Service = Get.find<SAPService>();
  final ApiService _apiService = Get.find<ApiService>();

  final RxList<dynamic> _allPicklists = <dynamic>[].obs;
  final RxList<dynamic> displayedPicklists = <dynamic>[].obs;
  final RxString selectedStatusFilter = 'R'.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  var searchQuery = ''.obs;
  List<dynamic> get allPicklists => _allPicklists;

  int _page = 0;
  int _pageSize = 1;
  int _maxAutoFetch = 3;
  int _autoFetchCount = 0;
  RxBool hasMoreData = true.obs;
  RxBool isFetchingMore = false.obs;
  // PASTIKAN DEKLARASI INI ADA
  final Rx<Map<String, dynamic>?> currentProcessingPicklist =
      Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchPickList();
    ever(_allPicklists, (_) => _filterPicklists());
    ever(selectedStatusFilter, (_) => _filterPicklists());
  }

  @override
  Future<void> fetchPickList({bool reset = false, String? source}) async {
    if (reset) {
      _page = 0;
      _pageSize = 1;
      _autoFetchCount = 0;
      hasMoreData.value = true;
      // pickableItems.clear();
      // currentSource = source;
    } else {
      if (!hasMoreData.value || isFetchingMore.value) return;
      isFetchingMore.value = true;
    }

    if (reset) isLoading.value = true;
    errorMessage.value = '';

    try {
      final List<Map<String, dynamic>> pickpack = await _sapB1Service
          .getPickList(
            _page * 20,
            selectedStatusFilter.value,
            searchQuery.value,
          );

      if (pickpack.isEmpty) {
        hasMoreData.value = false;
      } else {
        _page++;
        if (reset) {
          _allPicklists.value = pickpack;
        } else {
          _allPicklists.addAll(pickpack);
        }
        _filterPicklists();
      }
    } catch (e) {
      errorMessage.value = 'Failed to fetch pickable items: $e';
      Get.snackbar(
        "Error",
        "Gagal memuat item: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isFetchingMore.value = false;
    }
  }

  void _filterPicklists() {
    if (selectedStatusFilter.value == 'All') {
      displayedPicklists.value = _allPicklists;
    } else {
      displayedPicklists.value =
          _allPicklists
              .where((pl) => pl['Status'] == selectedStatusFilter.value)
              .toList();
    }
  }

  void changeStatusFilter(String status) {
    selectedStatusFilter.value = status;
  }

  // --- Metode updatePickedQuantity (Sama seperti sebelumnya) ---
  void updatePickedQuantity(int lineIndex, double newQty) {
    if (currentProcessingPicklist.value == null) return;

    final List<dynamic> lines =
        currentProcessingPicklist.value!['PickListsLines'];

    if (lineIndex >= 0 && lineIndex < lines.length) {
      final lineToUpdate = lines[lineIndex];

      final double releasedQty =
          lineToUpdate['ReleasedQuantity']?.toDouble() ?? 0.0;
      final double stockOnHand =
          double.tryParse(lineToUpdate['Stock_On_Hand']?.toString() ?? '0.0') ??
          0.0;

      double finalQty = newQty;

      if (finalQty < 0) {
        finalQty = 0.0;
        Get.snackbar(
          'Warning',
          'Picked quantity cannot be negative.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }

      if (finalQty > releasedQty) {
        finalQty = releasedQty;
        Get.snackbar(
          'Warning',
          'Picked quantity cannot exceed released quantity.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      if (finalQty > stockOnHand) {
        finalQty = stockOnHand;
        Get.snackbar(
          'Warning',
          'Picked quantity cannot exceed stock on hand.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }

      lineToUpdate['PickedQuantity'] = finalQty;
      currentProcessingPicklist.refresh();
    }
  }

  // --- Metode onBarcodeScanned (Sama seperti sebelumnya) ---
  void onBarcodeScanned(BarcodeCapture barcodeCapture) {
    if (barcodeCapture.barcodes.isNotEmpty) {
      final String? scannedCode = barcodeCapture.barcodes.first.rawValue;
      if (scannedCode != null && scannedCode.isNotEmpty) {
        processScannedItem(scannedCode);
      } else {
        Get.snackbar(
          'Scan Error',
          'No readable barcode found.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
  }

  // --- Metode processScannedItem (Sama seperti sebelumnya) ---
  void processScannedItem(String scannedItemCode) {
    if (currentProcessingPicklist.value == null) {
      Get.snackbar(
        'Error',
        'No picklist selected for scanning.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final picklist = currentProcessingPicklist.value!;
    final List<dynamic> lines = picklist['PickListsLines'];
    bool itemFound = false;

    for (int i = 0; i < lines.length; i++) {
      final Map<String, dynamic> line = lines[i];
      if (line['ItemCode'] == scannedItemCode) {
        final double releasedQty = line['ReleasedQuantity']?.toDouble() ?? 0.0;
        final double currentPickedQty =
            line['PickedQuantity']?.toDouble() ?? 0.0;
        final double stockOnHand =
            double.tryParse(line['Stock_On_Hand']?.toString() ?? '0.0') ?? 0.0;

        if (currentPickedQty < releasedQty && currentPickedQty < stockOnHand) {
          line['PickedQuantity'] = currentPickedQty + 1.0;
          Get.snackbar(
            'Success',
            'Item ${line['ItemName']} (${line['ItemCode']}) picked! Current: ${line['PickedQuantity'].toStringAsFixed(0)}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          itemFound = true;
          currentProcessingPicklist.refresh();
          break;
        } else {
          Get.snackbar(
            'Warning',
            'Item ${line['ItemName']} (${line['ItemCode']}) already fully picked or out of stock.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          itemFound = true;
          break;
        }
      }
    }

    if (!itemFound) {
      Get.snackbar(
        'Error',
        'Scanned item ($scannedItemCode) not found in this picklist.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // --- Metode completePicklist (Sama seperti sebelumnya) ---
  Future<void> completePicklist() async {
    if (currentProcessingPicklist.value == null) {
      Get.snackbar(
        'Error',
        'No picklist selected to complete.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final picklist = currentProcessingPicklist.value!;
      final Map<String, dynamic> dataToUpdate = {
        "AbsoluteEntry": picklist["AbsoluteEntry"],
        "PickListsLines":
            picklist["DocumentLine"].map((line) {
              final pickedQty = line["PickedQuantity"]?.toDouble() ?? 0.0;
              final releasedQty = line["ReleasedQuantity"]?.toDouble() ?? 0.0;
              final finalPickedQty =
                  pickedQty > releasedQty ? releasedQty : pickedQty;

              return {
                "LineNumber": line["LineNumber"],
                "OrderEntry": line["OrderEntry"],
                "PickedQuantity": pickedQty,
              };
            }).toList(),
      };

      // TODO: Panggil API Anda untuk mengupdate PickList di SAP B1
      await Future.delayed(const Duration(seconds: 1));

      Get.snackbar(
        'Success',
        'Picklist ${picklist['Name']} updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
      fetchPickList();
    } catch (e) {
      errorMessage.value = 'Failed to update picklist: ${e.toString()}';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
