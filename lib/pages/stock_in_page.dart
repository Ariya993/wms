import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stock_in_controller.dart';

import 'scanner.dart'; 

class StockInPage extends StatefulWidget {
  const StockInPage({super.key});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage>
    with TickerProviderStateMixin {
  final StockInController controller = Get.put(StockInController());
  late TabController _tabController;
  List<TextEditingController> poItemQtyControllers = []; 
  final ScrollController _poScrollController = ScrollController();

  List<TextEditingController> GIItemQtyControllers = [];
  final ScrollController _scrollController = ScrollController();

  List<TextEditingController> itrItemQtyControllers = [];
final ScrollController _itrScrollController = ScrollController();
  int? focusIndex;

  void focusOnItem(int index) {
    setState(() {
      focusIndex = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          index * 220, // perkiraan tinggi item (atur sesuai tinggi card kamu)
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void focusOnItemPO(int index) {
    setState(() {
      focusIndex = index;
    }); 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_poScrollController.hasClients) {
        _poScrollController.animateTo(
          index * 220, // perkiraan tinggi item (atur sesuai tinggi card kamu)
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

void focusOnItemITR(int index) {
    setState(() {
      focusIndex = index;
    }); 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itrScrollController.hasClients) {
        _itrScrollController.animateTo(
          index * 220, // perkiraan tinggi item (atur sesuai tinggi card kamu)
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      // initialIndex: controller.currentMode.value == StockInMode.poBased ? 0 : 2,
      initialIndex:
          controller.currentMode.value == StockInMode.poBased
              ? 0
              : controller.currentMode.value == StockInMode.grgi
              ? 1
              : 2,
      // initialIndex: controller.currentMode.value == StockInMode.poBased ? 0 : 1,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 0) {
        controller.setMode(StockInMode.poBased);
      } else if (_tabController.index == 1) {
        controller.setMode(StockInMode.grgi);
      }else {
        controller.setMode(StockInMode.itr);
      }
    }); 
    _syncQtyControllers(); 
    ever(controller.poItems, (_) => _syncQtyControllers());
    ever(controller.itrItems, (_) => _syncQtyControllers());
    ever(controller.grgiItems, (_) => _syncQtyControllers());
  }

  void _syncQtyControllers() {
    final poitems = controller.poItems;
    while (poItemQtyControllers.length < poitems.length) {
      final idx = poItemQtyControllers.length;
      final qty = (poitems[idx]['currentReceivedQuantity'] ?? 0).toInt();
      poItemQtyControllers.add(
        TextEditingController(text: qty == 0 ? '' : qty.toString()),
      );
    }

    final itritems = controller.itrItems;
    while (itrItemQtyControllers.length < itritems.length) {
      final idx = itrItemQtyControllers.length;
      final qty = (itritems[idx]['currentReceivedQuantity'] ?? 0).toInt();
      itrItemQtyControllers.add(
        TextEditingController(text: qty == 0 ? '' : qty.toString()),
      );
    }

    final grgiItems = controller.grgiItems;
    while (GIItemQtyControllers.length < grgiItems.length) {
      final idx = GIItemQtyControllers.length;
      final qty = (grgiItems[idx]['currentReceivedQuantity'] ?? 0).toInt();
      GIItemQtyControllers.add(
        TextEditingController(text: qty == 0 ? '' : qty.toString()),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();

    for (final c in poItemQtyControllers) {
      c.dispose();
    }

    for (final c in itrItemQtyControllers) {
      c.dispose();
    }


    for (final c in GIItemQtyControllers) {
      c.dispose();
    }

    super.dispose();
  }

  Future<void> _navigateToScanner() async {
    final result = await Get.to(() => const BarcodeScannerPage());
    if (result != null && result is String && result.isNotEmpty) {
      controller.handleScanResult(result);
      if (controller.currentMode.value == StockInMode.poBased) {
        if (controller.poItems.isNotEmpty) {
          final itemIndex = controller.poItems.indexWhere(
            (item) => item["ItemCode"] == result,
          );
          if (itemIndex >= 0) {
            final scannedItem = controller.poItems[itemIndex];
            // Hapus item dari posisi aslinya
            controller.poItems.removeAt(itemIndex);
            controller.poItems.insert(0, scannedItem);
            controller.update();

            for (int i = 0; i < controller.poItems.length; i++) {
              final item = controller.poItems[i];
              final currentQty = item["currentReceivedQuantity"] ?? 0;
              poItemQtyControllers[i].text = currentQty.toInt().toString();
            } 

            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusOnItemPO(0);
            });

            // String textValue = poItemQtyControllers[itemIndex].text;
            // final item = controller.poItems[itemIndex];
            // final openQty = item["RemainingOpenInventoryQuantity"] ?? 0;
            // final currentQty = item["currentReceivedQuantity"] ?? 0;
            //  poItemQtyControllers[itemIndex].text =currentQty.toInt().toString();
            //   debugPrint(itemIndex.toString());

            //   WidgetsBinding.instance.addPostFrameCallback((_) {
            //     focusOnItemPO(itemIndex);
            //   });
          }
        }
      } else if (controller.currentMode.value == StockInMode.itr) {
        if (controller.itrItems.isNotEmpty) {
          final itemIndex = controller.itrItems.indexWhere(
            (item) => item["ItemCode"] == result,
          );
          if (itemIndex >= 0) {
            final scannedItem = controller.itrItems[itemIndex];
            // Hapus item dari posisi aslinya
            controller.itrItems.removeAt(itemIndex);
            controller.itrItems.insert(0, scannedItem);
            controller.update();

            for (int i = 0; i < controller.itrItems.length; i++) {
              final item = controller.itrItems[i];
              final currentQty = item["currentReceivedQuantity"] ?? 0;
              itrItemQtyControllers[i].text = currentQty.toInt().toString();
            } 

            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusOnItemITR(0);
            });
 
          }
        }
      } 
      else if (controller.currentMode.value == StockInMode.grgi) {
        if (controller.grgiItems.isNotEmpty) {
          final itemIndex = controller.grgiItems.indexWhere(
            (item) => item["ItemCode"] == result,
          );
          debugPrint(itemIndex.toString());
          if (itemIndex >= 0) {
             final scannedItem = controller.grgiItems[itemIndex];
            controller.grgiItems.removeAt(itemIndex);
            controller.grgiItems.insert(0, scannedItem);
            controller.update();

            for (int i = 0; i < controller.grgiItems.length; i++) {
              final item = controller.grgiItems[i];
              final currentQty = item["currentReceivedQuantity"] ?? 0;
              GIItemQtyControllers[i].text = currentQty.toInt().toString();
            }
            debugPrint(0.toString());

            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusOnItem(0);
            });



            // String textValue = GIItemQtyControllers[itemIndex].text;
            // final item = controller.grgiItems[itemIndex];
            // final openQty = item["RemainingOpenQuantity"] ?? 0;
            // final currentQty = item["currentReceivedQuantity"] ?? 0;
            // GIItemQtyControllers[itemIndex].text =
            //     currentQty.toInt().toString();

            // Future.delayed(const Duration(milliseconds: 500), () {
            //   focusOnItem(itemIndex);
            // });
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
              } else if (controller.currentMode.value == StockInMode.grgi) {
                controller.submitGIGoodsReceipt(context);
              } 
              else if (controller.currentMode.value == StockInMode.itr) {
                controller.submitITRGoodsReceipt(context);
              }
            },
            icon: const Icon(Icons.save),
             label: Text( "Submit",
                style: const TextStyle(fontSize: 14),
              ),
             
            // label: Obx(
            //   () => Text(
            //     controller.currentMode.value == StockInMode.poBased
            //         ? "Submit"
            //         : "Submit",
            //     style: const TextStyle(fontSize: 14),
            //   ),
            // ),
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
            _buildGrGiForm(context),  
              _buildITRBasedForm(context),
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
              Tab(text: "Goods Receipt"), // Tab baru
              Tab(text: "Transfer Request"), // Tab baru
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    Icon(Icons.business_center, color: Colors.grey, size: 60),
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
                          Text("Vendor: ${po["cardName"]} (${po["cardCode"]})"),
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
                // SizedBox(
                //   height: 300,
                //   child:
                   ListView.builder(
                    controller: _poScrollController,
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.poItems.length,
                    itemBuilder: (context, index) {
                      final item = controller.poItems[index];
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity:
                            (item["currentReceivedQuantity"] ?? 0.1) > 0
                                ? 1.0
                                : 0.0,
                        child: IgnorePointer(
                          ignoring:
                              (item["currentReceivedQuantity"] ?? 0.1) <= 0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  (item["currentReceivedQuantity"] ==
                                          item["RemainingOpenInventoryQuantity"])
                                      ? Border.all(
                                        color: Colors.green.shade400,
                                        width: 2,
                                      )
                                      : null,
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
                                    "UOM : ${item["MeasureUnit"] ?? '-'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Bin Loc : ${item["BinLoc"]??''}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Info Qty
                                  Text(
                                    "Ordered: ${item["Quantity"]} | Received: ${item["ReceivedQuantity"] ?? 0} | Open: ${item["RemainingOpenInventoryQuantity"]}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
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
                                          final currentQty =
                                              item["currentReceivedQuantity"] ??
                                              0.0;
                                          if (currentQty > 0) {
                                            final newQty = (currentQty - 1)
                                                .clamp(0.0, double.infinity);
                                            controller.updatePoItemQuantity(
                                              index,
                                              newQty,
                                            );
                                            poItemQtyControllers[index].text =
                                                newQty == 0.0
                                                    ? ''
                                                    : newQty.toInt().toString();
                                          }
                                        },
                                      ),
                                      SizedBox(
                                        width: 100,
                                        height: 38,
                                        child: TextField(
                                          controller:
                                              poItemQtyControllers[index],
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                        onPressed: () {
                                          final currentQty =
                                              item["currentReceivedQuantity"] ??
                                              0.0;
                                          final maxQty =
                                              item["RemainingOpenInventoryQuantity"] ??
                                              0.0;
                                          if (currentQty < maxQty) {
                                            final newQty = (currentQty + 1)
                                                .clamp(0.0, double.infinity);
                                            controller.updatePoItemQuantity(
                                              index,
                                              newQty,
                                            );
                                            poItemQtyControllers[index].text =
                                                newQty.toInt().toString();
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
                                          poItemQtyControllers[index].text =
                                              "0";
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
               // ),
              ],
            );
          }),
        ],
      ),
   ),
    );
  }

  // FORM PO
  Widget _buildITRBasedForm(BuildContext context) {
    return SingleChildScrollView(
   child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Form Cari ITR ===
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
                    "Search Transfer Request",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.itrNumberController,
                          decoration: InputDecoration(
                            hintText: "Transfer Request Number",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: controller.searchITR,
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
            if (controller.inventoryTransfer.value == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_center, color: Colors.grey, size: 60),
                    SizedBox(height: 10),
                    Text(
                      'Please search the Transfer Request number',
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

            final po = controller.inventoryTransfer.value!;

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
                            "Transfer Request Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("Transfer Request Number: ${po["docNum"]}"),
                          Text("Vendor: ${po["cardName"]} (${po["cardCode"]})"),
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
                // SizedBox(
                //   height: 300,
                //   child:
                   ListView.builder(
                    controller: _itrScrollController,
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.itrItems.length,
                    itemBuilder: (context, index) {
                      final item = controller.itrItems[index];

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity:
                            (item["currentReceivedQuantity"] ?? 0.1) > 0
                                ? 1.0
                                : 0.0,
                        child: IgnorePointer(
                          ignoring:
                              (item["currentReceivedQuantity"] ?? 0.1) <= 0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  (item["currentReceivedQuantity"] ==
                                          item["RemainingOpenQuantity"])
                                      ? Border.all(
                                        color: Colors.green.shade400,
                                        width: 2,
                                      )
                                      : null,
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
                                    "UOM : ${item["MeasureUnit"] ?? '-'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Bin Loc : ${item["BinLoc"]?? '-'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Info Qty
                                  Text(
                                    "Qty Transfer: ${item["Quantity"]} | Received: ${item["ReceivedQuantity"] ?? 0} | Open: ${item["RemainingOpenQuantity"]}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
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
                                          final currentQty =
                                              item["currentReceivedQuantity"] ??
                                              0.0;
                                          if (currentQty > 0) {
                                            final newQty = (currentQty - 1)
                                                .clamp(0.0, double.infinity);
                                            controller.updateitrItemQuantity(
                                              index,
                                              newQty,
                                            );
                                            itrItemQtyControllers[index].text =
                                                newQty == 0.0
                                                    ? ''
                                                    : newQty.toInt().toString();
                                          }
                                        },
                                      ),
                                      SizedBox(
                                        width: 100,
                                        height: 38,
                                        child: TextField(
                                          controller:
                                              itrItemQtyControllers[index],
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: false,
                                              ),
                                          onChanged: (value) {
                                            controller.updateitrItemQuantity(
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
                                        onPressed: () {
                                          final currentQty =
                                              item["currentReceivedQuantity"] ??
                                              0.0;
                                          final maxQty =
                                              item["RemainingOpenQuantity"] ??
                                              0.0;
                                          if (currentQty < maxQty) {
                                            final newQty = (currentQty + 1)
                                                .clamp(0.0, double.infinity);
                                            controller.updateitrItemQuantity(
                                              index,
                                              newQty,
                                            );
                                            itrItemQtyControllers[index].text =
                                                newQty.toInt().toString();
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
                                          controller.updateitrItemQuantity(
                                            index,
                                            0.0,
                                          );
                                          itrItemQtyControllers[index].text =
                                              "0";
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
               // ),
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
   child:Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Form Cari GI ===
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
                      "Search Goods Receipt",
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
                              hintText: "Goods Receipt Number",
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
                      Icon(Icons.business_center, color: Colors.grey, size: 60),
                      SizedBox(height: 10),
                      Text(
                        'Please search the goods receipt number',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final po = controller.goodsIssue.value!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // === GI Info ===
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
                              "GR Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Doc Number: ${po["docNum"]}"),
                            Text(
                              "From Warehouse: ${po["lines"] != null && po["lines"].isNotEmpty ? po["lines"][0]["WarehouseCode"] : ''}",
                            ),

                            Text(
                              "Date: ${DateTime.parse(po["docDate"]).toLocal().toString().split(' ')[0]}",
                            ),
                            Text("Comments: ${po["comments"]}"),
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
                  // SizedBox(
                  //   height: 250,
                  //   child:
                     ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      //  physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.grgiItems.length,
                      itemBuilder: (context, index) {
                        final item = controller.grgiItems[index];

                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity:
                              (item["currentReceivedQuantity"] ?? 0.1) > 0
                                  ? 1.0
                                  : 0.0,
                          child: IgnorePointer(
                            ignoring:
                                (item["currentReceivedQuantity"] ?? 0.1) <= 0,
                            child: Visibility(
                              visible:
                                  (item["currentReceivedQuantity"] ?? 0) > 0,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      (item["currentReceivedQuantity"] ==
                                              item["RemainingOpenQuantity"])
                                          ? Border.all(
                                            color: Colors.green.shade400,
                                            width: 2,
                                          )
                                          : null,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        "Qty Transfer: ${item["Quantity"]} | Received: ${item["ReceivedQuantity"] ?? 0} | Open: ${item["RemainingOpenQuantity"]}",
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
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
                                              final currentQty =
                                                  item["currentReceivedQuantity"] ??
                                                  0.0;
                                              if (currentQty > 0) {
                                                final newQty = (currentQty - 1)
                                                    .clamp(
                                                      0.0,
                                                      double.infinity,
                                                    );
                                                controller
                                                    .updateGrgiItemQuantity(
                                                      index,
                                                      newQty,
                                                    );
                                                GIItemQtyControllers[index]
                                                    .text = newQty == 0.0
                                                        ? ''
                                                        : newQty
                                                            .toInt()
                                                            .toString();
                                              }
                                            },
                                          ),
                                          SizedBox(
                                            width: 100,
                                            height: 38,
                                            child: TextField(
                                              controller:
                                                  GIItemQtyControllers[index],
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
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: false,
                                                  ),
                                              onChanged: (value) {
                                                controller
                                                    .updateGrgiItemQuantity(
                                                      index,
                                                      double.tryParse(value) ??
                                                          0.0,
                                                    );
                                              },
                                            ),
                                          ),

                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: Colors.green,
                                            ),

                                            onPressed: () {
                                              final currentQty =
                                                  item["currentReceivedQuantity"] ??
                                                  0.0;
                                              final maxQty =
                                                  item["RemainingOpenQuantity"] ??
                                                  0.0;
                                              if (currentQty < maxQty) {
                                                final newQty = (currentQty + 1)
                                                    .clamp(
                                                      0.0,
                                                      double.infinity,
                                                    );
                                                controller
                                                    .updateGrgiItemQuantity(
                                                      index,
                                                      newQty,
                                                    );
                                                GIItemQtyControllers[index]
                                                        .text =
                                                    newQty.toInt().toString();
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
                                              controller.updateGrgiItemQuantity(
                                                index,
                                                0.0,
                                              );
                                              GIItemQtyControllers[index].text =
                                                  "0";
                                            },
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
                      },
                    ),
                  //),
                ],
              );
            }),
          ],
        ),
   ),
    );
  }
}
