// lib/controllers/picklist_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as box;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart';

class PicklistController extends GetxController {
  final SAPService _sapB1Service = Get.find<SAPService>();
  final ApiService _apiService = Get.find<ApiService>();
  final box = GetStorage();
  final RxList<dynamic> _allPicklists = <dynamic>[].obs;
  final RxList<dynamic> displayedPicklists = <dynamic>[].obs;
  final RxString selectedStatusFilter = 'R'.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  var searchQuery = ''.obs;
  List<dynamic> get allPicklists => _allPicklists;

  int _page = 0;
  int _pageSize = 0;
  int _maxAutoFetch = 3;
  int _autoFetchCount = 0;
  RxBool hasMoreData = true.obs;
  RxBool isFetchingMore = false.obs;
  // PASTIKAN DEKLARASI INI ADA
  final Rx<Map<String, dynamic>?> currentProcessingPicklist =
      Rx<Map<String, dynamic>?>(null);
  final ScrollController scrollController = ScrollController();

  void setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        fetchPickList();
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    setupScrollListener(); // tunggu hingga data datang

    ever(_allPicklists, (_) => _filterPicklists());
    ever(selectedStatusFilter, (_) => _filterPicklists());
    await fetchPickList(reset: true);
    _filterPicklists();
    // langsung panggil filter di awal
  }

  @override
  Future<void> fetchPickList({
    bool reset = false,
    String? source,
    String? warehouse,
  }) async {
    if (reset) {
      _page = 0;
      _autoFetchCount = 0;
      hasMoreData.value = true;
      _allPicklists.clear();
      displayedPicklists.clear();
      // currentSource = source;
    } else {
      if (!hasMoreData.value || isFetchingMore.value) return;
      isFetchingMore.value = true;
    }

    if (reset) isLoading.value = true;
    errorMessage.value = '';
    warehouse ??= box.read('warehouse_code');
    String mSource = source.toString();
    String mWarehouse = warehouse.toString();
    print(mSource);
    print(selectedStatusFilter.value);
    print(mWarehouse);
    try {
      final List<Map<String, dynamic>> pickpack = await _sapB1Service
          .getPickList(
            _page * 20,
            source ?? selectedStatusFilter.value,
            searchQuery.value,
            warehouse,
          );
      print(pickpack);
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
        "Gagal memuat picklist: ${e.toString()}",
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
        currentProcessingPicklist.value!['DocumentLine'];

    if (lineIndex >= 0 && lineIndex < lines.length) {
      final lineToUpdate = lines[lineIndex];

      final double pickedQty =
          lineToUpdate['PickedQuantity']?.toDouble() ?? 0.0;
      final double releasedQty =
          lineToUpdate['ReleasedQuantity']?.toDouble() ?? 0.0;
      final double stockOnHand =
          double.tryParse(lineToUpdate['StockOnHand']?.toString() ?? '0.0') ??
          0.0;

      double finalQty = newQty;
      // final double allowedMax = releasedQty - pickedQty;

      //  if (finalQty > allowedMax) {
      //     finalQty = allowedMax;
      //     Get.snackbar('Warning','Picked quantity cannot exceed released quantity.',
      //         backgroundColor: Colors.orange, colorText: Colors.white);
      //   }

      if (finalQty < 0) finalQty = 0;
      if (finalQty > releasedQty) {
        finalQty = releasedQty;
        Get.snackbar(
          'Warning',
          'Cannot exceed released quantity',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      if (finalQty > stockOnHand) {
        finalQty = stockOnHand;
        Get.snackbar(
          'Warning',
          'Cannot exceed stock on hand',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      // lineToUpdate['PickedQuantity'] = finalQty ;
      lineToUpdate["NewPickedQty"] = finalQty;
      currentProcessingPicklist.refresh();
    }
  }

  // --- Metode onBarcodeScanned (Sama seperti sebelumnya) ---
  void onBarcodeScanned(BarcodeCapture barcodeCapture) {
    if (barcodeCapture.barcodes.isNotEmpty) {
      final String? scannedCode = barcodeCapture.barcodes.first.rawValue;
      if (scannedCode != null && scannedCode.isNotEmpty) {
        print(scannedCode);
        processScannedItem(scannedCode);
      } else {
        Get.snackbar(
          'Scan Error',
          'No readable barcode found.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
  }

  // Di dalam PicklistController
  void processScannedItem(String scannedItemCode) {
    // Hanya menerima ItemCode
    if (currentProcessingPicklist.value == null) {
      Get.snackbar(
        'Error',
        'No picklist selected for scanning.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final picklist = currentProcessingPicklist.value!;
    final List<dynamic> lines = picklist['DocumentLine'] ?? [];

    Map<String, dynamic>?
    targetLine; // Untuk menyimpan baris yang akan diupdate

    // Strategi: Cari baris yang ItemCode-nya cocok DAN belum sepenuhnya di-pick
    for (int i = 0; i < lines.length; i++) {
      final Map<String, dynamic> line = lines[i];
      if (line['ItemCode'] == scannedItemCode) {
        final double releasedQty = line['ReleasedQuantity']?.toDouble() ?? 0.0;
        final double currentPickedQty =
            line['PickedQuantity']?.toDouble() ?? 0.0;
        final double stockOnHand =
            double.tryParse(line['StockOnHand']?.toString() ?? '0.0') ?? 0.0;

        // Prioritaskan baris yang masih bisa di-pick
        if (currentPickedQty < releasedQty && currentPickedQty < stockOnHand) {
          targetLine = line;
          break; // Ditemukan baris yang valid, keluar dari loop
        }
      }
    }

    if (targetLine != null) {
      // Update kuantitas untuk targetLine
      final double alreadyPicked =
          targetLine['PickedQuantity']?.toDouble() ?? 0.0;
      final double currentPickedQty =
          targetLine['PickedQuantity']?.toDouble() ?? 0.0;
      final double newPicked = targetLine['NewPickedQty']?.toDouble() ?? 0.0;
      final double releasedQty =
          targetLine['ReleasedQuantity']?.toDouble() ?? 0.0;
      final double stockOnHand =
          double.tryParse(targetLine['StockOnHand']?.toString() ?? '0.0') ??
          0.0;
    
      // targetLine['PickedQuantity'] = currentPickedQty + 1.0;
      final double combined = alreadyPicked + newPicked + 1.0;
      print(combined);
      if (combined > releasedQty) {
        Get.snackbar(
          'Warning',
          'Cannot exceed released quantity!',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
      if (combined > stockOnHand) {
        Get.snackbar(
          'Warning',
          'Cannot exceed stock on hand!',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // increment qty sementara
      targetLine['NewPickedQty'] = newPicked + 1.0;
      Get.snackbar(
        'Success',
        'Item ${targetLine['ItemName']} (${targetLine['ItemCode']}) picked from Order ${targetLine['OrderEntry']}! Current: ${targetLine['PickedQuantity'].toStringAsFixed(0)}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      currentProcessingPicklist.refresh();
    } else {
      // Jika tidak ada baris yang cocok atau semua baris sudah penuh
      Get.snackbar(
        'Warning',
        'Scanned item ($scannedItemCode) not found or all matching items are already fully picked in this picklist.',
        backgroundColor:
            Colors
                .orange, // Ganti dari merah ke orange karena mungkin sudah di-pick semua
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // --- Metode completePicklist (Sama seperti sebelumnya) ---
  Future<void> completePicklist() async {
    if (currentProcessingPicklist.value == null) {
      Get.snackbar(
        'Error',
        'No picklist selected to complete.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final picklist = currentProcessingPicklist.value!;
      final warehouse = picklist["DocumentLine"][0]["WarehouseCode"];
      final Map<String, dynamic> dataToUpdate = {
        "PickListsLines":
            picklist["DocumentLine"].map((line) {
              // final pickedQty = line["PickedQuantity"]?.toDouble() ?? 0.0;
              final releasedQty = line["ReleasedQuantity"]?.toDouble() ?? 0.0;
              final orderdQty =
                  line["PreviouslyReleasedQuantity"]?.toDouble() ?? 0.0;

              final double pickedQtyBefore =
                  line["PickedQuantity"]?.toDouble() ?? 0.0;
              final double newPicked = line["NewPickedQty"]?.toDouble() ?? 0.0;
              final double finalPickedQty = pickedQtyBefore + newPicked;

               final double sendQty = line["NewPickedQty"]?.toDouble()
        ?? (line["PickedQuantity"]?.toDouble() ?? 0.0);

              print(pickedQtyBefore);
              print(newPicked);
              print(finalPickedQty);
              print(sendQty);
              return {
                "LineNumber": line["LineNumber"],
                "PickedQuantity": finalPickedQty,
              };
            }).toList(),
      };

      final rslt = await _sapB1Service.updatePickList(
        dataToUpdate,
        picklist["Absoluteentry"],
        warehouse,
      );
      if (rslt == '') {
        for (var line in picklist["DocumentLine"]) {
          line.remove('NewPickedQty');
        }
        String plaform = '';
        String atasan = box.read('atasan');
        String user = box.read('username');
        await _apiService.SendFCM(
          atasan,
          plaform,
          'WMS Apps',
          '$user - Pick List has been completed',
          '/wms/#/pickpack',
        );
        await Future.delayed(const Duration(seconds: 1));

        Get.snackbar(
          "Success",
          "Picklist Submitted",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchPickList(reset: true);
        Get.offAllNamed('/picklist');

        // Get.back();
      } else {
        errorMessage.value = "Failed";
        Get.snackbar(
          "Error",
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
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

  Future<void> cancelPicklist() async {
    if (currentProcessingPicklist.value == null) {
      Get.snackbar(
        'Error',
        'No picklist selected to un-released.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final picklist = currentProcessingPicklist.value!;
      final warehouse = picklist["DocumentLine"][0]["WarehouseCode"];
      final Map<String, dynamic> dataToUpdate = {
        "PickListsLines":
            picklist["DocumentLine"].map((line) {
              final pickedQty = line["PickedQuantity"]?.toDouble() ?? 0.0;
              final releasedQty = line["ReleasedQuantity"]?.toDouble() ?? 0.0;

              //  final finalPickedQty = pickedQty;
              //   final finalreleasedQty = pickedQty

              return {
                "LineNumber": line["LineNumber"],
                "PickedQuantity": releasedQty,
              };
            }).toList(),
      };

      final rslt = await _sapB1Service.updatePickList(
        dataToUpdate,
        picklist["Absoluteentry"],
        warehouse,
      );
      if (rslt == '') {
        String plaform = '';
        String atasan = box.read('atasan');
        String user = box.read('username');
        await _apiService.SendFCM(
          atasan,
          plaform,
          'WMS Apps',
          '$user - Pick List has been opened',
          '/wms/#/pickpack',
        );
        await Future.delayed(const Duration(seconds: 1));

        Get.snackbar(
          "Success",
          "Picklist opened",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchPickList(reset: true);
        Get.offAllNamed('/picklist');
      } else {
        errorMessage.value = "Failed";
        Get.snackbar(
          "Error",
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to open picklist: ${e.toString()}';
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
