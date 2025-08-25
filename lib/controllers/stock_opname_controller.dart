// lib/controllers/goods_receipt_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:wms/controllers/item_controller.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart';
import '../widgets/custom_dropdown_search.dart';

// enum StockInMode { poBased, nonPo,grgi }

class StockOpnameController extends GetxController {
  final SAPService _apiService = Get.find<SAPService>();
  final ApiService _apiServices = Get.find<ApiService>();
  final ItemController itemcontroller = Get.find<ItemController>();

  var isLoading = false.obs;

  // --- PO Based Goods Receipt ---
  final TextEditingController soNumberController = TextEditingController();
  final Rxn<Map<String, dynamic>> stockOpname = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> soItems = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> currentProcessingPicklist =
      Rx<Map<String, dynamic>?>(null);

  final RxString errorMessage = ''.obs;
  final RxList<Map<String, dynamic>> vendorList = <Map<String, dynamic>>[].obs;
  final RxString selectedVendor = ''.obs;
  Rx<Map<String, dynamic>?> selectedWarehouse = Rx<Map<String, dynamic>?>(null);
  RxList<Map<String, dynamic>> warehouses = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> wmsUsers = <Map<String, dynamic>>[].obs;

  Rx<DateTime> pickDate = DateTime.now().obs;
  RxString pickerName = ''.obs;
  RxString pickerValue = ''.obs;
  Rx<Map<String, dynamic>?> selectedPicker = Rx<Map<String, dynamic>?>(null);
  RxList<Map<String, dynamic>> Picker = <Map<String, dynamic>>[].obs;
  var outstandingPickList = <Map<String, dynamic>>[].obs;
  RxString note = ''.obs; // Tambahkan ini jika belum ada

  final box = GetStorage();
  @override
  void onInit() {
    super.onInit();
    // fetchDropdownData();
    init();
  }

  @override
  void onClose() {
    soNumberController.dispose();
    super.onClose();
  }

  Future<void> init() async {
    // await fetchDropdownData();
    //  searchQuery.value = '';
    // await fetchPickableItems(reset: true);
    await Future.wait([
      fetchDropdownData(),
      fetchDropdownDataWareouse(),
      fetchOutstandingPicklist(),
    ]);
  }

  void resetForm() {
    isLoading.value = false;

    soNumberController.clear();
    stockOpname.value = null;
    soItems.clear();
  }

  void updatePickedQtyByItemCode(String itemCode, double inputQty) {
    final picklist = currentProcessingPicklist.value;
    if (picklist == null) return;

    List<dynamic> lines = picklist['DocumentLine'] ?? [];

    double remainingQty = inputQty;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i]['ItemCode'] == itemCode) {
        double releasedQty = lines[i]['InWarehouseQuantity']?.toDouble() ?? 0.0;
        double pickedQty =
            lines[i]['NewPickedQty']?.toDouble() ??
            (lines[i]['CountedQuantity']?.toDouble() ?? 0.0);

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

  Future<void> fetchOutstandingPicklist() async {
    isLoading.value = true;
    try {
      final fetchedPicker = await _apiService.getOutstandingPickList();

      outstandingPickList.value = fetchedPicker;
      // print(outstandingPickList);
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
      final fetchedPicker = await _apiServices.getWMSUsers();
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

  Future<void> fetchDropdownDataWareouse() async {
    isLoading.value = true;
    try {
      final fetchedWarehouses = await _apiServices.getWarehouses();
      final fetchedWMSUsers = await _apiServices.getWMSUsers();

      warehouses.assignAll(fetchedWarehouses);
      wmsUsers.assignAll(fetchedWMSUsers);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load dropdown: $e",
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchSO() async {
    if (soNumberController.text.isEmpty) {
      Get.snackbar(
        'Input Required',
        'Please enter a document number.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    stockOpname.value = null;
    soItems.clear();

    final data = await _apiService.fetchStockOpname(soNumberController.text);
    // final data = await _apiService.fetchPoDetails(soNumberController.text);

    if (data != null) {
      try {
        stockOpname.value = {
          "DocumentEntry": data["DocumentEntry"],
          "DocumentNumber": data["DocumentNumber"],
          "CountDate": data["CountDate"],
          "Remarks": data["Remarks"] ?? '',
          "DocumentStatus": data["DocumentStatus"],
          "DocumentLine": data["Lines"],
        };

        if (stockOpname.value!["DocumentStatus"] != "cdsOpen") {
          stockOpname.value = null;
          Get.snackbar(
            'Info',
            'Stock opname ${data["DocumentNumber"]} is not open.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orangeAccent.shade700,
            colorText: Colors.white,
          );
          return;
        }
        final lines = List<Map<String, dynamic>>.from(data["Lines"]);
        final openItems =
            lines
                .where((item) => (item["InWarehouseQuantity"] ?? 0) > 0)
                .toList();
 
        soItems.assignAll(openItems);

        if (openItems.isEmpty) {
          Get.snackbar(
            'Info',
            'Stock opname ${data["DocumentNumber"]} has no open items.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orangeAccent.shade700,
            colorText: Colors.white,
          );
        }
        currentProcessingPicklist.value = stockOpname.value;
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to process stock opname data: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        stockOpname.value = null;
      }
    }
    isLoading.value = false;
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
      final created = await _apiServices.postStockOpname(newPickListPayload);
      if (created) {
        String platform = '';

        await _apiServices.SendFCM(
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

  void updatePickedQuantity(int lineIndex, double newQty) {
    if (currentProcessingPicklist.value == null) return;

    final List<dynamic> lines =
        currentProcessingPicklist.value!['DocumentLine'];

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
      print(finalQty);
      lineToUpdate["NewPickedQty"] = finalQty;
      currentProcessingPicklist.refresh();
    }
  }

  void handleScanResult(String scannedItemCode) async {
    if (currentProcessingPicklist.value == null) {
      Get.snackbar(
        'Error',
        'No selected item for scanning.',
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
        final double releasedQty =
            line['InWarehouseQuantity']?.toDouble() ?? 0.0;
        final double currentPickedQty =
            line['CountedQuantity']?.toDouble() ?? 0.0;
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
          targetLine['CountedQuantity']?.toDouble() ?? 0.0;
      final double currentPickedQty =
          targetLine['CountedQuantity']?.toDouble() ?? 0.0;
      final double newPicked = targetLine['NewPickedQty']?.toDouble() ?? 0.0;
      final double releasedQty =
          targetLine['InWarehouseQuantity']?.toDouble() ?? 0.0;
      final double stockOnHand =
          double.tryParse(targetLine['StockOnHand']?.toString() ?? '0.0') ??
          0.0;

      // targetLine['PickedQuantity'] = currentPickedQty + 1.0;
      final double combined = alreadyPicked + newPicked + 1.0;
      // print(combined);
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
        'Item ${targetLine['ItemDescription']} (${targetLine['ItemCode']}) picked from Order ${targetLine['OrderEntry']}! Current: ${targetLine['PickedQuantity'].toStringAsFixed(0)}',
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

  Future<void> completeStockOpname() async {
    if (currentProcessingPicklist.value == null) {
      Get.snackbar(
        'Error',
        'No data to be complete.',
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
        "InventoryCountingLines":
            picklist["DocumentLine"].map((line) {  
              line["NewPickedQty"] = line["NewPickedQty"] ?? 0;

              // final InWarehouseQuantity =
              //     line["InWarehouseQuantity"]?.toDouble() ?? 0.0;

              final double pickedQtyBefore =
                  line["CountedQuantity"]?.toDouble() ?? 0.0;
              final double newPicked = line["NewPickedQty"]?.toDouble() ?? 0.0;
             
                double finalPickedQty = pickedQtyBefore + newPicked;
              if(pickedQtyBefore>0 && newPicked==0)
               {
                  finalPickedQty =  newPicked;
               }
             // final double finalPickedQty =  newPicked; 
              return {
                "LineNumber": line["LineNumber"],
                "CountedQuantity": finalPickedQty,
              };
            }).toList(),
      };
      
      final rslt = await _apiService.updateStockOpname(
        dataToUpdate,
        picklist["DocumentEntry"].toString(),
        warehouse,
      );
     
      if (rslt == '') {
        _apiService.fetchStockOpname(picklist["DocumentNumber"].toString());
        for (var line in picklist["DocumentLine"]) {
          line.remove('NewPickedQty');
        }
        String plaform = '';
        String atasan = box.read('atasan');
        String user = box.read('username');
        await _apiServices.SendFCM(
          atasan,
          plaform,
          'WMS Apps',
          'Stock opname has been submited by $user',
          '/wms/#/list-opname',
        );
        await Future.delayed(const Duration(seconds: 1));

        Get.snackbar(
          "Success",
          "Stock opname has been submited",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // fetchPickList(reset: true);
        
          Get.toNamed('/list-opname');
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
      errorMessage.value = 'Failed to update stock opname: ${e.toString()}';
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
