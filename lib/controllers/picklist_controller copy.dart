// lib/controllers/picklist_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import mobile_scanner

class PicklistController extends GetxController {
  final RxList<dynamic> _allPicklists = <dynamic>[].obs;
  final RxList<dynamic> displayedPicklists = <dynamic>[].obs;
  final RxString selectedStatusFilter = 'R'.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Untuk menyimpan referensi ke picklist yang sedang di-scan (jika kita masuk ke detail)
  Rx<Map<String, dynamic>?> currentScanningPicklist = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchPickList();
    ever(_allPicklists, (_) => _filterPicklists());
    ever(selectedStatusFilter, (_) => _filterPicklists());
  }

  // Metode untuk mensimulasikan panggilan API fetchPickList
  Future<void> fetchPickList() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Simulasi delay API call
      await Future.delayed(const Duration(seconds: 2));

      // Contoh response API dari Anda (pakai dynamic/Map<String, dynamic>)
      final List<Map<String, dynamic>> responseData = [
        {
          "AbsoluteEntry": 21,
          "Name": "Pick 21",
          "OwnerCode": 1,
          "Remarks": "Test Picklist with notif",
          "Status": "R", // Released
          "PickListsLines": [
            {
              "LineNumber": 0,
              "OrderEntry": 6536,
              "ItemCode": "10001",
              "ItemName": "Item A (from SO 6536)",
              "Bin_Loc": "F12B",
              "Stock_On_Hand": "2",
              "PickedQuantity": 0.0,
              "ReleasedQuantity": 1.0,
              "PreviouslyReleasedQuantity": 1.0,
              "BaseObjectType": 17 // Sales Order
            },
            {
              "LineNumber": 1,
              "OrderEntry": 6537,
              "ItemCode": "10002",
              "ItemName": "Item B (from SO 6537)",
              "Bin_Loc": "G05A",
              "Stock_On_Hand": "5",
              "PickedQuantity": 0.0,
              "ReleasedQuantity": 2.0,
              "PreviouslyReleasedQuantity": 2.0,
              "BaseObjectType": 17
            }
          ]
        },
        {
          "AbsoluteEntry": 22,
          "Name": "Pick 22",
          "OwnerCode": 2,
          "Remarks": "For Inventory Transfer",
          "Status": "R", // Released
          "PickListsLines": [
            {
              "LineNumber": 0,
              "OrderEntry": 1001, // ITR DocEntry
              "ItemCode": "20001",
              "ItemName": "Item C (for ITR 1001)",
              "Bin_Loc": "H10C",
              "Stock_On_Hand": "10",
              "PickedQuantity": 0.0,
              "ReleasedQuantity": 3.0,
              "PreviouslyReleasedQuantity": 3.0,
              "BaseObjectType": 67 // Inventory Transfer Request
            }
          ]
        },
        {
          "AbsoluteEntry": 20,
          "Name": "Pick 20",
          "OwnerCode": 1,
          "Remarks": "Completed pick",
          "Status": "C", // Closed
          "PickListsLines": [
            {
              "LineNumber": 0,
              "OrderEntry": 6530,
              "ItemCode": "10005",
              "ItemName": "Item X",
              "Bin_Loc": "A01B",
              "Stock_On_Hand": "5",
              "PickedQuantity": 5.0, // Sudah di-pick 5.0
              "ReleasedQuantity": 5.0,
              "PreviouslyReleasedQuantity": 5.0,
              "BaseObjectType": 17
            }
          ]
        },
      ];

      // Update _allPicklists dengan data yang diterima
      _allPicklists.value = responseData;
      // Filter untuk pertama kali
      _filterPicklists();
    } catch (e) {
      errorMessage.value = 'Failed to fetch picklists: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Metode untuk memfilter picklist berdasarkan status
  void _filterPicklists() {
    if (selectedStatusFilter.value == 'All') {
      displayedPicklists.value = _allPicklists;
    } else {
      displayedPicklists.value = _allPicklists
          .where((pl) => pl['Status'] == selectedStatusFilter.value)
          .toList();
    }
  }

  // Metode untuk mengubah filter status
  void changeStatusFilter(String status) {
    selectedStatusFilter.value = status;
  }

  // Metode untuk mengupdate 'PickedQuantity' di tingkat line item (lokal)
  // Ini penting agar UI dapat merefleksikan perubahan yang dilakukan picker
  void updatePickedQuantity(int picklistIndex, int lineIndex, double newQty) {
    // Perbaikan di sini: Gunakan operator perbandingan standar
    if (picklistIndex >= 0 && picklistIndex < displayedPicklists.length &&
        lineIndex >= 0 && lineIndex < displayedPicklists[picklistIndex]['PickListsLines'].length) {

      final picklistToUpdate = displayedPicklists[picklistIndex];
      final lineToUpdate = picklistToUpdate['PickListsLines'][lineIndex];

      final double releasedQty = lineToUpdate['ReleasedQuantity']?.toDouble() ?? 0.0;
      final double stockOnHand = double.tryParse(lineToUpdate['Stock_On_Hand']?.toString() ?? '0.0') ?? 0.0;

      double finalQty = newQty;

      // Validasi: Picked quantity tidak boleh negatif
      if (finalQty < 0) {
        finalQty = 0.0;
        Get.snackbar('Warning', 'Picked quantity cannot be negative.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      }
      
      // Validasi: Picked quantity tidak melebihi released quantity
      if (finalQty > releasedQty) {
        finalQty = releasedQty;
        Get.snackbar('Warning', 'Picked quantity cannot exceed released quantity.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      }
      // Validasi tambahan jika ingin membatasi berdasarkan stok
      if (finalQty > stockOnHand) { 
         finalQty = stockOnHand;
         Get.snackbar('Warning', 'Picked quantity cannot exceed stock on hand.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      }


      lineToUpdate['PickedQuantity'] = finalQty;
      // Memaksa update UI GetX untuk nested object
      displayedPicklists.refresh();
    }
  }
 // Metode yang dipanggil ketika barcode berhasil di-scan
  void onBarcodeScanned(BarcodeCapture barcodeCapture) {
    // Pastikan ada barcode dan data tidak kosong
    if (barcodeCapture.barcodes.isNotEmpty) {
      final String? scannedCode = barcodeCapture.barcodes.first.rawValue;
      if (scannedCode != null && scannedCode.isNotEmpty) {
        processScannedItem(scannedCode);
      } else {
        Get.snackbar('Scan Error', 'No readable barcode found.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    }
  }

  // Logika untuk memproses item yang di-scan
  void processScannedItem(String scannedItemCode) {
    // 1. Temukan picklist yang sedang aktif (jika ada, misal dari halaman detail)
    //    ATAU, cari di semua picklist 'Released' yang ditampilkan
    if (currentScanningPicklist.value != null) {
      _processScannedItemInSpecificPicklist(currentScanningPicklist.value!, scannedItemCode);
    } else {
      _processScannedItemAcrossDisplayedPicklists(scannedItemCode);
    }
  }

  void _processScannedItemInSpecificPicklist(Map<String, dynamic> picklist, String scannedItemCode) {
    final List<dynamic> lines = picklist['PickListsLines'];
    bool itemFound = false;

    for (int i = 0; i < lines.length; i++) {
      final Map<String, dynamic> line = lines[i];
      if (line['ItemCode'] == scannedItemCode) {
        // Cek apakah kuantitas yang perlu di-pick masih ada
        final double releasedQty = line['ReleasedQuantity']?.toDouble() ?? 0.0;
        final double currentPickedQty = line['PickedQuantity']?.toDouble() ?? 0.0;
        final double stockOnHand = double.tryParse(line['Stock_On_Hand']?.toString() ?? '0.0') ?? 0.0;

        if (currentPickedQty < releasedQty && currentPickedQty < stockOnHand) {
          line['PickedQuantity'] = currentPickedQty + 1.0; // Tambahkan 1 untuk setiap scan
          Get.snackbar('Success', 'Item ${line['ItemName']} (${line['ItemCode']}) picked! Current: ${line['PickedQuantity'].toStringAsFixed(0)}',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
          itemFound = true;
          // Memaksa UI untuk refresh, karena perubahan terjadi di nested map
          displayedPicklists.refresh();
          // Jika Anda hanya ingin scan satu item per baris per scan, bisa break di sini
          break;
        } else {
          Get.snackbar('Warning', 'Item ${line['ItemName']} (${line['ItemCode']}) already fully picked or out of stock.',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
          itemFound = true;
          break; // Item ditemukan tapi sudah full
        }
      }
    }

    if (!itemFound) {
      Get.snackbar('Error', 'Scanned item ($scannedItemCode) not found in this picklist.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void _processScannedItemAcrossDisplayedPicklists(String scannedItemCode) {
      bool itemFound = false;
      for (int i = 0; i < displayedPicklists.length; i++) {
        final Map<String, dynamic> picklist = displayedPicklists[i];
        if (picklist['Status'] == 'R') { // Hanya proses picklist yang Released
          final List<dynamic> lines = picklist['PickListsLines'];
          for (int j = 0; j < lines.length; j++) {
            final Map<String, dynamic> line = lines[j];
            if (line['ItemCode'] == scannedItemCode) {
              final double releasedQty = line['ReleasedQuantity']?.toDouble() ?? 0.0;
              final double currentPickedQty = line['PickedQuantity']?.toDouble() ?? 0.0;
              final double stockOnHand = double.tryParse(line['Stock_On_Hand']?.toString() ?? '0.0') ?? 0.0;

              if (currentPickedQty < releasedQty && currentPickedQty < stockOnHand) {
                line['PickedQuantity'] = currentPickedQty + 1.0;
                Get.snackbar('Success', 'Item ${line['ItemName']} (${line['ItemCode']}) picked from ${picklist['Name']}! Current: ${line['PickedQuantity'].toStringAsFixed(0)}',
                    snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                itemFound = true;
                displayedPicklists.refresh();
                return; // Berhenti setelah menemukan dan mengupdate item pertama
              }
            }
          }
        }
      }

      if (!itemFound) {
        Get.snackbar('Error', 'Scanned item ($scannedItemCode) not found in any open picklist.',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
  }
  // Metode untuk "menyelesaikan" picking untuk satu picklist
  // Ini akan memanggil API untuk mengirim data update ke SAP B1
  Future<void> completePicklist(Map<String, dynamic> picklist) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Contoh data yang akan dikirim ke API Anda
      // Sesuaikan dengan format API update picklist Anda
      final Map<String, dynamic> dataToUpdate = {
        "AbsoluteEntry": picklist["AbsoluteEntry"],
        "Status": "C", // Mengubah status menjadi Closed
        "PickListsLines": picklist["PickListsLines"].map((line) => {
          "LineNumber": line["LineNumber"],
          "OrderEntry": line["OrderEntry"],
          "ItemCode": line["ItemCode"],
          "PickedQuantity": line["PickedQuantity"],
          // Sertakan field lain yang relevan untuk update di API Anda
        }).toList(),
      };

      // TODO: Panggil API Anda untuk mengupdate PickList di SAP B1
      // Contoh: final response = await _yourApiService.updatePicklist(dataToUpdate);
      await Future.delayed(const Duration(seconds: 1)); // Simulasi API call

      // Setelah berhasil update di API, refresh daftar picklist
      Get.snackbar('Success', 'Picklist ${picklist['Name']} updated successfully!',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchPickList(); // Ambil ulang data untuk merefleksikan perubahan status
    } catch (e) {
      errorMessage.value = 'Failed to update picklist: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}