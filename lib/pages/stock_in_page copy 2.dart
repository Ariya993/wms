import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stock_in_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../widgets/custom_dropdown_search.dart'; // Hapus impor ini
//import 'package:qr_code_scanner/qr_code_scanner.dart'; // Tambahkan impor ini

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR/Barcode',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
          IconButton(
            icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: () {
              cameraController.switchCamera();
              setState(() {
                _isFrontCamera = !_isFrontCamera;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isScanned) return;
              _isScanned = true;
              final barcode = capture.barcodes.first;
              final code = barcode.rawValue;
              if (code != null && code.isNotEmpty) {
                Get.back(result: code);
              } else {
                _isScanned = false;
              }
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 20),
              child: const Text(
                'Arahkan QR/Barcode ke dalam bingkai',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StockInPage extends StatefulWidget {
  const StockInPage({super.key});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage>
    with TickerProviderStateMixin {
  final StockInController controller = Get.put(StockInController());
  late TabController _tabController;
  final List<TextEditingController> _nonPoQtyControllers = [];
List<TextEditingController> poItemQtyControllers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      // initialIndex: controller.currentMode.value == StockInMode.poBased ? 0 : 
      //            controller.currentMode.value == StockInMode.nonPo ? 1 : 2,
      // // initialIndex: controller.currentMode.value == StockInMode.poBased ? 0 : 1,
    );

    // _tabController.addListener(() {
    //   if (_tabController.indexIsChanging) return;
    //   if (_tabController.index == 0) {
    //     controller.setMode(StockInMode.poBased);
    //   } else {
    //     controller.setMode(StockInMode.nonPo);
    //   }
    // });
  //   _tabController.addListener(() {
  //   if (_tabController.indexIsChanging) return;
  //   if (_tabController.index == 0) {
  //     controller.setMode(StockInMode.poBased);
  //   } else if (_tabController.index == 1) {
  //     controller.setMode(StockInMode.nonPo);
  //   } else {
  //     controller.setMode(StockInMode.grgi); // Tambah mode baru
  //   }
  // });

    _syncQtyControllers();
 //initPoItemQtyControllers();
  // Auto sync saat nonPoItems berubah
  ever(controller.nonPoItems, (_) => _syncQtyControllers());
  ever(controller.poItems, (_) => _syncQtyControllers());
  }

 void initPoItemQtyControllers() {
    poItemQtyControllers = controller.poItems.map((item) {
      return TextEditingController(
        text: item["currentReceivedQuantity"]?.toStringAsFixed(0) ?? '0',
      );
    }).toList();
  }

void _syncQtyControllers() {
  final items = controller.nonPoItems;
  while (_nonPoQtyControllers.length < items.length) {
    final idx = _nonPoQtyControllers.length;
    final qty = (items[idx]['currentReceivedQuantity'] ?? 0).toInt();
    _nonPoQtyControllers.add(
      TextEditingController(text: qty == 0 ? '' : qty.toString()),
    );
  }

  final poitems = controller.poItems;
  while (poItemQtyControllers.length < poitems.length) {
    final idx = poItemQtyControllers.length;
    final qty = (poitems[idx]['currentReceivedQuantity'] ?? 0).toInt();
    poItemQtyControllers.add(
      TextEditingController(text: qty == 0 ? '' : qty.toString()),
    );
  }
}
  @override
  void dispose() {
    _tabController.dispose();
     for (final c in _nonPoQtyControllers) {
    c.dispose();
  }

 for (final c in poItemQtyControllers) {
    c.dispose();
  }

  //  for (var controller in poItemQtyControllers) {
  //     controller.dispose();
  //   }
    super.dispose();
  }

  Future<void> _navigateToScanner() async {
    final result = await Get.to(() => const BarcodeScannerPage());
    if (result != null && result is String && result.isNotEmpty) {
      
     controller.handleScanResult(result);
    if(controller.currentMode.value == StockInMode.poBased)
    {
      if (controller.poItems.isNotEmpty)
      {
          final itemIndex = controller.poItems.indexWhere(
            (item) => item["ItemCode"] == result,
          );
          print(itemIndex);
          if(itemIndex >= 0)
          { 
            final item = controller.poItems[itemIndex];
            final openQty = item["RemainingOpenInventoryQuantity"] ?? 0;
            final currentQty = item["currentReceivedQuantity"] ?? 0; 
            if (currentQty < openQty) {
             
                String textValue = poItemQtyControllers[itemIndex].text;
                int cQty = textValue.isEmpty ? 0 : int.tryParse(textValue) ?? 0;
                int newQty = cQty + 1; 
                poItemQtyControllers[itemIndex].text = newQty.toString();

            } else {
              Get.snackbar(
                'Max Quantity',
                'Qty untuk "${item["ItemDescription"]}" sudah mencapai limit open ($openQty).',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange.shade700,
                colorText: Colors.white,
              );
            }
            
           
          } 
      } 
    }
    else{
      if (controller.nonPoItems.isNotEmpty)
      {
          final itemIndex = controller.nonPoItems.indexWhere(
            (item) => item["ItemCode"] == result,
          );
          print(itemIndex);
          if(itemIndex >= 0)
          { 
            String textValue = _nonPoQtyControllers[itemIndex].text;
            int currentQty = textValue.isEmpty ? 0 : int.tryParse(textValue) ?? 0;
            int newQty = currentQty + 1;

  
              _nonPoQtyControllers[itemIndex].text = newQty.toString();
          } 
      } 
    }
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventory In", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              if (controller.currentMode.value == StockInMode.poBased) {
                controller.submitPoGoodsReceipt(context);
              } else {
                // controller.submitNonPoGoodsReceipt(context);
              }
            },
            icon: const Icon(Icons.save),
            label: Obx(
              () => Text(
                controller.currentMode.value == StockInMode.poBased
                    ? "Submit"
                    : "Submit",
                style: const TextStyle(fontSize: 14),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return TabBarView(
          controller: _tabController,
          children: [
          _buildPoBasedForm(context),
          _buildNonPoForm(context),
          _buildGrGiForm(context), // Form baru
        ],
          // children: [_buildPoBasedForm(context), _buildNonPoForm(context)],
        );
      }),
      bottomNavigationBar: SizedBox(
        height: 42, // <--- atur tinggi eksplisit yang kecil
        child: Material(
          color: Colors.blue.shade50,
          elevation: 6,
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.blue.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorPadding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.blueGrey.shade500,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
             tabs: const [
              Tab(text: "PO Based"), 
              Tab(text: "Transfer Request"),
              Tab(text: "Goods Issue")  // Tab baru
            ],
            // tabs: const [Tab(text: "PO Based"), Tab(text: "Non-PO")],
            //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // <- ini menghapus padding default
          ),
        ),
      ),

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
  Widget _buildPoBasedForm(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Form Cari PO ===
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
                      "Search PO",
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
                            controller: controller.poNumberController,
                            decoration: InputDecoration(
                              hintText: "PO Number",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: controller.searchPo,
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
              if (controller.purchaseOrder.value == null) {
                return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_center,
                          color: Colors.grey,
                          size: 60,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Please search the PO number',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );

                // return const Center(
                //   child: Padding(
                //     padding: EdgeInsets.all(20),
                //     child: Text(
                //       "Please search the PO number.",
                //       style: TextStyle(fontSize: 16, color: Colors.grey),
                //     ),
                //   ),
                // );
              }

              final po = controller.purchaseOrder.value!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // === PO Info ===
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
                              "PO Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("PO Number: ${po["docNum"]}"),
                            Text(
                              "Vendor: ${po["cardName"]} (${po["cardCode"]})",
                            ),
                            Text(
                              "Date: ${DateTime.parse(po["docDate"]).toLocal().toString().split(' ')[0]}",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // === Daftar Item ===
                  const Text(
                    "Items to Receive",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.poItems.length,
                    itemBuilder: (context, index) {
                      final item = controller.poItems[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                                "Ordered: ${item["Quantity"]} | Received: ${item["ReceivedQuantity"] ?? 0} | Open: ${item["RemainingOpenInventoryQuantity"]}",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 12),

                              // Input Quantity
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                     onPressed: () {
                                      final currentQty = item["currentReceivedQuantity"] ?? 0.0;
                                      if (currentQty > 0) {
                                        final newQty = (currentQty - 1).clamp(0.0, double.infinity);
                                        controller.updatePoItemQuantity(index, newQty);
                                        poItemQtyControllers[index].text =
                                            newQty == 0.0 ? '' : newQty.toInt().toString();
                                      }
                                    }, 
                                  ),
                                  SizedBox(
                                    width: 100,
                                    height: 38,
                                    child: TextField(
                                      controller: poItemQtyControllers[index],
                                      // controller: TextEditingController(
                                      //   text:
                                      //       item["currentReceivedQuantity"] ==
                                      //               0.0
                                      //           ? ''
                                      //           : item["currentReceivedQuantity"]
                                      //               .toStringAsFixed(0),
                                      // ),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: "0",
                                        filled: true,
                                        fillColor: Colors.white,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: false,
                                          ),
                                      onChanged: (value) {
                                        controller.updatePoItemQuantity(
                                          index,
                                          double.tryParse(value) ?? 0.0,
                                        );
                                      },
                                    ),
                                  ),
                                  
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.green,
                                    ),
                                    // onPressed: () {
                                    //   final currentQty = item["currentReceivedQuantity"] ?? 0.0;
                                    //   if (currentQty > 0) {
                                    //     final newQty = (currentQty - 1).clamp(0.0, double.infinity);
                                    //     controller.updatePoItemQuantity(index, newQty);
                                    //     poItemQtyControllers[index].text =
                                    //         newQty == 0.0 ? '' : newQty.toInt().toString();
                                    //   }
                                    // }, 
                                    onPressed: () {
                                      final currentQty =
                                          item["currentReceivedQuantity"] ??
                                          0.0;
                                      final maxQty =
                                          item["RemainingOpenInventoryQuantity"] ??
                                          0.0;
                                      if (currentQty < maxQty) {
                                          final newQty = (currentQty + 1).clamp(0.0, double.infinity);
                                        controller.updatePoItemQuantity(
                                          index,
                                          newQty,
                                        );
                                         poItemQtyControllers[index].text = newQty.toInt().toString();
                                      }
                                    },
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.red,
                                    ),
                                    
                                    onPressed: () {
                                      controller.updatePoItemQuantity(
                                        index,
                                        0.0,
                                      );
                                      poItemQtyControllers[index].text="0";
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }


Widget _buildGrGiForm(BuildContext context) {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Form Cari Transfer Request ===
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
                    "Search Goods Issue",
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
                          controller: controller.grgiNumberController,
                          decoration: InputDecoration(
                            hintText: "Goods Issue Number",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: controller.searchGrgi,
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
            if (controller.goodsIssue.value == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: Colors.grey,
                      size: 60,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please search the goods issue number',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final tr = controller.goodsIssue.value!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // === Transfer Request Info ===
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
                            "Goods Issue Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("Doc Number: ${tr["docNum"]}"),
                          Text("From Warehouse: ${tr["warehouseCode"]}"),
                          // Text("To Warehouse: ${tr["toWhsCode"]}"),
                          Text(
                            "Date: ${DateTime.parse(tr["docDate"]).toLocal().toString().split(' ')[0]}",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // === Daftar Item ===
                const Text(
                  "Items to Transfer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.grgiItems.length,
                  itemBuilder: (context, index) {
                    final item = controller.grgiItems[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                            Text(
                              "${item["ItemDescription"]} (${item["ItemCode"]})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Bin Loc: ${item["BinLoc"]}",
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Qty Transfer: ${item["Quantity"]} | Open: ${item["RemainingOpenQuantity"]}",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 12),
                            
                            // Input Quantity with +/- buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () {
                                    final currentQty = item["currentReceivedQuantity"] ?? 0.0;
                                    if (currentQty > 0) {
                                      controller.updateGrgiItemQuantity(
                                        index, 
                                        (currentQty - 1).clamp(0.0, double.infinity)
                                      );
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: 100,
                                  height: 38,
                                  child: TextField(
                                    controller: TextEditingController(
                                      text: item["currentReceivedQuantity"]?.toString() ?? "0"
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: "0",
                                      filled: true,
                                      fillColor: Colors.white,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    onChanged: (value) {
                                      controller.updateGrgiItemQuantity(
                                        index,
                                        double.tryParse(value) ?? 0.0,
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () {
                                    final currentQty = item["currentReceivedQuantity"] ?? 0.0;
                                    final maxQty = item["RemainingOpenQuantity"] ?? 0.0;
                                    if (currentQty < maxQty) {
                                      controller.updateGrgiItemQuantity(
                                        index,
                                        currentQty + 1,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }),
        ],
      ),
    ),
  );
}


  Widget _buildNonPoForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // 🔽 Header Collapse
          GestureDetector(
            onTap: () => controller.isNonPoExpanded.toggle(),
            child: Obx(
              () => Row(
                children: [
                  Icon(
                    controller.isNonPoExpanded.value
                        ? Icons.indeterminate_check_box
                        : Icons.add_box_outlined,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.isNonPoExpanded.value
                        ? "Hide Form"
                        : "Show Form",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🔁 Input Item (collapsable)
          Obx(
            () =>
                controller.isNonPoExpanded.value
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomDropdownSearch<Map<String, dynamic>>(
                          labelText: 'Item',
                          asyncItems: (String? filter) async {
                            final result = await controller.getItem(
                              filter ?? '',
                            );
                            return result;
                          },
                          // selectedItem: controller.nonPoItems.firstWhereOrNull(
                          //   (item) =>
                          //       item['ItemCode'] ==
                          //       controller.nonPoItemCodeController.text,
                          // ),
                          itemAsString:
                              (item) =>
                                  "${item['ItemCode']} - ${item['ItemName']}",
                          compareFn: (a, b) => a['ItemCode'] == b['ItemCode'],
                          onChanged: (value) {
                            controller.nonPoItemCodeController.text =
                                value?['ItemCode'] ?? '';
                            controller.nonPoItemNameController.text =
                                value?['ItemName'] ?? '';
                          },
                        ),

                        const SizedBox(height: 10),
                        TextField(
                              controller: controller.nonPoQuantityController,
                              decoration: InputDecoration(
                                labelText: "Quantity",
                                hintText: "Enter Quantity",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.production_quantity_limits,
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: false,
                              ),
                            ),
                        const SizedBox(height: 10),
                        // SizedBox(
                        //   width: double.infinity,
                        //   child: ElevatedButton.icon(
                        //     onPressed: controller.addNonPoItem,
                        //     icon: const Icon(
                        //       Icons.add_shopping_cart,
                        //       color: Colors.green,
                        //     ),
                        //     label: const Text(
                        //       "Add Item",
                        //       style: TextStyle(color: Colors.green),
                        //     ),
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.white,
                        //       side: BorderSide(
                        //         color: Colors.green.shade500,
                        //         width: 2,
                        //       ),
                        //       padding: const EdgeInsets.symmetric(vertical: 12),
                        //       minimumSize: const Size.fromHeight(
                        //         56,
                        //       ), // tinggi tombol jadi 56 px
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //       ),
                        //       elevation: 0,
                        //     ).copyWith(
                        //       // atur warna saat hover (web/desktop)
                        //       overlayColor: MaterialStateProperty.resolveWith<
                        //         Color?
                        //       >((Set<MaterialState> states) {
                        //         if (states.contains(MaterialState.hovered)) {
                        //           return Colors.green.shade500.withOpacity(
                        //             0.3,
                        //           ); // hover background hijau muda
                        //         }
                        //         if (states.contains(MaterialState.pressed)) {
                        //           return Colors.green.shade200.withOpacity(
                        //             0.5,
                        //           ); // pressed effect
                        //         }
                        //         return null; // default
                        //       }),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 20),
                      ],
                    )
                    : const SizedBox(),
          ),

          const Text(
            "Items to Receive (Non-PO):",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Flexible(
            child: Obx(() {
              if (controller.nonPoItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_center,
                          color: Colors.grey,
                          size: 60,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No items added',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );

                // return const Center(
                //   child: Text(
                //     "No items added.",
                //     style: TextStyle(color: Colors.grey, fontSize: 16),
                //   ),
                // );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: controller.nonPoItems.length,
                itemBuilder: (context, index) {
                  final item = controller.nonPoItems[index];
                  final qty = (item["currentReceivedQuantity"] ?? 0).toInt();

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item["ItemName"]} (${item["ItemCode"]})",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  // if (qty > 0) {
                                  //   controller.updateNonPoItemQuantity(
                                  //     index,
                                  //    (qty - 1).toDouble(),
                                  //   );
                                  // }
                                  if (qty > 0) {
                                      final newQty = (qty - 1).toDouble();
                                      //controller.updateNonPoItemQuantity(index, newQty);

                                      // ⬇️ update controller juga
                                      _nonPoQtyControllers[index].text = newQty == 0 ? '' : newQty.toInt().toString();
                                    }
                                },
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                              ),
                              

                              SizedBox(
                                width: 100,
                                height: 36,
                                child: TextField(
                                  controller: _nonPoQtyControllers[index],

                                  // controller: TextEditingController(
                                  //   text: qty == 0 ? '' : qty.toString(),
                                  // ),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    print(value);
                                    // controller.updateNonPoItemQuantity(
                                    //   index,
                                    //   double.tryParse(value) ?? 0,
                                    // );
                                  },
                                ),
                              ),
                              IconButton(
                                 onPressed: () {
                                  final newQty = (qty + 1).toDouble();
                                 // controller.updateNonPoItemQuantity(index, newQty);

                                  _nonPoQtyControllers[index].text = newQty.toInt().toString();
                                },
                                // onPressed: 
                                //     () => controller.updateNonPoItemQuantity(
                                //       index,
                                //       (qty + 1).toDouble(),
                                //     ),
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                              // IconButton(
                              //   icon: const Icon(
                              //     Icons.delete,
                              //     color: Colors.red,
                              //   ),
                              //   // onPressed: () {
                              //   //   controller.updateNonPoItemQuantity(index, 0);
                              //   //   _nonPoQtyControllers[index].text = '';
                              //   // },

                              //    onPressed:
                              //        () => controller.removeNonPoItem(index),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
