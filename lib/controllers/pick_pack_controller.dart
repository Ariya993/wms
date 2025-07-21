import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // Import ini dibutuhkan untuk Get.snackbar
import 'package:get_storage/get_storage.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart'; // Pastikan path ini benar sesuai struktur proyek Anda

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

  // Method untuk update kuantitas pickedQuantity, dengan validasi
  void updatePickedQuantity(double value) {
    if (value < 0) value = 0; // Kuantitas tidak bisa negatif

    double tempValue = value;
    double maxAllowed = openQuantity;
    if (simulatedAvailableQuantity.value < maxAllowed) {
      maxAllowed = simulatedAvailableQuantity.value;
    }

    if (value > maxAllowed) {
      pickedQuantity.value = maxAllowed;
      Get.snackbar(
        "Warning",
        "Quantity pick tidak boleh melebihi Qty Open (${openQuantity.toStringAsFixed(0)}) atau Qty Available (${simulatedAvailableQuantity.value.toStringAsFixed(0)}).",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      pickedQuantity.value = value;
    }
  }
}

class PickPackController extends GetxController {
  final SAPService _sapB1Service = Get.find<SAPService>();
  final ApiService _apiService = Get.find<ApiService>();
  RxList<PickableItem> pickableItems = <PickableItem>[].obs;
  RxBool isLoading = true.obs;
  RxString errorMessage = ''.obs;
  var searchQuery = ''.obs;
  var filterType = 'ALL'.obs;
  int _page = 0;
  int _pageSize = 1;
  int _maxAutoFetch = 3;
int _autoFetchCount = 0;
  RxBool hasMoreData = true.obs;
  RxBool isFetchingMore = false.obs;
  String? currentSource;
  Rx<DateTime> pickDate = DateTime.now().obs;
  RxString pickerName = ''.obs;
  RxString pickerValue = ''.obs;
  RxString note = ''.obs;
  Rx<Map<String, dynamic>?> selectedPicker = Rx<Map<String, dynamic>?>(null);
  RxList<Map<String, dynamic>> Picker = <Map<String, dynamic>>[].obs;
  final box = GetStorage();
  @override
  void onInit() {
    super.onInit();
    //   debounce(searchQuery, (String keyword) {
    //   fetchPickableItems(reset: true);
    // }, time: const Duration(milliseconds: 500));
    debounce<String>(
      searchQuery,
      (_) => update(), // atau panggil fungsi filter jika perlu
      time: const Duration(milliseconds: 300),
    );
    fetchDropdownData();
    fetchPickableItems(reset: true);
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
  Future<void> fetchPickableItems({bool reset = false, String? source}) async {
    if (reset) {
      _page = 0;
      _pageSize = 1;
      _autoFetchCount=0;
      hasMoreData.value = true;
      pickableItems.clear();
      currentSource = source;
    } else {
      if (!hasMoreData.value || isFetchingMore.value) return;
      isFetchingMore.value = true;
    }

    if (reset) isLoading.value = true;
    errorMessage.value = '';

    try {
      final List<Map<String, dynamic>> pickpack = await _sapB1Service
          .getPickPack(
            _page * 20,
            source ?? currentSource ?? '',
            searchQuery.value,
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

                double inStock = (line['InStock'] as num?)?.toDouble() ?? 0.0;
                double committed =
                    (line['Committed'] as num?)?.toDouble() ?? 0.0;
                double orderedFromPO =
                    (line['Ordered'] as num?)?.toDouble() ?? 0.0;
                double availableQuantity = 0.0;
                // (line['AvailableQuantity'] as num?)?.toDouble() ?? 10.0;

                if (availableQuantity == 0.0 && inStock != 0.0) {
                  availableQuantity = inStock - committed + orderedFromPO;
                }

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
                    initialAvailableQuantity: availableQuantity,
                  ),
                );
              }
            }
          }
        }
        pickableItems.addAll(tempItems);
        _updateAllSimulatedAvailableQuantities();
        _page++;
        if (tempItems.length < 5 &&
            hasMoreData.value &&
            _autoFetchCount <= _maxAutoFetch) {
          _autoFetchCount++;
          await fetchPickableItems();
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

  // --- Metode baru untuk memperbarui kuantitas tersedia yang disimulasikan ---
  void _updateAllSimulatedAvailableQuantities() {
    // Peta untuk menyimpan total kuantitas picked untuk setiap ItemCode
    Map<String, double> currentPickedTotalByItemCode = {};

    // Hitung total pickedQuantity untuk setiap ItemCode dari item yang *saat ini* dipilih
    for (var item in pickableItems) {
      if (item.isSelected.value) {
        // Hanya yang dicentang yang berkontribusi pada pengurangan simulasi
        currentPickedTotalByItemCode.update(
          item.itemCode,
          (currentTotal) => currentTotal + item.pickedQuantity.value,
          ifAbsent: () => item.pickedQuantity.value,
        );
      }
    }

    // Perbarui simulatedAvailableQuantity untuk setiap item
    for (var item in pickableItems) {
      double totalPickedForThisItemCode =
          currentPickedTotalByItemCode[item.itemCode] ?? 0.0;

      // Kuantitas tersedia yang disimulasikan = Kuantitas Tersedia Asli - total pick yang sedang berlangsung
      double newSimulatedQty =
          item.originalAvailableQuantity - totalPickedForThisItemCode;

      // Pastikan simulatedAvailableQuantity tidak negatif
      if (newSimulatedQty < 0) {
        newSimulatedQty = 0.0;
      }
      item.simulatedAvailableQuantity.value = newSimulatedQty;
    }
 
  }

  @override
  void toggleItemSelection(int index, bool? value) {
    if (index >= 0 && index < pickableItems.length) {
      final item = pickableItems[index];

      // JANGAN IZINKAN CENTANG JIKA STOK TIDAK CUKUP UNTUK OPEN QUANTITY
      if (value == true) {
        // Jika user mencoba mencentang
        if (item.openQuantity > item.simulatedAvailableQuantity.value ||
            item.simulatedAvailableQuantity.value < 0) {
          Get.snackbar(
            "warning",
            "Quantity Open (${item.openQuantity.toStringAsFixed(0)}) cannot exceed the qty available (${item.simulatedAvailableQuantity.toStringAsFixed(0)}) for ${item.itemName}.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          // Jangan ubah isSelected, biarkan tetap false
          return; // Hentikan fungsi
        }
      }

      // Lanjutkan jika kondisi terpenuhi atau jika sedang tidak dicentang
      item.isSelected.value = value ?? false;

      if (!item.isSelected.value) {
        item.pickedQuantity.value =
            0.0; // Reset pickedQuantity saat tidak dicentang
      } else {
        // Atur pickedQuantity default saat dicentang, tapi perhatikan openQuantity
        double defaultPickQty =
            item.openQuantity; // Ambil dari openQuantity dulu

        // PENTING: Sesuaikan default pick jika melebihi simulatedAvailableQuantity
        if (item.openQuantity == item.simulatedAvailableQuantity.value) {
          defaultPickQty = item.openQuantity;
        } else if (defaultPickQty > item.simulatedAvailableQuantity.value) {
          defaultPickQty = item.simulatedAvailableQuantity.value;

          Get.snackbar(
            "Info",
            "Quantity pick  ${item.itemName} to be set ${defaultPickQty.toStringAsFixed(0)}.",
            backgroundColor: Colors.blueGrey,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
        item.pickedQuantity.value =
            defaultPickQty; // <--- BARIS INI YANG MENGATUR KUANTITASNYA
        // Tambahkan print ini untuk debugging:
        print(
          " [Debug] ${item.itemCode}: Picked quantity set to ${item.pickedQuantity.value} after checking.",
        );
      }
      print(selectedPicker.value);
      _updateAllSimulatedAvailableQuantities();
    }
  } 
  @override
  void updatePickedQuantity(int index, String value) {
    if (index >= 0 && index < pickableItems.length) {
      double? qty = double.tryParse(value);
      if (qty != null) {
        final item = pickableItems[index];
        item.updatePickedQuantity(qty); // Panggil metode update di PickableItem

        // Otomatis centang jika kuantitas > 0 dan belum dicentang
        if (item.pickedQuantity.value > 0 && !item.isSelected.value) {
          item.isSelected.value = true;
        }
        // Jika kuantitas kembali 0, tidak dicentang
        if (item.pickedQuantity.value == 0 && item.isSelected.value) {
          item.isSelected.value = false;
        }
        // Panggil ini setelah perubahan pickedQuantity
        _updateAllSimulatedAvailableQuantities();
      }
    }
  }

  Future<void> generatePickList({
    required DateTime pickDate,
    required String pickerName,
    String? note,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    //  print(selectedPicker.value?['username'] );
    //  return;
    try {
      final List<Map<String, dynamic>> pickListLines = [];
      for (var item in pickableItems) {
        if (item.isSelected.value && item.pickedQuantity.value > 0) {
          // Validasi akhir sebelum membuat payload Pick List
          // Pastikan pickedQuantity tidak melebihi open atau simulated available yang terakhir
          if (item.pickedQuantity.value > item.openQuantity ||
              item.pickedQuantity.value >
                  item.simulatedAvailableQuantity.value+item.pickedQuantity.value) {
            Get.snackbar(
              "Error",
              "Quantity pick ${item.itemCode} cannot exceed the qty open or available (${item.simulatedAvailableQuantity.toStringAsFixed(0)}).",
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            isLoading.value = false;
            return; // Hentikan proses jika ada item yang tidak valid
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
            "PickedQuantity": 0,
            "ReleasedQuantity": item.pickedQuantity.value,
            "PreviouslyReleasedQuantity": 0,
            "BaseObjectType": baseObjectType,
          });
        }
      }

      if (pickListLines.isEmpty) {
        Get.snackbar(
          "Warning",
          "No data saved",
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

      final createdPickList = await _sapB1Service.createPickList(
        newPickListPayload,
      ); 
      if (createdPickList == '') {
        String plaform='';
        if (kIsWeb)
        {
            plaform='web';
        }
        else
        {
            plaform='mobile';
        }
        await _apiService.SendFCM(selectedPicker.value?['username'],plaform,'WMS Apps','New Pick List','/wms/#/home' );
        Get.snackbar(
          "Success",
          "Generated Picklist Successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
         fetchPickableItems(reset: true); // Refresh list setelah Pick List berhasil dibuat
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
