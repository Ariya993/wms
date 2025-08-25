// lib/controllers/goods_receipt_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:wms/controllers/item_controller.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart';
import '../widgets/custom_dropdown_search.dart';

// enum AdjutsmentStockMode { poBased, adjust,grgi }
enum AdjutsmentStockMode { adjOut,adjIn }

class AdjutsmentStockController extends GetxController {
  final SAPService _apiService = Get.find<SAPService>();
  final ApiService _apiServices = Get.find<ApiService>();
  final ItemController itemcontroller = Get.find<ItemController>();
  var currentMode = AdjutsmentStockMode.adjOut.obs;
  var isLoading = false.obs;
  var isadjustExpanded = false.obs;

 
  // --- Non-PO Goods Receipt ---
  final RxList<Map<String, dynamic>> adjustItems = <Map<String, dynamic>>[].obs;
  final TextEditingController adjustItemCodeController = TextEditingController();
  final TextEditingController adjustItemNameController = TextEditingController();
  final TextEditingController adjustQuantityController = TextEditingController();
  final TextEditingController adjustRemarksController = TextEditingController();

   Rx<Map<String, dynamic>?> selectedBP = Rx<Map<String, dynamic>?>(null);
  final RxList<Map<String, dynamic>> vendorList = <Map<String, dynamic>>[].obs;
  final RxString selectedVendor = ''.obs;

  Rx<Map<String, dynamic>?> selectedWarehouse = Rx<Map<String, dynamic>?>(null); 
  RxList<Map<String, dynamic>> warehouses = <Map<String, dynamic>>[].obs;
  
  Rx<Map<String, dynamic>?> selectedIssue = Rx<Map<String, dynamic>?>(null); 
  RxList<Map<String, dynamic>> issueType = <Map<String, dynamic>>[].obs;

  RxList<Map<String, dynamic>> wmsUsers = <Map<String, dynamic>>[].obs;
List<TextEditingController> poItemQtyControllers = [];


  final box = GetStorage();
  @override
  void onInit() {
    super.onInit();
    fetchBussinesPartner();
    fetchDropdownData();
  
  }

  @override
  void onClose() {
   
    adjustItemCodeController.dispose();
    adjustItemNameController.dispose();
    adjustQuantityController.dispose();
    super.onClose();
  }

  void setMode(AdjutsmentStockMode mode) {
    currentMode.value = mode;
    //resetForm();
  }

  void resetForm() {
    isLoading.value = false;
 
    adjustItems.clear();
    adjustItemCodeController.clear();
    adjustItemNameController.clear();
    adjustQuantityController.clear();
  }

  Future<void> fetchDropdownData() async {
    isLoading.value = true;
    try {
      final fetchedWarehouses = await _apiServices.getWarehouses();
      final fetchedWMSUsers = await _apiServices.getWMSUsers();
      final fetchedIssueType = await _apiServices.getIssueType();
      warehouses.assignAll(fetchedWarehouses);
      wmsUsers.assignAll(fetchedWMSUsers);
      issueType.assignAll(fetchedIssueType);

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
 
  void updateadjustItemQuantity(int index, double quantity) {
    if (index >= 0 && index < adjustItems.length) {
      final item = adjustItems[index];
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
      adjustItems[index] = item;
      adjustItems.refresh();
    }
  }

  void removeadjustItem(int index) {
    if (index >= 0 && index < adjustItems.length) {
      adjustItems.removeAt(index);
    }
  }
 
  Future<Map<String, dynamic>?> showSubmitDialog(BuildContext context) async {
    TextEditingController dateController = TextEditingController(
      text: DateFormat('dd-MMM-yyyy').format(DateTime.now()),
    );
    TextEditingController remarksController =
        TextEditingController(); // Controller untuk Remarks
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
            padding: const EdgeInsets.all(16.0),
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
                        'Adjustment Confirmation',
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
                CustomDropdownSearch<Map<String, dynamic>>(
                  labelText: "Warehouse",
                  selectedItem: selectedWarehouse.value,
                  asyncItems: (String? filter) async {
                    if (filter == null || filter.isEmpty) {
                      return warehouses.toList();
                    }
                    return warehouses
                        .where(
                          (wh) =>
                              (wh['warehouseCode'] as String)
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()) ||
                              (wh['warehouseName'] as String)
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()),
                        )
                        .toList();
                  },
                  onChanged: (warehouse) {
                    selectedWarehouse.value = warehouse;
                  },
                  itemAsString:
                      (Map<String, dynamic> wh) =>
                          '${wh['warehouseCode']} - ${wh['warehouseName']}',
                  compareFn:
                      (item1, item2) =>
                          item1['warehouseCode'] == item2['warehouseCode'],
                ),
                const SizedBox(height: 16),
                CustomDropdownSearch<Map<String, dynamic>>(
                  labelText: "Supplier or Customer",
                  selectedItem:selectedBP.value,
                  asyncItems: (String? filter) async {
                      // setiap kali search dipanggil, call API
                      final result = await _apiService.getBussinesPartner(keyword: filter);
                      if (result != null) {
                        return List<Map<String, dynamic>>.from(result);
                      }
                      return [];
                    },
                  // asyncItems: (String? filter) async {
                  //   if (filter == null || filter.isEmpty) {
                  //     return vendorList.toList();
                  //   }
                  //   return vendorList
                  //       .where(
                  //         (wh) =>
                  //             (wh['CardCode'] as String)
                  //                 .toLowerCase()
                  //                 .contains(filter.toLowerCase()) ||
                  //             (wh['CardName'] as String)
                  //                 .toLowerCase()
                  //                 .contains(filter.toLowerCase()),
                  //       )
                  //       .toList();
                  // },
                  onChanged: (vendorList) {
                    selectedBP.value = vendorList;
                  },
                  itemAsString:
                      (Map<String, dynamic> wh) =>
                          '${wh['CardCode']} - ${wh['CardName']}',
                  compareFn:
                      (item1, item2) =>
                          item1['CardCode'] == item2['CardCode'],
                ),
                const SizedBox(height: 16),
                CustomDropdownSearch<Map<String, dynamic>>(
                  labelText: "Reason Type",
                  selectedItem: selectedIssue.value,
                  asyncItems: (String? filter) async {
                    if (filter == null || filter.isEmpty) {
                      return issueType.toList();
                    }
                    return issueType
                        .where(
                          (wh) =>
                              (wh['id_issue'] as String)
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()) ||
                              (wh['issue_name'] as String)
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()),
                        )
                        .toList();
                  },
                  onChanged: (issueType) {
                    selectedIssue.value = issueType;
                  },
                  itemAsString:
                      (Map<String, dynamic> wh) =>
                          '${wh['issue_name']}',
                  compareFn:
                      (item1, item2) =>
                          item1['id_issue'] == item2['id_issue'],
                ),
                const SizedBox(height: 16),
                // Document Date
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Proses Date',
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
                      dateController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(picked);
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
                          debugPrint(selectedBP.value?["CardCode"]??'');
                           debugPrint(selectedBP.value?["CardName"]??'');
                        Get.back(
                          result: {
                            'DocDate': dateController.text,
                            'CardCode': selectedBP.value?["CardCode"]??'', 
                            'CardName': selectedBP.value?["CardName"]??'', 
                            'IssueType': selectedIssue.value?["id_issue"]??'6', 
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
        backgroundColor: const Color.fromARGB(255, 50, 24, 24),
        colorText: Colors.white,
      );
    }
  }

  Future<void> fetchBussinesPartner() async {
    final result = await _apiService.getBussinesPartner();
    if (result != null) {
      vendorList.assignAll(List<Map<String, dynamic>>.from(result));
    } else {
      Get.snackbar(
        'Error',
        'Failed to get data vendor.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color.fromARGB(255, 50, 24, 24),
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

  Future<void> submitadjustGoodsReceipt(BuildContext context) async {
    if (adjustItems.isEmpty) {
      Get.snackbar(
        'No Items',
        'Please add at least one item before submitting.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }
   
    final result = await showSubmitDialog(context);
    if (result == null) return;
     String warehouse_code =  selectedWarehouse.value?["warehouseCode"] ?? box.read('warehouse_code');
    final warehouse = {'warehouse_code': warehouse_code};

    final data = await _apiServices.getWarehouseAuth(warehouse);
    int bpl_id = data?['bpl_id'] ?? box.read('bpl_id');
    final sapDb = data?['sap_db_name'] ?? box.read('sap_db_name');
    final sapUser = data?['sap_username'] ?? '';
    final sapPass = data?['sap_password'] ?? '';

    final loginSuccess = await _apiService.LoginSAP(
      sap_db: sapDb,
      sap_username: sapUser,
      sap_pass: sapPass,
    );
    if (!loginSuccess) {
      Get.snackbar(
        "Session Expired",
        "Gagal login ulang. Silakan login manual.",
        snackPosition: SnackPosition.TOP,
      );
      box.erase();
      Get.offAllNamed('/login');
    }

    final payload = {
      "DocDate": result['DocDate'],
      "NumAtCard": result['NoRef'],
      "BPL_IDAssignedToInvoice": bpl_id,
      "U_STEM_CardCode": result['CardCode'],
      "U_STEM_CardName": result['CardName'],
      "U_STEM_IssueType": result['id_issue'],
      "Comments": result['Comments'],
      "DocumentLines":
          adjustItems
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
     final success =true;
    
  //  final success = await _apiService.postGoodsReceiptadjust(payload);
   //  print('stock in controller post:  $success');
//final success=true;
    if (success) {
      Get.snackbar(
        'Success',
        'Data has been successfully submitted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      // Delay reset form biar snackbar sempat muncul
      Future.delayed(Duration(milliseconds: 500), () {
        resetForm();
      });
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
Future<void> submitAdjustment(BuildContext context) async {
    if (adjustItems.isEmpty) {
      Get.snackbar(
        'No Items',
        'Please add at least one item before submitting.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }
   
    final result = await showSubmitDialog(context);
    if (result == null) return;
     String warehouse_code =  selectedWarehouse.value?["warehouseCode"] ?? box.read('warehouse_code');
    final warehouse = {'warehouse_code': warehouse_code};

    final data = await _apiServices.getWarehouseAuth(warehouse);
    int bpl_id = data?['bpl_id'] ?? box.read('bpl_id');
    final sapDb = data?['sap_db_name'] ?? box.read('sap_db_name');
    final sapUser = data?['sap_username'] ?? '';
    final sapPass = data?['sap_password'] ?? '';

    final loginSuccess = await _apiService.LoginSAP(
      sap_db: sapDb,
      sap_username: sapUser,
      sap_pass: sapPass,
    );
    if (!loginSuccess) {
      Get.snackbar(
        "Session Expired",
        "Gagal login ulang. Silakan login manual.",
        snackPosition: SnackPosition.TOP,
      );
      box.erase();
      Get.offAllNamed('/login');
    }

    final payload = {
      "DocDate": result['DocDate'],
      "NumAtCard": result['NoRef'],
      "BPL_IDAssignedToInvoice": bpl_id,
      "U_STEM_CardCode": result['CardCode'],
      "U_STEM_CardName": result['CardName'],
      "U_STEM_IssueType": result['IssueType'],
      "Comments": result['Comments'],
      "DocumentLines":
          adjustItems
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
     String mode ='out';
    if(AdjutsmentStockMode.adjIn==currentMode.value)
    {
       mode='in';
    }
    final success = await _apiService.postAdjustment(payload,mode);
   //  print('stock in controller post:  $success'); 
    if (success) {
      Get.snackbar(
        'Success',
        'Data has been successfully submitted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      // Delay reset form biar snackbar sempat muncul
      Future.delayed(Duration(milliseconds: 500), () {
        resetForm();
      });
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
  void addadjustItem() {
    final code = adjustItemCodeController.text.trim();
    final name = adjustItemNameController.text.trim();
    final qty = double.tryParse(adjustQuantityController.text.trim()) ?? 0.0;

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

    final existingIndex = adjustItems.indexWhere(
      (item) => item["ItemCode"] == code,
    );
    if (existingIndex != -1) {
      adjustItems[existingIndex]["currentReceivedQuantity"] += qty;
      adjustItems[existingIndex] = adjustItems[existingIndex];
    } else {
      adjustItems.add({
        "ItemCode": code,
        "ItemName": name,
        "currentReceivedQuantity": qty,
      });
    }

    adjustItemCodeController.clear();
    adjustItemNameController.clear();
    adjustQuantityController.clear();
  }

  void handleScanResult(String scannedValue) async {
    FocusScope.of(Get.context!).unfocus();
    bool isNumeric(String s) => double.tryParse(s) != null;

     
      final itemIndex = adjustItems.indexWhere(
        (item) => item["ItemCode"] == scannedValue,
      );
      if (itemIndex != -1) {
        adjustItems[itemIndex]["currentReceivedQuantity"] += 1;
        adjustItems[itemIndex] = adjustItems[itemIndex];
      } else {
        // final itemName = await _apiService.getItemName(scannedValue);
        // if (itemName != "") {
        //   adjustItems.add({
        //     "ItemCode": scannedValue,
        //     "ItemName": itemName, 
        //     "currentReceivedQuantity": 1.0,
        //   });
        // } 
        final result = await _apiService.getItemName(scannedValue);
        if(result==null)
        {
          Get.snackbar(
            'Item Not Found',
            'Scanned item code "$scannedValue" not found in the system.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade400,
            colorText: Colors.white,
          );
          return;
        }
        if (result != "") {
          // pecah berdasarkan '|'
          final parts = result.split('|');
          final itemName = parts.isNotEmpty ? parts[0] : '';
          final uom = parts.length > 1 ? parts[1] : '';

          adjustItems.add({
            "ItemCode": scannedValue,
            "ItemName": itemName,
            "MeasureUnit": uom,
            "currentReceivedQuantity": 1.0,
          });
        }
        else {
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
