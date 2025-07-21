// lib/controllers/goods_receipt_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../services/sap_service.dart';
import '../widgets/custom_dropdown_search.dart';

enum StockInMode { poBased, nonPo }

class StockInController extends GetxController {
  final SAPService _apiService = Get.find<SAPService>();

  var currentMode = StockInMode.poBased.obs;
  var isLoading = false.obs;
  var isNonPoExpanded = false.obs;

  // --- PO Based Goods Receipt ---
  final TextEditingController poNumberController = TextEditingController();
  final Rxn<Map<String, dynamic>> purchaseOrder = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> poItems = <Map<String, dynamic>>[].obs;

  // --- Non-PO Goods Receipt ---
  final RxList<Map<String, dynamic>> nonPoItems = <Map<String, dynamic>>[].obs;
  final TextEditingController nonPoItemCodeController = TextEditingController();
  final TextEditingController nonPoItemNameController = TextEditingController();
  final TextEditingController nonPoQuantityController = TextEditingController();
  final TextEditingController nonPoRemarksController = TextEditingController();

  final RxList<Map<String, dynamic>> vendorList = <Map<String, dynamic>>[].obs;
  final RxString selectedVendor = ''.obs;
  final box = GetStorage();
  @override
  void onInit() {
    super.onInit();
    fetchVendors();
  }

  @override
  void onClose() {
    poNumberController.dispose();
    nonPoItemCodeController.dispose();
    nonPoItemNameController.dispose();
    nonPoQuantityController.dispose();
    super.onClose();
  }

  void setMode(StockInMode mode) {
    currentMode.value = mode;
    //resetForm();
  }

  void resetForm() {
    isLoading.value = false;

    poNumberController.clear();
    purchaseOrder.value = null;
    poItems.clear();

    nonPoItems.clear();
    nonPoItemCodeController.clear();
    nonPoItemNameController.clear();
    nonPoQuantityController.clear();
  }

  Future<void> searchPo() async {
    if (poNumberController.text.isEmpty) {
      Get.snackbar(
        'Input Required',
        'Please enter a PO Number.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    purchaseOrder.value = null;
    poItems.clear();

    final poData = await _apiService.fetchPoDetails(poNumberController.text);
    isLoading.value = false;

    if (poData != null) {
      try {
        purchaseOrder.value = {
          "docEntry": poData["docEntry"],
          "docNum": poData["docNum"],
          "cardCode": poData["cardCode"],
          "cardName": poData["cardName"],
          "docDate": poData["docDate"],
          "docDueDate": poData["docDueDate"],
          "documentStatus": poData["documentStatus"],
        };
        if (purchaseOrder.value!["documentStatus"] != "O") {
           purchaseOrder.value = null;
          Get.snackbar(
            'Info',
            'PO ${poData["docNum"]} is not open.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orangeAccent.shade700,
            colorText: Colors.white,
          );
          return;
        }
        final lines = List<Map<String, dynamic>>.from(poData["lines"]);
        final openItems =
            lines
                .where(
                  (item) => (item["RemainingOpenInventoryQuantity"] ?? 0) > 0,
                )
                .toList();

        for (var item in openItems) {
          item["currentReceivedQuantity"] = 0.0;
        }

        poItems.assignAll(openItems);

        if (openItems.isEmpty) {
          Get.snackbar(
            'Info',
            'PO ${poData["docNum"]} has no open items.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orangeAccent.shade700,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to process PO data: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        purchaseOrder.value = null;
      }
    } 
    // else {
    //   Get.snackbar(
    //     'Not Found',
    //     'PO ${poNumberController.text} not found or error occurred.',
    //     snackPosition: SnackPosition.TOP,
    //     backgroundColor: Colors.red.shade700,
    //     colorText: Colors.white,
    //   );
    // }
  }

  void updatePoItemQuantity(int index, double quantity) {
    if (index >= 0 && index < poItems.length) {
      final item = poItems[index];
      if (quantity <= (item["RemainingOpenInventoryQuantity"] ?? 0)) {
        item["currentReceivedQuantity"] = quantity;
      } else {
        item["currentReceivedQuantity"] =
            item["RemainingOpenInventoryQuantity"];
        Get.snackbar(
          'Warning',
          'Quantity for ${item["ItemDescription"]} cannot exceed open quantity (${item["RemainingOpenInventoryQuantity"]}).',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
      }
      poItems[index] = item;
    }
  }

  void updateNonPoItemQuantity(int index, double quantity) {
    if (index >= 0 && index < nonPoItems.length) {
      final item = nonPoItems[index];
      final double openQty =
          item["RemainingOpenInventoryQuantity"] ?? double.infinity;
      if (quantity > openQty) {
        Get.snackbar(
          'Oops',
          'Quantity tidak boleh lebih dari open quantity ($openQty)',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
        quantity = openQty;
      }
      item["currentReceivedQuantity"] = quantity;
      nonPoItems[index] = item;
    }
  }

  void removeNonPoItem(int index) {
    if (index >= 0 && index < nonPoItems.length) {
      nonPoItems.removeAt(index);
    }
  }

  Future<void> submitPoGoodsReceipt(BuildContext context) async {
    if (purchaseOrder.value == null ||
        poItems.every((item) => item["currentReceivedQuantity"] <= 0)) {
      Get.snackbar(
        'Failed',
        'Please select a valid PO and ensure at least one item has a received quantity greater than 0.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }
     String warehouse_code = box.read('warehouse_code') ?? '';
    int bpl_id = box.read('bpl_id') ?? 0;
    final result = await showSubmitDialog(context);
    if (result == null) return;
    final payload = {
      "DocDate": result['DocDate'],
      "CardCode": purchaseOrder.value!["cardCode"],
      "CardName": purchaseOrder.value!["cardName"],
      "NumAtCard": result['NoRef'],
      "Comments":  result['Comments'] ?? '', 
      "BPL_IDAssignedToInvoice": bpl_id,
      "DocumentLines":
          poItems
              .where((item) => item["currentReceivedQuantity"] > 0)
              .map(
                (item) => {
                  "ItemCode": item["ItemCode"],
                  "Quantity": item["currentReceivedQuantity"].toInt(),
                   "WarehouseCode": warehouse_code,
                   "BaseType": 22,
					          "BaseEntry": purchaseOrder.value!["docEntry"],
                    "BaseLine": item["LineNum"],
                },
              )
              .toList(),
    };

    isLoading.value = true;
    final success = await _apiService.postGoodsReceiptPo(payload);
    isLoading.value = false;

    if (success) {
      Get.snackbar(
        'Success',
        'Data has been successfully submitted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
      resetForm();
    } 
    // else {
    //   Get.snackbar(
    //     'Failed',
    //     'failed to submit data. Please try again.',
    //     snackPosition: SnackPosition.TOP,
    //     backgroundColor: Colors.red.shade700,
    //     colorText: Colors.white,
    //   );
    // }
  }

  Future<Map<String, dynamic>?> showSubmitDialog(BuildContext context) async {
  TextEditingController dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  TextEditingController remarksController = TextEditingController(); // Controller untuk Remarks
  TextEditingController norefController = TextEditingController();
  RxString selectedVendor = ''.obs;

  return await Get.dialog<Map<String, dynamic>>(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 28,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Receipt Confirmation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.blueGrey),
              const SizedBox(height: 20),

              // Document Date
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Receipt Date', 
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),

              const SizedBox(height: 16),

              // No Reference
              TextField(
                controller: norefController,
                decoration: const InputDecoration(
                  labelText: 'No Reference', 
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Remarks
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks', 
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.blueGrey),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (dateController.text.isEmpty) {
                        Get.snackbar(
                          'Validation',
                          'Document Date is required.',
                          backgroundColor: Colors.red.shade600,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      Get.back(
                        result: {
                          'DocDate': dateController.text,
                          'CardCode': selectedVendor,
                          'NoRef': norefController.text,
                          'Comments': remarksController.text,
                        },
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Future<void> fetchVendors() async {
    final result = await _apiService.getVendors();
    if (result != null) {
      vendorList.assignAll(List<Map<String, dynamic>>.from(result));
    } else {
      Get.snackbar(
        'Error',
        'Failed to get data vendor.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getItem(String keyword) async {
    final result = await _apiService.getItemHeader(keyword);
    if (result != null && result is List) {
      return List<Map<String, dynamic>>.from(result);
    } else {
      Get.snackbar(
        'Error',
        'Failed to get data item.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return [];
    }
  }

  Future<void> submitNonPoGoodsReceipt(BuildContext context) async {
    if (nonPoItems.isEmpty) {
      Get.snackbar(
        'No Items',
        'Please add at least one item before submitting.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }
    String warehouse_code = box.read('warehouse_code') ?? '';
    int bpl_id = box.read('bpl_id') ?? 0;
    final result = await showSubmitDialog(context);
    if (result == null) return;

    final payload = {
      "DocDate": result['DocDate'],
      "NumAtCard": result['NoRef'],
      "BPL_IDAssignedToInvoice": bpl_id,
      "Comments": result['Comments'],
      "DocumentLines":
          nonPoItems
              .map(
                (e) => {
                  "ItemCode": e["ItemCode"],
                  "Quantity": e["currentReceivedQuantity"].toInt(),
                  "WarehouseCode": warehouse_code,
                },
              )
              .toList(),
    };

    isLoading.value = true;
    final success = await _apiService.postGoodsReceiptNonPo(payload);
    isLoading.value = false;

    if (success) {
      Get.snackbar(
        'Success',
        'Data has been successfully submitted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
      resetForm();
    } else {
      Get.snackbar(
        'Failed',
        'Submission failed. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  void addNonPoItem() {
    final code = nonPoItemCodeController.text.trim();
    final name = nonPoItemNameController.text.trim();
    final qty = double.tryParse(nonPoQuantityController.text.trim()) ?? 0.0;

    if (code.isEmpty || name.isEmpty || qty <= 0) {
      Get.snackbar(
        'Invalid Input',
        'Please enter valid item code, name, and quantity.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final existingIndex = nonPoItems.indexWhere(
      (item) => item["ItemCode"] == code,
    );
    if (existingIndex != -1) {
      nonPoItems[existingIndex]["currentReceivedQuantity"] += qty;
      nonPoItems[existingIndex] = nonPoItems[existingIndex];
    } else {
      nonPoItems.add({
        "ItemCode": code,
        "ItemName": name,
        "currentReceivedQuantity": qty,
      });
    }

    nonPoItemCodeController.clear();
    nonPoItemNameController.clear();
    nonPoQuantityController.clear();
  }

  void handleScanResult(String scannedValue) async {
    FocusScope.of(Get.context!).unfocus();
    bool isNumeric(String s) => double.tryParse(s) != null;

    if (currentMode.value == StockInMode.poBased) {
      final itemIndex = poItems.indexWhere(
        (item) => item["ItemCode"] == scannedValue,
      );
      if (itemIndex != -1) {
        final item = poItems[itemIndex];
        final openQty = item["RemainingOpenInventoryQuantity"] ?? 0;
        final currentQty = item["currentReceivedQuantity"] ?? 0;

        if (currentQty < openQty) {
          updatePoItemQuantity(itemIndex, currentQty + 1);
        } else {
          Get.snackbar(
            'Max Quantity',
            'Qty untuk "${item["ItemDescription"]}" sudah mencapai limit open ($openQty).',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white,
          );
        }
        return;
      }

      if (purchaseOrder.value == null && isNumeric(scannedValue)) {
        poNumberController.text = scannedValue;
        searchPo();
        Get.snackbar(
          'PO Candidate',
          'Trying to search PO: $scannedValue',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue.shade600,
          colorText: Colors.white,
        );
        return;
      }

      Get.snackbar(
        'Not Matched',
        'Item Code "$scannedValue" tidak terdaftar pada PO Number.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } else {
      final itemIndex = nonPoItems.indexWhere(
        (item) => item["ItemCode"] == scannedValue,
      );
      if (itemIndex != -1) {
        nonPoItems[itemIndex]["currentReceivedQuantity"] += 1;
        nonPoItems[itemIndex] = nonPoItems[itemIndex];
      } else {
        final itemName = await _apiService.getItemName(scannedValue);
        if (itemName != "") {
          nonPoItems.add({
            "ItemCode": scannedValue,
            "ItemName": itemName,
            "currentReceivedQuantity": 1.0,
          });
        } else {
          Get.snackbar(
            'Item Not Found',
            'Scanned item code "$scannedValue" not found in the system.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade400,
            colorText: Colors.white,
          );
        }
      }
    }
  }
}
