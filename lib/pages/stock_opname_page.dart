import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms/controllers/stock_opname_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../controllers/item_controller.dart';
import '../widgets/custom_dropdown_search.dart';
import 'scanner.dart'; // Hapus impor ini
//import 'package:qr_code_scanner/qr_code_scanner.dart'; // Tambahkan impor ini

 

 
class StockOpnamePage extends StatefulWidget {
  const StockOpnamePage({super.key});

  @override
  State<StockOpnamePage> createState() => _StockOpnamePageState();
}

class _StockOpnamePageState extends State<StockOpnamePage>
    with TickerProviderStateMixin {
  final StockOpnameController controller = Get.put(StockOpnameController());
   
  List<TextEditingController> poItemQtyControllers = []; 
  @override
   

   
  @override
  void dispose() {
    

    super.dispose();
  }

  Future<void> _navigateToScanner() async {
    final result = await Get.to(() => const BarcodeScannerPage());
    if (result != null && result is String && result.isNotEmpty) {
      controller.soNumberController.text=result;
      controller.searchSO();      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stock Opname", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        // actions: [
        //   ElevatedButton.icon(
        //     onPressed: () {
        //      controller.submitPoGoodsReceipt(context);
        //     },
        //     icon: const Icon(Icons.save),
        //      label: const Text(
        //       "Submit",
        //       style: TextStyle(fontSize: 14),
        //     ),
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.white,
        //       foregroundColor: Colors.blue,
        //       elevation: 0,
        //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(8),
        //       ),
        //     ),
        //   ),
        //   const SizedBox(width: 8),
        // ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildSOBasedForm(context);
        
      }),
       

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToScanner,
        label: const Text("Scan QR"),
        icon: const Icon(Icons.qr_code_scanner),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // FORM PO
  Widget _buildSOBasedForm(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Form Cari SO ===
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Search Stock Opname Number",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.soNumberController,
                            decoration: InputDecoration(
                              hintText: "Stock Opname Number",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: controller.searchSO,
                          icon: const Icon(Icons.search, color: Colors.blue),
                          label: const Text(
                            "Search",
                            style: TextStyle(color: Colors.blue),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.blue.shade500,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Obx(() {
              if (controller.stockOpname.value == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_center, color: Colors.grey, size: 60),
                      SizedBox(height: 10),
                      Text(
                        'Please search the Stock Opname number',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ); 
              }

              final po = controller.stockOpname.value!;
              final docEntry = po["DocumentEntry"];
              final docNum = po["DocumentNumber"];
              final items_rows =controller.soItems.length;
               
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // === SO Info ===
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Stock Opname Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Doc Number: ${po["DocumentNumber"]}"),
                             
                            Text(
                              "Date: ${DateTime.parse(po["CountDate"]).toLocal().toString().split(' ')[0]}",
                            ),
                            Text(
                              "Remarks: ${po["Remarks"]}",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // === Daftar Item ===
                  const Text(
                    "List Items",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.soItems.length,
                    itemBuilder: (context, index) {
                      final item = controller.soItems[index];
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 500), 
                        opacity:1, 
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                               border: Border.all(color: Colors.lightBlue.shade500, width: 2) ,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),

                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nama Item
                                  Text(
                                    "${item["ItemDescription"]} (${item["ItemCode"]})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Bin Loc : ${item["BinLoc"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Info Qty
                                  Text(
                                    "Stock Warehouse: ${item["InWarehouseQuantity"]}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 12), 
                                ],
                              ),
                            ),
                          ),
                         
                      );
                    },
                  ),
                  // === Tombol Generate Pick List ===
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => showPickListDialog(context,docEntry,docNum,items_rows),
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.playlist_add_check,
                                color: Colors.white,
                              ),
                        label: Text(
                          controller.isLoading.value
                              ? 'Processing ...'
                              : 'Submit',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
      
    );
    
  }

 void showPickListDialog(BuildContext context,int docEntry,int docNum,int items_rows) {
    final _formKey = GlobalKey<FormState>();
    final controller = Get.find<StockOpnameController>();
    final tempNote = TextEditingController();
    Rx<DateTime> selectedDate = DateTime.now().obs;

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
            child: Obx(
              () => Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      const Text(
                        'Detail Pick List',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(thickness: 1, color: Colors.grey),

                      // Picker Dropdown
                      CustomDropdownSearch<Map<String, dynamic>>(
                        labelText: "Picker",
                        selectedItem: controller.selectedPicker.value,
                        asyncItems: (String? filter) async {
                          final allPickers = controller.Picker.toList();

                          if (filter == null || filter.isEmpty)
                            return allPickers;

                          return allPickers.where((wh) {
                            final name =
                                (wh['nama'] ?? '').toString().toLowerCase();
                            final username =
                                (wh['username'] ?? '').toString().toLowerCase();
                            final filterText = filter.toLowerCase();
                            return name.contains(filterText) ||
                                username.contains(filterText);
                          }).toList();
                        },
                        onChanged: (picker) {
                          controller.selectedPicker.value = picker;
                        },
                       itemAsString: (picker) {
                        final nama = picker['nama'] ?? ''; 
                          final outstanding=   controller.outstandingPickList
                            .firstWhere(
                              (o) => o['Name'].toString().toLowerCase() == nama.toString().toLowerCase(),
                              orElse: () => {"Count": 0},
                            )['Count'];
                        return "$nama (Outstanding : ${outstanding ?? 0})";
                      },
                        compareFn: (a, b) => a['UserCode'] == b['UserCode'],
                        validator:
                            (picker) =>
                                picker == null
                                    ? 'Please select the Picker'
                                    : null,
                      ),

                      const SizedBox(height: 16),

                      // Note Input
                      TextFormField(
                        controller: tempNote,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Pick Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate.value,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                selectedDate.value = picked;
                              }
                            },
                            child: Text(
                              'Tanggal: ${selectedDate.value.toLocal().toIso8601String().split("T")[0]}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                controller.ProsesStockOpname(
                                  pickDate: selectedDate.value,
                                  pickerName:
                                      controller
                                          .selectedPicker
                                          .value?['nama'] ??
                                      '',
                                  note: tempNote.text,
                                  warehouse:
                                      ItemController()
                                          .selectedWarehouseFilter
                                          .value,
                                  docEntry: docEntry,
                                  docNum: docNum,
                                  items: items_rows
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: const Text("Submit"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
