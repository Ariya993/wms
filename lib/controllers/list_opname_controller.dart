// lib/controllers/picklist_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as box;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart';
import 'item_controller.dart';

class ListOpnameController extends GetxController {
  final SAPService _sapB1Service = Get.find<SAPService>();
  final ApiService _apiService = Get.find<ApiService>();
  final ItemController itemcontroller = Get.find<ItemController>();
  final box = GetStorage();
  final RxList<dynamic> _allPicklists = <dynamic>[].obs;
  final RxList<dynamic> displayedPicklists = <dynamic>[].obs;
  final RxString selectedStatusFilter = 'R'.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  var searchQuery = ''.obs;
  var outstandingPickList = <Map<String, dynamic>>[].obs;
  Rx<DateTime> pickDate = DateTime.now().obs;
  RxString pickerName = ''.obs;
  RxString pickerValue = ''.obs;
  Rx<Map<String, dynamic>?> selectedPicker = Rx<Map<String, dynamic>?>(null);
  RxList<Map<String, dynamic>> Picker = <Map<String, dynamic>>[].obs;

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
        fetchList();
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
    await fetchDropdownData();
    ever(_allPicklists, (_) => _filterPicklists());
    ever(selectedStatusFilter, (_) => _filterPicklists());

    await fetchList(reset: true);
    await fetchOutstandingPicklist();
    _filterPicklists();
    // langsung panggil filter di awal
  }

  Future<void> fetchOutstandingPicklist() async {
    isLoading.value = true;
    try {
      final fetchedPicker = await _sapB1Service.getOutstandingPickList();

      outstandingPickList.value = fetchedPicker;
      print(outstandingPickList);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load dropdown: $e",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDropdownData() async {
    isLoading.value = true;
    try {
      final fetchedPicker = await _apiService.getWMSUsers();
      final filteredPickers =
          fetchedPicker.where((picker) {
            return picker['warehouse_code'] == box.read("warehouse_code");
          }).toList();

      Picker.assignAll(filteredPickers);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load dropdown: $e",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> fetchList({
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
    // print(mSource);
    // print(selectedStatusFilter.value);
    // print(mWarehouse);
    try {
      final List<Map<String, dynamic>> pickpack = await _apiService.fetchListOpname(warehouse:mWarehouse);
      
      if (pickpack.isEmpty) {
        hasMoreData.value = false;
      } else {
        _page++;
        //   pickpack.sort((a, b) {
        //   final binA = (a["BinLoc"] ?? "").toString();
        //   final binB = (b["BinLoc"] ?? "").toString();
        //   return binA.compareTo(binB);
        // });
        if (reset) {
          _allPicklists.value = pickpack;
        } else {
          _allPicklists.addAll(pickpack);
        }
        _filterPicklists();
      }
    } catch (e) {
      errorMessage.value = 'Failed to fetch list opname items: $e';
      Get.snackbar(
        "Error",
        "Gagal memuat list opname: ${e.toString()}",
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
              .where((pl) => pl['status'] == selectedStatusFilter.value)
              .toList();
    }
  }

  void changeStatusFilter(String status) {
    selectedStatusFilter.value = status;
  }

  void updatePickedQtyByItemCode(String itemCode, double inputQty) {
    final picklist = currentProcessingPicklist.value;
    if (picklist == null) return;

    List<dynamic> lines = picklist['DocumentLine'] ?? [];

    double remainingQty = inputQty;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i]['ItemCode'] == itemCode) {
        double releasedQty = lines[i]['ReleasedQuantity']?.toDouble() ?? 0.0;
        double pickedQty =
            lines[i]['NewPickedQty']?.toDouble() ??
            (lines[i]['PickedQuantity']?.toDouble() ?? 0.0);

        double need = releasedQty - pickedQty;
        if (need < 0) need = 0;

        if (remainingQty >= need) {
          lines[i]['NewPickedQty'] = pickedQty + need;
          remainingQty -= need;
        } else {
          lines[i]['NewPickedQty'] = pickedQty + remainingQty;
          remainingQty = 0;
        }

        if (remainingQty <= 0) break;
      }
    }

    currentProcessingPicklist.value = {...picklist, 'DocumentLine': lines};
    currentProcessingPicklist.refresh();
  }

  // --- Metode updatePickedQuantity (Sama seperti sebelumnya) ---
  void updatePickedQuantity(int lineIndex, double newQty) {
    if (currentProcessingPicklist.value == null) return;

    final List<dynamic> lines =
        currentProcessingPicklist.value!['InventoryCountingLines'];

    if (lineIndex >= 0 && lineIndex < lines.length) {
      final lineToUpdate = lines[lineIndex];

      final double pickedQty =
          lineToUpdate['CountedQuantity']?.toDouble() ?? 0.0;
      final double releasedQty =
          lineToUpdate['InWarehouseQuantity']?.toDouble() ?? 0.0;
      final double stockOnHand =
          double.tryParse(lineToUpdate['StockOnHand']?.toString() ?? '0.0') ??
          0.0;

      double finalQty = newQty; 

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
      //print(combined);
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

  Future<void> openPicklist() async {
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
       // fetchPickList(reset: true);
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

  Future<void> updatePickList({
    required DateTime pickDate,
    required String pickerName,
    String? note,
    String? warehouse,
    int? id_picklist,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    //(warehouse);
    try {
      final List<Map<String, dynamic>> pickListLines = [];

      final Map<String, dynamic> newPickListPayload = {
        "PickDate": pickDate.toIso8601String(),
        "Name": pickerName,
        "Remarks": note,
      };
      print('Picker value : ${selectedPicker.value?['username']}');
      final createdPickList = await _sapB1Service.updatePickList(
        newPickListPayload,
        id_picklist.toString(),
        itemcontroller.selectedWarehouseFilter.value,
      );
      if (createdPickList == '') {
        String platform = '';

        await _apiService.SendFCM(
          selectedPicker.value?['username'],
          platform,
          'WMS Apps',
          'You have a new pick list',
          '/wms/#/picklist',
        );
        Get.snackbar(
          "Success",
          "Generated Picklist Successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // fetchPickList(
        //   reset: true,
        // ); // Refresh list setelah Pick List berhasil dibuat
      } else {
        errorMessage.value = createdPickList; // Gunakan pesan error dari API
        Get.snackbar(
          "Error",
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value =
          'Terjadi kesalahan saat membuat Pick List: ${e.toString()}';
      Get.snackbar(
        "Error",
        'Terjadi kesalahan saat membuat Pick List: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      print(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelPickList(int id_picklist) async {
    
    isLoading.value = true;
    errorMessage.value = '';
    //(warehouse);
    try {
      final Map<String, dynamic> newPickListPayload = {"Status": 'C'};
      final createdPickList = await _sapB1Service.updatePickList(
        newPickListPayload,
        id_picklist.toString(),
        itemcontroller.selectedWarehouseFilter.value,
      );
      if (createdPickList == '') {
        String platform = '';

        await _apiService.SendFCM(
          selectedPicker.value?['username'],
          platform,
          'WMS Apps',
          'You have a new pick list',
          '/wms/#/picklist',
        );
        Get.snackbar(
          "Success",
          "Cancelled Picklist Successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // fetchPickList(
        //   reset: true,
        // ); // Refresh list setelah Pick List berhasil dibuat
      } else {
        errorMessage.value = createdPickList; // Gunakan pesan error dari API
        Get.snackbar(
          "Error",
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value =
          'Terjadi kesalahan saat cnacel Pick List: ${e.toString()}';
      Get.snackbar(
        "Error",
        'Terjadi kesalahan saat membuat Pick List: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      print(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }



  Future<void> ProsesStockOpname({
    required DateTime pickDate,
    required String pickerName,
    String? note,
    String? warehouse,
    int? docEntry,
    int? docNum,
    int? items,
  }) async {
    isLoading.value = true;

    //(warehouse);
    try {
      if (warehouse == '') {
        warehouse = box.read('warehouse_code');
      }

      if (pickerName == '') {
        Get.snackbar(
          "Failed",
          "Please select picker name",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final Map<String, dynamic> newPickListPayload = {
        "docDate": pickDate.toIso8601String(),
        "pickerName": pickerName,
        "remarks": note,
        "warehouse_code": warehouse,
        "docEntry": docEntry,
        "docNum": docNum,
        "items": items,
        "status": 'R',
        "user_proses": box.read('username') ?? '',
      };
      // print('Picker value : ${selectedPicker.value?['username']}');
      final created = await _apiService.postStockOpname(newPickListPayload);
      if (created) {
        String platform = '';

        await _apiService.SendFCM(
          selectedPicker.value?['username'],
          platform,
          'WMS Apps',
          'You have a new task for stock opname',
          '/wms/#/list-opname',
        ); 
      } 
    } catch (e) {
      Get.snackbar(
        "Error",
        'Terjadi kesalahan saat proses stock opname : ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }


}
