import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/adjustment_stock_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../widgets/custom_dropdown_search.dart';
import '../widgets/loading.dart';
import 'scanner.dart'; // Hapus impor ini
//import 'package:qr_code_scanner/qr_code_scanner.dart'; // Tambahkan impor ini

 
class AdjustmentStockPage extends StatefulWidget {
  const AdjustmentStockPage({super.key});

  @override
  State<AdjustmentStockPage> createState() => _AdjustmentStockPageState();
}

class _AdjustmentStockPageState extends State<AdjustmentStockPage>
    with TickerProviderStateMixin {
  final AdjutsmentStockController controller = Get.put(AdjutsmentStockController());
  late TabController _tabController;
  final List<TextEditingController> _adjustQtyControllers = [];
 final ScrollController _scrollController = ScrollController();
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
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex:
          controller.currentMode.value == AdjutsmentStockMode.adjOut
              ? 0
              : 1  
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 0) {
        controller.setMode(AdjutsmentStockMode.adjOut);
      } else {
        controller.setMode(AdjutsmentStockMode.adjIn);
      }
    });
   
    _syncQtyControllers();
  
    ever(controller.adjustItems, (_) => _syncQtyControllers()); 
  }

  void _syncQtyControllers() {
    final items = controller.adjustItems;
    while (_adjustQtyControllers.length < items.length) {
      final idx = _adjustQtyControllers.length;
      final qty = (items[idx]['currentReceivedQuantity'] ?? 0).toInt();
      _adjustQtyControllers.add(
        TextEditingController(text: qty == 0 ? '' : qty.toString()),
      );
    }

     
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _adjustQtyControllers) {
      c.dispose();
    }

    

    super.dispose();
  }

  Future<void> _navigateToScanner() async {
    final result = await Get.to(() => const BarcodeScannerPage());
    if (result != null && result is String && result.isNotEmpty) {
      controller.handleScanResult(result);
       
        if (controller.adjustItems.isNotEmpty) {
          final itemIndex = controller.adjustItems.indexWhere(
            (item) => item["ItemCode"] == result,
          );
          print(itemIndex);
          if (itemIndex >= 0) {
            String textValue = _adjustQtyControllers[itemIndex].text;
            int currentQty =
                textValue.isEmpty ? 0 : int.tryParse(textValue) ?? 0;
            int newQty = currentQty + 1;

            _adjustQtyControllers[itemIndex].text = newQty.toString();
          Future.delayed(const Duration(milliseconds: 300), () {
                        focusOnItem(itemIndex);
                      });
                         

          }
        }
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Adjustment Stock", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              if (controller.currentMode.value == AdjutsmentStockMode.adjOut) {
                controller.submitAdjustment(context);
              } else if (controller.currentMode.value == AdjutsmentStockMode.adjIn) {
                controller.submitAdjustment(context);
              }  
            },
            icon: const Icon(Icons.save),
             label:  Text( "Submit" ,
                style: const TextStyle(fontSize: 14),
              
            ),
            // label: Obx(
            //   () => Text(
            //     controller.currentMode.value == AdjutsmentStockMode.adjIn
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
          return const Loading();
        }
        return _buildNonPoForm(context); 
      }),

      // body: Obx(() {
      //   if (controller.isLoading.value) {
      //     return const Loading();
      //   }

      //   return TabBarView(
      //     controller: _tabController,
      //     children: [
      //       _buildPoBasedForm(context),
      //       // _buildNonPoForm(context),
      //       _buildGrGiForm(context), // Form baru
      //     ],
      //     // children: [_buildPoBasedForm(context), _buildNonPoForm(context)],
      //   );
      // }),
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
              Tab(text: "Adjustment Stock Out"),
              // Tab(text: "Transfer Request"),
              Tab(text: "Adjustment Stock In"), // Tab baru
            ], 
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

 
  Widget _buildNonPoForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const SizedBox(height: 10),

          // // 🔽 Header Collapse
          // GestureDetector(
          //   onTap: () => controller.isadjustExpanded.toggle(),
          //   child: Obx(
          //     () => Row(
          //       children: [
          //         Icon(
          //           controller.isadjustExpanded.value
          //               ? Icons.indeterminate_check_box
          //               : Icons.add_box_outlined,
          //           color: Colors.blue.shade700,
          //         ),
          //         const SizedBox(width: 8),
          //         Text(
          //           controller.isadjustExpanded.value
          //               ? "Hide Form"
          //               : "Show Form",
          //           style: TextStyle(
          //             color: Colors.blue.shade700,
          //             fontWeight: FontWeight.w500,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // const SizedBox(height: 10),

          // 🔁 Input Item (collapsable)
          // Obx(
          //   () =>
          //       controller.isadjustExpanded.value
          //           ? Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               CustomDropdownSearch<Map<String, dynamic>>(
          //                 labelText: 'Item',
          //                 asyncItems: (String? filter) async {
          //                   final result = await controller.getItem(
          //                     filter ?? '',
          //                   );
          //                   return result;
          //                 },
          //                 selectedItem: controller.adjustItems.firstWhereOrNull(
          //                   (item) =>
          //                       item['ItemCode'] ==
          //                       controller.adjustItemCodeController.text,
          //                 ),
          //                 itemAsString:
          //                     (item) =>
          //                         "${item['ItemCode']} - ${item['ItemName']}",
          //                 compareFn: (a, b) => a['ItemCode'] == b['ItemCode'],
          //                 onChanged: (value) {
          //                   controller.adjustItemCodeController.text =
          //                       value?['ItemCode'] ?? '';
          //                   controller.adjustItemNameController.text =
          //                       value?['ItemName'] ?? '';
          //                 },
          //               ),

          //               const SizedBox(height: 10),
          //               TextField(
          //                 controller: controller.adjustQuantityController,
          //                 decoration: InputDecoration(
          //                   labelText: "Quantity",
          //                   hintText: "Enter Quantity",
          //                   border: OutlineInputBorder(
          //                     borderRadius: BorderRadius.circular(8),
          //                   ),
          //                   prefixIcon: const Icon(
          //                     Icons.production_quantity_limits,
          //                   ),
          //                 ),
                          
          //                 keyboardType: const TextInputType.numberWithOptions(
          //                   decimal: false,
          //                 ),
          //               ),
          //               const SizedBox(height: 10),
          //               SizedBox(
          //                 width: double.infinity,
          //                 child: ElevatedButton.icon(
          //                   onPressed: controller.addadjustItem,
          //                   icon: const Icon(
          //                     Icons.add_shopping_cart,
          //                     color: Colors.green,
          //                   ),
          //                   label: const Text(
          //                     "Add Item",
          //                     style: TextStyle(color: Colors.green),
          //                   ),
          //                   style: ElevatedButton.styleFrom(
          //                     backgroundColor: Colors.white,
          //                     side: BorderSide(
          //                       color: Colors.green.shade500,
          //                       width: 2,
          //                     ),
          //                     padding: const EdgeInsets.symmetric(vertical: 12),
          //                     minimumSize: const Size.fromHeight(
          //                       56,
          //                     ), // tinggi tombol jadi 56 px
          //                     shape: RoundedRectangleBorder(
          //                       borderRadius: BorderRadius.circular(8),
          //                     ),
          //                     elevation: 0,
          //                   ).copyWith(
          //                     // atur warna saat hover (web/desktop)
          //                     overlayColor: MaterialStateProperty.resolveWith<
          //                       Color?
          //                     >((Set<MaterialState> states) {
          //                       if (states.contains(MaterialState.hovered)) {
          //                         return Colors.green.shade500.withOpacity(
          //                           0.3,
          //                         ); // hover background hijau muda
          //                       }
          //                       if (states.contains(MaterialState.pressed)) {
          //                         return Colors.green.shade200.withOpacity(
          //                           0.5,
          //                         ); // pressed effect
          //                       }
          //                       return null; // default
          //                     }),
          //                   ),
          //                 ),
          //               ),
          //               const SizedBox(height: 20),
          //             ],
          //           )
          //           : const SizedBox(),
          // ),

          const Text(
            "List Items Adjustment:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Flexible(
            child: Obx(() {
              if (controller.adjustItems.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_center, color: Colors.grey, size: 60),
                      SizedBox(height: 10),
                      Text(
                        'No items added',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ); 
              }
              return ListView.builder(
                controller :_scrollController,
                shrinkWrap: true,
                itemCount: controller.adjustItems.length,
                itemBuilder: (context, index) {
                  final item = controller.adjustItems[index];
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
                          Text(
                            "UOM : ${item["MeasureUnit"]}",
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  // if (qty > 0) {
                                  //   controller.updateadjustItemQuantity(
                                  //     index,
                                  //    (qty - 1).toDouble(),
                                  //   );
                                  // }
                                  if (qty > 0) {
                                    final newQty = (qty - 1).toDouble();
                                    controller.updateadjustItemQuantity(
                                      index,
                                      newQty,
                                    );

                                    // ⬇️ update controller juga
                                    _adjustQtyControllers[index].text =
                                        newQty == 0
                                            ? ''
                                            : newQty.toInt().toString();
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
                                  controller: _adjustQtyControllers[index],

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
                                    controller.updateadjustItemQuantity(
                                      index,
                                      double.tryParse(value) ?? 0,
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final newQty = (qty + 1).toDouble();
                                  controller.updateadjustItemQuantity(
                                    index,
                                    newQty,
                                  );

                                  _adjustQtyControllers[index].text =
                                      newQty.toInt().toString();
                                },
                                // onPressed:
                                //     () => controller.updateadjustItemQuantity(
                                //       index,
                                //       (qty + 1).toDouble(),
                                //     ),
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),

                                // onPressed: () {
                                //   controller.updateadjustItemQuantity(index, 0);
                                //   _adjustQtyControllers[index].text = '';
                                // },
                                onPressed:
                                    () => controller.removeadjustItem(index),
                              ),
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
