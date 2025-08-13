// lib/controllers/goods_receipt_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:wms/controllers/item_controller.dart';
import '../services/api_service.dart';
import '../services/sap_service.dart';
import '../widgets/custom_dropdown_search.dart';

enum StockInMode { poBased, nonPo,grgi }

class StockInController extends GetxController {
  final SAPService _apiService = Get.find<SAPService>();
  final ApiService _apiServices = Get.find<ApiService>();
  final ItemController itemcontroller = Get.find<ItemController>();
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

// --- Goods Issue - Goods Receipt ---
final grgiNumberController = TextEditingController();
final goodsIssue = Rxn<Map<String, dynamic>>();
final grgiItems = <Map<String, dynamic>>[].obs;


  final RxList<Map<String, dynamic>> vendorList = <Map<String, dynamic>>[].obs;
  final RxString selectedVendor = ''.obs;
  Rx<Map<String, dynamic>?> selectedWarehouse = Rx<Map<String, dynamic>?>(null);
  RxList<Map<String, dynamic>> warehouses = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> wmsUsers = <Map<String, dynamic>>[].obs;
List<TextEditingController> poItemQtyControllers = [];


  final box = GetStorage();
  @override
  void onInit() {
    super.onInit();
    fetchVendors();
    fetchDropdownData();
  }

  @override
  void onClose() {
    poNumberController.dispose();
    grgiNumberController.dispose();
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

     grgiNumberController.clear();
    goodsIssue.value = null;
    grgiItems.clear();

    nonPoItems.clear();
    nonPoItemCodeController.clear();
    nonPoItemNameController.clear();
    nonPoQuantityController.clear();
  }

  Future<void> fetchDropdownData() async {
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
 Future<void> searchGrgi() async {
    if (grgiNumberController.text.isEmpty) {
      Get.snackbar(
        'Input Required',
        'Please enter a Goods Issue Number.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    goodsIssue.value = null;
    grgiItems.clear();

    final data = await _apiService.fetchGIDetails(grgiNumberController.text);
    isLoading.value = false;
    print(data);
    if (data != null) {
      try {
        goodsIssue.value = {
          "docEntry": data["docEntry"],
          "docNum": data["docNum"],
          "cardCode": data["cardCode"],
          "cardName": data["cardName"],
          "docDate": data["docDate"],
          "docDueDate": data["docDueDate"],
           "comments": data["comments"],
          "documentStatus": data["documentStatus"],
        };
        if (goodsIssue.value!["documentStatus"] != "O") {
          goodsIssue.value = null;
          Get.snackbar(
            'Info',
            'Goods Issue ${data["docNum"]} is not open.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orangeAccent.shade700,
            colorText: Colors.white,
          );
          return;
        }
        final lines = List<Map<String, dynamic>>.from(data["lines"]);
        // final openItems =
        //     lines
        //         .where(
        //           (item) => (item["RemainingOpenQuantity"] ?? 0) > 0,
        //         )
        //         .toList();
        final openItems = lines
    .where((item) => (item["RemainingOpenQuantity"] ?? 0) > 0)
    .map((item) => {
          ...item,
          "baseEntry": data["docEntry"], // ← inject docEntry dari header
        })
    .toList();

        for (var item in openItems) {
          item["currentReceivedQuantity"] = 0.0;
        }

        grgiItems.assignAll(openItems);

        if (openItems.isEmpty) {
          Get.snackbar(
            'Info',
            'Goods Issue ${data["docNum"]} has no open items.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orangeAccent.shade700,
            colorText: Colors.white,
          );
        }
        else
        {
          Get.snackbar(
        'GI Number Found',
        'Please scan QR to add add items',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to process Goods Issue data: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        goodsIssue.value = null;
      }
    } 
  }
 void updateGrgiItemQuantity(int index, double quantity) {
    if (index >= 0 && index < grgiItems.length) {
      final item = grgiItems[index];
      if (quantity <= (item["RemainingOpenQuantity"] ?? 0)) {
        item["currentReceivedQuantity"] = quantity;
      } else { 
          final rawOpen = item["RemainingOpenQuantity"];
          final openQty = (rawOpen is num) ? rawOpen.toDouble() : 0.0;
           
          quantity=openQty+1;
          item["currentReceivedQuantity"] = quantity;
        Get.snackbar(
          'Warning',
          'Quantity for "${item["ItemDescription"]}" cannot exceed open quantity (${item["RemainingOpenQuantity"]}).',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
      
      }
       item["currentReceivedQuantity"] = quantity;
      grgiItems[index] = item; 
     grgiItems.refresh();
           }
  }
  
 Future<void> submitGIGoodsReceipt(BuildContext context) async {
   if (goodsIssue.value == null ||
        grgiItems.every((item) => item["currentReceivedQuantity"] <= 0)) {
      Get.snackbar(
        'Failed',
        'Please select a valid Goods Issue and ensure at least one item has a received quantity greater than 0.',
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
      "Comments": result['Comments'],
      "DocumentLines":
          grgiItems
              .map(
                (e) => {
                  "ItemCode": e["ItemCode"],
                  "Quantity": e["currentReceivedQuantity"].toInt(),
                  "WarehouseCode": warehouse_code,
                  "BaseType": 60,
                  "BaseEntry": e['baseEntry'], 
                  "BaseLine":e["LineNum"]
                },
              )
              .toList(),
    };

    isLoading.value = true;
     
    final success = await _apiService.postGoodsReceiptNonPo(payload);
     print('stock in controller post:  $success');
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
        else
        {
          Get.snackbar(
        'PO Number Found',
        'Please scan QR to add add items',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade700,
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
          final rawOpen = item["RemainingOpenInventoryQuantity"];
          final openQty = (rawOpen is num) ? rawOpen.toDouble() : 0.0;
           
          quantity=openQty+1;
          item["currentReceivedQuantity"] = quantity;
        Get.snackbar(
          'Warning',
          'Quantity for "${item["ItemDescription"]}" cannot exceed open quantity (${item["RemainingOpenInventoryQuantity"]}).',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
      
      }
       item["currentReceivedQuantity"] = quantity;
      poItems[index] = item; 
     poItems.refresh();
        // poItems[index]["currentReceivedQuantity"] = quantity;
    // poItemQtyControllers[index].text = quantity.toStringAsFixed(0);
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
      poItems.refresh();
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
    

    final result = await showSubmitDialog(context);
    if (result == null) return;

    String warehouse_code =
        selectedWarehouse.value?["warehouseCode"] ?? box.read('warehouse_code');
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
      "CardCode": purchaseOrder.value!["cardCode"],
      "CardName": purchaseOrder.value!["cardName"],
      "NumAtCard": result['NoRef'],
      "Comments": result['Comments'] ?? '',
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
      duration: Duration(seconds: 3),
    );

    // Delay reset form biar snackbar sempat muncul
    Future.delayed(Duration(milliseconds: 500), () {
      resetForm();
    });
    }
  }

  Future<Map<String, dynamic>?> showSubmitDialog(BuildContext context) async {
    TextEditingController dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
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
     print('stock in controller post:  $success');
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
