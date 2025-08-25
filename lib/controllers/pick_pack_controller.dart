import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // Import ini dibutuhkan untuk Get.snackbar
import 'package:get_storage/get_storage.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart';
import 'item_controller.dart'; // Pastikan path ini benar sesuai struktur proyek Anda

// Class untuk merepresentasikan baris item yang akan di-pick di UI
class PickableItem {
  final String
  docType; // "order" (Sales Order) atau "transfer" (Inventory Transfer Request)
  final int docEntry;
  final String docNum;
  final String? cardCode;
  final String? cardName;
  final int docLineNum;
  final String itemCode;
  final String itemName;
  final String
  sourceWarehouseCode; // Gudang tempat pick dilakukan (WarehouseCode for SO, FromWarehouseCode for ITR)
  final double orderedQuantity; // Kuantitas asli di dokumen
  final double openQuantity; // Kuantitas yang tersisa untuk di-pick
  late TextEditingController pickedQtyController;
  RxDouble pickedQuantity;
  RxDouble inStock; // Data stok dari backend
  RxDouble committed; // Data stok dari backend
  RxDouble orderedFromPO; // Data stok dari backend
  final double
  originalAvailableQuantity; // <-- NEW: Kuantitas tersedia asli dari backend
  RxDouble
  availableQuantity; // Data stok dari backend (ini tetap cerminan dari backend)
  RxDouble
  simulatedAvailableQuantity; // <-- NEW: Kuantitas tersedia yang disimulasikan di frontend
  RxBool isSelected;
  RxString note = ''.obs;
  PickableItem({
    required this.docType,
    required this.docEntry,
    required this.docNum,
    this.cardCode,
    this.cardName,
    required this.docLineNum,
    required this.itemCode,
    required this.itemName,
    required this.sourceWarehouseCode,
    required this.orderedQuantity,
    required this.openQuantity,
    // Asumsi ini sudah dari backend
    required double initialInStock,
    required double initialCommitted,
    required double initialOrderedFromPO,
    required double initialAvailableQuantity,
  }) : pickedQuantity = 0.0.obs, // Default awal 0
       inStock = initialInStock.obs,
       committed = initialCommitted.obs,
       orderedFromPO = initialOrderedFromPO.obs,
       availableQuantity =
           initialAvailableQuantity.obs, // Ini tetap available dari backend
       originalAvailableQuantity =
           initialAvailableQuantity, // Simpan nilai asli
       simulatedAvailableQuantity =
           initialAvailableQuantity.obs, // Mulai dengan nilai asli
       isSelected = false.obs {
    pickedQtyController = TextEditingController(
      text: pickedQuantity.value.toStringAsFixed(0),
    );

    pickedQuantity.listen((val) {
      final newText = val.toStringAsFixed(0);
      if (pickedQtyController.text != newText) {
        pickedQtyController.text = newText;
        pickedQtyController.selection = TextSelection.fromPosition(
          TextPosition(offset: newText.length),
        );
      }
    });
  }

  void setPickedQuantity(double value) {
    if (value < 0) value = 0; // Kuantitas tidak bisa negatif

    // Batasi hingga openQuantity saja di sini.
    // Batasan simulatedAvailableQuantity akan ditangani di controller utama.
    if (value > openQuantity) {
      pickedQuantity.value = openQuantity;
      // Opsional: tampilkan snackbar di sini jika Anda ingin feedback instan
      // saat melebihi openQuantity SAJA. Validasi stok global akan di controller.
      Get.snackbar(
        "Warning",
        "Quantity pick tidak boleh melebihi Qty Open (${openQuantity.toStringAsFixed(0)}).",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2), // Durasi lebih pendek
      );
    } else {
      pickedQuantity.value = value;
    }
  }
}
// lib/controllers/pick_pack_controller.dart (melanjutkan dari PickableItem class)

class PickPackController extends GetxController {
  final SAPService _sapB1Service = Get.find<SAPService>();
  final ApiService _apiService = Get.find<ApiService>();
  final ItemController itemcontroller = Get.find<ItemController>();
  RxList<PickableItem> pickableItems = <PickableItem>[].obs;
  RxBool isLoading = true.obs;
  var _loadingCounter = 0.obs;
  RxString errorMessage = ''.obs;
  var searchQuery = ''.obs;
  var filterType = 'ALL'.obs;
  int _page = 0;
  int _pageSize =
      1; // Mungkin perlu disesuaikan jika ingin fetch lebih banyak per halaman
  int _maxAutoFetch = 5;
  int _autoFetchCount = 0;
  int _loop = 0;
  RxBool hasMoreData = true.obs;
  RxBool isFetchingMore = false.obs;
  String? currentSource;
  Rx<DateTime> pickDate = DateTime.now().obs;
  RxString pickerName = ''.obs;
  RxString pickerValue = ''.obs;
  Rx<Map<String, dynamic>?> selectedPicker = Rx<Map<String, dynamic>?>(null);
  RxList<Map<String, dynamic>> Picker = <Map<String, dynamic>>[].obs;
  final box = GetStorage();
  var outstandingPickList = <Map<String, dynamic>>[].obs;
  RxString note = ''.obs; // Tambahkan ini jika belum ada
  // Tambahkan filteredItems
  RxList<PickableItem> filteredItems = <PickableItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    init();
    // fetchDropdownData();
    // fetchPickableItems(reset: true);
  }
 void _startLoading() {
  _loadingCounter.value++;
  isLoading.value = true;
}

void _stopLoading() {
  _loadingCounter.value--;
  if (_loadingCounter.value <= 0) {
    isLoading.value = false;
    _loadingCounter.value = 0;
  }
}
  Future<void> init() async {
    // await fetchDropdownData();
    //  searchQuery.value = '';
    // await fetchPickableItems(reset: true);
    await Future.wait([fetchDropdownData(), fetchPickableItems(reset: true),fetchOutstandingPicklist()]);
  }
Future<void> fetchOutstandingPicklist() async {
   _startLoading();
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
     _stopLoading();
    }
  }

  Future<void> fetchDropdownData() async {
    _startLoading();
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
     _stopLoading();
    }
  }

  @override
  Future<void> fetchPickableItems({
    bool reset = false,
    String? source,
    String? warehouse,
  }) async {
    final cacheKey = '${source}_${warehouse}_${_page}';
    debugPrint('Fetching pickpack');
    if (reset) {
      _page = 0;
      _pageSize = 1; // Reset juga pageSize
      _autoFetchCount = 0;
      hasMoreData.value = true;
      pickableItems.clear();
      currentSource = source;
    } else {
      if (!hasMoreData.value || isFetchingMore.value) return;
      isFetchingMore.value = true;
    }

    if (reset) _startLoading();
    errorMessage.value = '';
    warehouse ??= box.read('warehouse_code');
    String mSource = source.toString();
    String mWarehouse = warehouse.toString();
 
    try {
      final List<Map<String, dynamic>> pickpack = await _sapB1Service
          .getPickPack(
            _page * 20, // Offset untuk pagination
            source ?? currentSource ?? 'ALL',
            searchQuery.value,
            warehouse,
          );

      if (pickpack.isEmpty) {
        hasMoreData.value = false;
      } else {
        List<PickableItem> tempItems = [];
        for (var doc in pickpack) {
          final String docType = doc['SourceType'] ?? 'Unknown';
          final int docEntry = doc['DocEntry'] as int;
          final String docNum = doc['DocNum']?.toString() ?? 'N/A';
          final String? cardCode = doc['CardCode'] as String?;
          final String? cardName = doc['CardName'] as String?;
          
          final List<dynamic>? docLines = doc['DocumentLine'];

          if (docLines != null) {
            for (var line in docLines) {
              final double openQty =
                  (line['RemainingOpenQuantity'] as num?)?.toDouble() ?? 0.0;
              if (openQty > 0) {
                final String itemCode = line['ItemCode'] ?? '';
                final String itemName = line['ItemDescription'] ?? 'N/A';
                final String sourceWarehouseCode =
                    docType == "order"
                        ? line['WarehouseCode'] ?? ''
                        : line['FromWarehouseCode'] ?? '';
                double onHand = (line['onHand'] as num?)?.toDouble() ?? 0.0;
                double inStock = (line['InStock'] as num?)?.toDouble() ?? 0.0;
                double committed =
                    (line['Committed'] as num?)?.toDouble() ?? 0.0;
                double orderedFromPO =
                    (line['Ordered'] as num?)?.toDouble() ?? 0.0;
                double availableQuantity = 0.0; // Ini akan dihitung di bawah

                // Hitung availableQuantity (dari InStock - Committed + OrderedFromPO)
                availableQuantity = inStock;
                inStock = onHand;
                if (availableQuantity < 0)
                  availableQuantity = 0.0; // Pastikan tidak negatif

                tempItems.add(
                  PickableItem(
                    docType: docType,
                    docEntry: docEntry,
                    docNum: docNum,
                    cardCode: cardCode,
                    cardName: cardName,
                    docLineNum: line['LineNum'] as int,
                    itemCode: itemCode,
                    itemName: itemName,
                    sourceWarehouseCode: sourceWarehouseCode,
                    orderedQuantity:
                        (line['Quantity'] as num?)?.toDouble() ?? 0.0,
                    openQuantity: openQty,
                    initialInStock: inStock,
                    initialCommitted: committed,
                    initialOrderedFromPO: orderedFromPO,
                    initialAvailableQuantity:
                        availableQuantity, // Gunakan hasil perhitungan
                  ),
                );
              }
            }
          }
        }

        for (var item in tempItems) {
          bool isDuplicate = pickableItems.any(
            (existing) =>
                existing.itemCode == item.itemCode &&
                existing.docType == item.docType &&
                existing.sourceWarehouseCode == item.sourceWarehouseCode &&
                existing.docEntry == item.docEntry &&
                existing.docLineNum == item.docLineNum,
          );

          if (!isDuplicate) {
            pickableItems.add(item);
          }
        }

        _page++;
        // Otomatis fetch jika data kurang dari 5 dan masih ada data
        if (tempItems.length <= 8 && _autoFetchCount < _maxAutoFetch) {
          // if(_autoFetchCount == 0)
          // {
          _autoFetchCount++;
          await Future.delayed(const Duration(milliseconds: 300));
          await fetchPickableItems(
            reset: false,
            source: source ?? currentSource ?? 'ALL',
            warehouse: mWarehouse,
          );
          //}
        }
        _updateAllSimulatedAvailableQuantities();
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
    if (reset) _stopLoading();
      isFetchingMore.value = false;
    }
  }

  @override
  Future<void> scanPickableItems({
    bool reset = false,
    String? source,
    String? warehouse,
  }) async {
    if (reset) {
      _page = 0;
      _pageSize = 1; // Reset juga pageSize
      _autoFetchCount = 0;
      hasMoreData.value = true;
      pickableItems.clear();
      currentSource = source;
    } else {
      if (!hasMoreData.value || isFetchingMore.value) return;
      isFetchingMore.value = true;
    }

    if (reset) isLoading.value = true;
    errorMessage.value = '';
    warehouse ??= box.read('warehouse_code');
    String mSource = source.toString();
    String mWarehouse = warehouse.toString();
    // print(warehouse);
    // print(searchQuery.value);
    try {
      final List<Map<String, dynamic>> pickpack = await _sapB1Service
          .getScanPickPack(
            _page * 20, // Offset untuk pagination
            source ?? currentSource ?? '',
            searchQuery.value,
            warehouse,
          );

      if (pickpack.isEmpty) {
        hasMoreData.value = false;
      } else {
        List<PickableItem> tempItems = [];
        for (var doc in pickpack) {
          final String docType = doc['SourceType'] ?? 'Unknown';
          final int docEntry = doc['DocEntry'] as int;
          final String docNum = doc['DocNum']?.toString() ?? 'N/A';
          final String? cardCode = doc['CardCode'] as String?;
          final String? cardName = doc['CardName'] as String?;
          final List<dynamic>? docLines = doc['DocumentLine'];

          if (docLines != null) {
            for (var line in docLines) {
              final double openQty =
                  (line['RemainingOpenQuantity'] as num?)?.toDouble() ?? 0.0;
              if (openQty > 0) {
                final String itemCode = line['ItemCode'] ?? '';
                final String itemName = line['ItemDescription'] ?? 'N/A';
                final String sourceWarehouseCode =
                    docType == "order"
                        ? line['WarehouseCode'] ?? ''
                        : line['FromWarehouseCode'] ?? '';
                double onHand = (line['onHand'] as num?)?.toDouble() ?? 0.0;
                double inStock = (line['InStock'] as num?)?.toDouble() ?? 0.0;
                double committed =
                    (line['Committed'] as num?)?.toDouble() ?? 0.0;
                double orderedFromPO =
                    (line['Ordered'] as num?)?.toDouble() ?? 0.0;
                double availableQuantity = 0.0; // Ini akan dihitung di bawah

                // Hitung availableQuantity (dari InStock - Committed + OrderedFromPO)
                availableQuantity = inStock;
                inStock = onHand;
                if (availableQuantity < 0)
                  availableQuantity = 0.0; // Pastikan tidak negatif

                tempItems.add(
                  PickableItem(
                    docType: docType,
                    docEntry: docEntry,
                    docNum: docNum,
                    cardCode: cardCode,
                    cardName: cardName,
                    docLineNum: line['LineNum'] as int,
                    itemCode: itemCode,
                    itemName: itemName,
                    sourceWarehouseCode: sourceWarehouseCode,
                    orderedQuantity:
                        (line['Quantity'] as num?)?.toDouble() ?? 0.0,
                    openQuantity: openQty,
                    initialInStock: inStock,
                    initialCommitted: committed,
                    initialOrderedFromPO: orderedFromPO,
                    initialAvailableQuantity:
                        availableQuantity, // Gunakan hasil perhitungan
                  ),
                );
              }
            }
          }
        }
        pickableItems.addAll(tempItems);
        // Panggil ini setelah semua item baru ditambahkan
        _updateAllSimulatedAvailableQuantities();
        _page++;
        // Otomatis fetch jika data kurang dari 5 dan masih ada data
        if (tempItems.length <= 10 &&
            hasMoreData.value &&
            _autoFetchCount < _maxAutoFetch) {
          // if(_autoFetchCount == 0)
          // {
          _autoFetchCount++;
          await Future.delayed(const Duration(milliseconds: 300));
          await fetchPickableItems(
            reset: false,
            source: mSource,
            warehouse: mWarehouse,
          );
          //}
        }
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

  // Metode untuk memperbarui kuantitas tersedia yang disimulasikan
  void _updateAllSimulatedAvailableQuantities() {
    Map<String, double> currentPickedTotalByItemCode = {};

    // Hitung total kuantitas yang sudah di-pick untuk setiap ItemCode
    // dari item-item yang currently `isSelected`
    for (var item in pickableItems) {
      if (item.isSelected.value) {
        currentPickedTotalByItemCode.update(
          item.itemCode,
          (currentTotal) => currentTotal + item.pickedQuantity.value,
          ifAbsent: () => item.pickedQuantity.value,
        );
      }
    }

    // Perbarui simulatedAvailableQuantity untuk setiap item
    for (var item in pickableItems) {
      // Dapatkan total picked untuk itemCode ini (dari semua baris yang dipilih)
      double totalPickedForThisItemCode =
          currentPickedTotalByItemCode[item.itemCode] ?? 0.0;

      // Kuantitas tersedia yang disimulasikan adalah Kuantitas Tersedia Asli
      // dikurangi total yang sudah di-pick untuk itemCode tersebut.
      double newSimulatedQty =
          item.originalAvailableQuantity - totalPickedForThisItemCode;

      // Pastikan simulatedAvailableQuantity tidak negatif
      if (newSimulatedQty < 0) {
        newSimulatedQty = 0.0;
      }
      item.simulatedAvailableQuantity.value = newSimulatedQty;
    }
  }

  // Metode yang dipanggil ketika checkbox item di-toggle
  void toggleItemSelection(int index, bool? value) {
    if (index >= 0 && index < pickableItems.length) {
      final item = pickableItems[index];
      bool willBeSelected = value ?? false;

      // Jika user mencoba mencentang item
      if (willBeSelected) {
        // Coba atur pickedQuantity ke openQuantity atau originalAvailableQuantity (mana yang lebih kecil)
        double defaultPickQty = item.openQuantity;
        if (item.openQuantity > item.originalAvailableQuantity) {
          defaultPickQty = item.originalAvailableQuantity;
        }

        // Lakukan simulasi awal untuk melihat apakah item ini bisa di-pick secara default
        // jika simulatedAvailableQuantity - defaultPickQty < 0 maka stok tidak cukup
        // Ini adalah pengecekan stok yang lebih realistis saat mencentang
        double potentialNewSimulatedAvailable = item.originalAvailableQuantity;
        for (var existingItem in pickableItems) {
          // Kurangi stok dari item lain yang SUDAH dipilih (kecuali item yang sedang di-toggle)
          if (existingItem.isSelected.value &&
              existingItem.itemCode == item.itemCode &&
              existingItem != item) {
            potentialNewSimulatedAvailable -= existingItem.pickedQuantity.value;
          }
        }

        // Sekarang, kurangi dengan defaultPickQty dari item ini jika akan dipilih
        potentialNewSimulatedAvailable -= defaultPickQty;

        if (potentialNewSimulatedAvailable < 0) {
          Get.snackbar(
            "Warning",
            "Not enough stock to pick ${item.itemName} (${item.itemCode}). Only ${item.originalAvailableQuantity.toStringAsFixed(0)} available across all orders.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.BOTTOM,
          );
          // Jangan centang jika stok tidak cukup
          return;
        }

        item.isSelected.value = true;
        item.setPickedQuantity(defaultPickQty); // Set kuantitas awal
      } else {
        // Jika user menghilangkan centang
        item.isSelected.value = false;
        item.setPickedQuantity(
          0.0,
        ); // Reset pickedQuantity saat tidak dicentang
      }
      _updateAllSimulatedAvailableQuantities(); // Perbarui simulasi setelah toggle
    }
  }

  // Metode yang dipanggil ketika kuantitas di TextField diubah atau tombol +/- ditekan
  void updatePickedQuantity(int index, String value) {
    if (index >= 0 && index < pickableItems.length) {
      double? qty = double.tryParse(value);
      if (qty != null) {
        final item = pickableItems[index];

        // 1. Panggil metode setPickedQuantity di PickableItem
        // Ini akan memvalidasi non-negatif dan tidak melebihi openQuantity
        item.setPickedQuantity(qty);

        // 2. Perbarui simulasi stok global setelah perubahan pickedQuantity item ini
        _updateAllSimulatedAvailableQuantities();

        // 3. Validasi ulang terhadap simulatedAvailableQuantity yang BARU
        // Jika pickedQuantity item ini (setelah setPickedQuantity)
        // menyebabkan total picked untuk itemCode ini melebihi originalAvailableQuantity
        // maka sesuaikan kembali pickedQuantity item ini.
        double totalPickedForThisItemCodeIncludingCurrent = 0.0;
        for (var tempItem in pickableItems) {
          if (tempItem.itemCode == item.itemCode && tempItem.isSelected.value) {
            totalPickedForThisItemCodeIncludingCurrent +=
                tempItem.pickedQuantity.value;
          }
        }

        if (totalPickedForThisItemCodeIncludingCurrent >
            item.originalAvailableQuantity) {
          // Hitung berapa kelebihan pickedQuantity untuk item ini
          double excess =
              totalPickedForThisItemCodeIncludingCurrent -
              item.originalAvailableQuantity;
          // Kurangi pickedQuantity item ini sejumlah excess
          double adjustedPickedQty = item.pickedQuantity.value - excess;
          if (adjustedPickedQty < 0) adjustedPickedQty = 0.0;

          item.setPickedQuantity(
            adjustedPickedQty,
          ); // Set kuantitas yang disesuaikan
          _updateAllSimulatedAvailableQuantities(); // Recalculate lagi setelah penyesuaian

          Get.snackbar(
            "Warning",
            "Total picked quantity for ${item.itemName} cannot exceed available stock. Adjusted to ${adjustedPickedQty.toStringAsFixed(0)} for this item.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.BOTTOM,
          );
        }

        // Otomatis centang/un-centang berdasarkan pickedQuantity
        if (item.pickedQuantity.value > 0 && !item.isSelected.value) {
          // Panggil toggleItemSelection untuk menjalankan logika centang/validasi lainnya
          toggleItemSelection(index, true);
        } else if (item.pickedQuantity.value == 0 && item.isSelected.value) {
          // Panggil toggleItemSelection untuk menjalankan logika un-centang
          toggleItemSelection(index, false);
        }
      }
    }
  }

  Future<void> generatePickList({
    required DateTime pickDate,
    required String pickerName,
    String? note,
    String? warehouse,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    //(warehouse);
    try {
      final List<Map<String, dynamic>> pickListLines = [];
      for (var item in pickableItems) {
        if (item.isSelected.value && item.pickedQuantity.value > 0) {
          // Validasi akhir sebelum membuat payload Pick List
          // Pastikan pickedQuantity tidak melebihi open atau simulated available yang terakhir
          // Re-validate terhadap total simulatedAvailableQuantity + pickedQuantity itu sendiri
          // karena simulatedAvailableQuantity sudah mencerminkan pengurangan dari item lain.
          // Jadi, item.pickedQuantity.value tidak boleh melebihi item.openQuantity
          // DAN total pick untuk itemCode tidak boleh melebihi originalAvailableQuantity
          double totalPickedForThisItemCodeFinal = 0.0;
          for (var finalItem in pickableItems) {
            if (finalItem.itemCode == item.itemCode &&
                finalItem.isSelected.value) {
              totalPickedForThisItemCodeFinal += finalItem.pickedQuantity.value;
            }
          }

          if (item.pickedQuantity.value > item.openQuantity) {
            Get.snackbar(
              "Error",
              "Quantity pick for ${item.itemCode} cannot exceed the Qty Open (${item.openQuantity.toStringAsFixed(0)}).",
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            isLoading.value = false;
            return;
          }
          if (totalPickedForThisItemCodeFinal >
              item.originalAvailableQuantity) {
            Get.snackbar(
              "Error",
              "Total quantity picked for ${item.itemCode} (${totalPickedForThisItemCodeFinal.toStringAsFixed(0)}) exceeds the available stock (${item.originalAvailableQuantity.toStringAsFixed(0)}).",
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            isLoading.value = false;
            return;
          }

          int baseObjectType;
          if (item.docType == "order") {
            baseObjectType = 17; // Object Type Code for Sales Order
          } else if (item.docType == "transfer") {
            baseObjectType =
                1250000001; // Object Type Code for Inventory Transfer Request
          } else {
            continue; // Lewati jika tipe dokumen tidak dikenal
          }

          pickListLines.add({
            "OrderEntry": item.docEntry,
            "OrderRowID": item.docLineNum,
            "PickedQuantity":
                0, // Ini mungkin field yang salah. Harusnya ReleasedQuantity
            "ReleasedQuantity":
                item.pickedQuantity.value, // Gunakan pickedQuantity di sini
            "PreviouslyReleasedQuantity": 0,
            "BaseObjectType": baseObjectType,
          });
        }
      }

      if (pickListLines.isEmpty) {
        Get.snackbar(
          "Warning",
          "No data saved. Please select items and enter quantities.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      final Map<String, dynamic> newPickListPayload = {
        "PickDate": pickDate.toIso8601String(),
        "Name": pickerName,
        "Remarks": note,
        "PickListsLines": pickListLines,
      };
      print('Picker value : ${selectedPicker.value?['username']}');
      final createdPickList = await _sapB1Service.createPickList(
        newPickListPayload,
        itemcontroller.selectedWarehouseFilter.value,
      );
      if (createdPickList == '') {
        String platform = '';
        if (kIsWeb) {
          platform = 'web';
        } else {
          platform = 'mobile';
        }
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
        fetchPickableItems(
          reset: true,
        ); // Refresh list setelah Pick List berhasil dibuat
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
}
