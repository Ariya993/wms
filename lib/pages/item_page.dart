import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/item_controller.dart';
// import '../controllers/print_qr_web_controller.dart';
// import '../helper/print_qr_stub.dart';
import '../controllers/printer_controller.dart';
import '../controllers/print_qr_controller.dart';
import '../widgets/loading.dart';
import 'scanner.dart';

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> with TickerProviderStateMixin {
  final ItemController itemController = Get.put(ItemController());
  final PrinterController printerController = Get.put(PrinterController());
  final ScrollController scrollController = ScrollController();
  final printQRController = PrintQRController();
  final box = GetStorage();
  // ItemPage({super.key});
  @override
  void initState() {
    super.initState();
  }

  Future<void> _navigateToScanner() async {
    final result = await Get.to(() => const BarcodeScannerPage());
    if (result != null && result is String && result.isNotEmpty) {
      itemController.searchQuery.value = result.trim();
      itemController.scanItems(); //fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !itemController.isLoadingMore.value &&
          !itemController.isLoading.value &&
          itemController.hasMore.value) {
        itemController.fetchItems(isLoadMore: true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Items'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white, // ✅ Background biru
      ),

      body: Column(
        children: [
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
  child: Row(
    children: [
      Expanded(
        child: TextField(
          controller: itemController.searchController,
          decoration: InputDecoration(
            hintText: 'Cari item...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Obx(
              () => itemController.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        itemController.searchController.clear();
                        itemController.searchQuery.value = '';
                        itemController.resetItems();
                      },
                    )
                  : const SizedBox(),
            ),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            itemController.searchQuery.value = value.trim();
            itemController.fetchItems();
          },
        ),
      ),
      const SizedBox(width: 8),

      // 👇 Tambahkan filter type
      

      SizedBox(
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () {
            itemController.searchQuery.value =
                itemController.searchController.text.trim();
            itemController.fetchItems();
          },
          child: const Text("Search"),
        ),
      ),
    ],
  ),
),

          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: TextField(
          //           controller: itemController.searchController,
          //           decoration: InputDecoration(
          //             hintText: 'Cari item...',
          //             prefixIcon: const Icon(Icons.search),
          //             suffixIcon: Obx(
          //               () =>
          //                   itemController.searchQuery.value.isNotEmpty
          //                       ? IconButton(
          //                         icon: const Icon(Icons.clear),
          //                         onPressed: () {
          //                           itemController.searchController.clear();
          //                           itemController.searchQuery.value = '';
          //                           itemController.resetItems();
          //                         },
          //                       )
          //                       : const SizedBox(),
          //             ),
          //             border: const OutlineInputBorder(),
          //           ),
          //           onSubmitted: (value) {
          //             itemController.searchQuery.value = value.trim();
          //             itemController.fetchItems();
          //           },
          //         ),
          //       ),

          //       const SizedBox(width: 8),
          //       SizedBox(
          //         height: 48, // tinggi tombol agar terlihat kotak
          //         child: ElevatedButton(
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.blue, // warna latar biru
          //             foregroundColor: Colors.white, // warna teks
          //             padding: const EdgeInsets.symmetric(
          //               horizontal: 20,
          //             ), // padding horizontal
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(4), // bentuk kotak
          //             ),
          //           ),
          //           onPressed: () {
          //             itemController.searchQuery.value =
          //                 itemController.searchController.text.trim();
          //             itemController.fetchItems();
          //           },
          //           child: const Text("Cari"),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(width: 8),

          // Padding(
          //   padding: const EdgeInsets.only(right: 16.0), // tambahkan ini
          //   child: Align(
          //     alignment: Alignment.centerRight,

          //     child: Obx(() {
          //       final warehouses = itemController.selectedWarehouses.toList();

          //       if (warehouses.isEmpty) return const SizedBox();

          //       return GestureDetector(
          //         onTapDown: (details) {
          //           final Offset offset = details.globalPosition;
          //           final double dx =
          //               offset.dx + MediaQuery.of(context).size.width;
          //           final double dy = offset.dy;

          //           showMenu(
          //             context: context,
          //             position: RelativeRect.fromLTRB(dx, dy, 0, 0),
          //             items: [
          //               PopupMenuItem<String>(
          //                 enabled: false,
          //                 padding:
          //                     EdgeInsets.zero, // Hindari padding default item
          //                 child: Obx(
          //                   () => Material(
          //                     color: Colors.white, // 💥 Material putih solid
          //                     child: Column(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         TextField(
          //                           style: const TextStyle(
          //                             fontSize: 16,
          //                           ), // ukuran teks lebih besar
          //                           decoration: const InputDecoration(
          //                             hintText: 'Cari warehouse...',
          //                             fillColor: Colors.white,
          //                             border: OutlineInputBorder(),
          //                             isDense: true, // rapat tapi tetap nyaman
          //                             contentPadding: EdgeInsets.symmetric(
          //                               horizontal: 12,
          //                               vertical:
          //                                   12, // padding lebih luas secara vertikal
          //                             ),
          //                           ),
          //                           onChanged:
          //                               (value) => itemController
          //                                   .filterWarehouseSearch(value),
          //                         ),

          //                         const SizedBox(height: 8),
          //                         SizedBox(
          //                           height: 350,
          //                           width: 200,
          //                           child: ListView(
          //                             shrinkWrap: true,
          //                             children:
          //                                 itemController.filteredWarehouseList.map((
          //                                   w,
          //                                 ) {
          //                                   final name =
          //                                       itemController
          //                                           .warehouseCodeNameMap[w] ??
          //                                       w; // cari nama
          //                                   return ListTile(
          //                                     title: Text(
          //                                       name,
          //                                     ), // ✅ tampilkan nama gudangnya
          //                                     tileColor: Colors.white,
          //                                     textColor: Colors.black,
          //                                     onTap: () {
          //                                       itemController
          //                                           .selectedWarehouseFilter
          //                                           .value = w;
          //                                       itemController.resetItems();
          //                                       Navigator.pop(context);
          //                                     },
          //                                   );
          //                                 }).toList(),
          //                           ),
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           );
          //         },
          //         child: Container(
          //           padding: const EdgeInsets.symmetric(
          //             horizontal: 12,
          //             vertical: 14,
          //           ),
          //           decoration: BoxDecoration(
          //             border: Border.all(color: Colors.grey.shade400),
          //             borderRadius: BorderRadius.circular(6),
          //           ),
          //           child: Row(
          //             mainAxisSize: MainAxisSize.min,

          //             children: [
          //               Text(
          //                 itemController.selectedWarehouseFilter.value.isEmpty
          //                     ? 'Warehouse'
          //                     : itemController
          //                             .warehouseCodeNameMap[itemController
          //                             .selectedWarehouseFilter
          //                             .value] ??
          //                         'Warehouse',
          //                 style: const TextStyle(
          //                   fontSize: 14,
          //                   fontWeight: FontWeight.w500,
          //                 ),
          //               ),

          //               const Icon(Icons.arrow_drop_down),
          //             ],
          //           ),
          //         ),
          //       );
          //     }),
          //   ),
          // ),
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      /// 🔽 Filter Type (Like / Equals)
      Obx(() => PopupMenuButton<String>(
            onSelected: (value) {
              itemController.filterType.value = value;
              itemController.resetItems(); // Optional: reset item jika diperlukan
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "like",
                child: Text("Like"),
              ),
              const PopupMenuItem(
                value: "equals",
                child: Text("Equals"),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    itemController.filterType.value.capitalizeFirst ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const Icon(Icons.filter_list, color: Colors.grey),
                ],
              ),
            ),
          )),

      const SizedBox(width: 8),

      /// 🏢 Warehouse Dropdown
      Obx(() {
        final warehouses = itemController.selectedWarehouses.toList();

        if (warehouses.isEmpty) return const SizedBox();

        return GestureDetector(
          onTapDown: (details) {
            final Offset offset = details.globalPosition;
            final double dx =
                offset.dx + MediaQuery.of(context).size.width;
            final double dy = offset.dy;

            showMenu(
              context: context,
              position: RelativeRect.fromLTRB(dx, dy, 0, 0),
              items: [
                PopupMenuItem<String>(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: Obx(
                    () => Material(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Cari warehouse...',
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) => itemController
                                .filterWarehouseSearch(value),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 350,
                            width: 200,
                            child: ListView(
                              shrinkWrap: true,
                              children: itemController.filteredWarehouseList.map(
                                (w) {
                                  final name = itemController
                                          .warehouseCodeNameMap[w] ??
                                      w;
                                  return ListTile(
                                    title: Text(name),
                                    tileColor: Colors.white,
                                    textColor: Colors.black,
                                    onTap: () {
                                      itemController
                                          .selectedWarehouseFilter.value = w;
                                      itemController.resetItems();
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  itemController.selectedWarehouseFilter.value.isEmpty
                      ? 'Warehouse'
                      : itemController.warehouseCodeNameMap[
                              itemController.selectedWarehouseFilter.value] ??
                          'Warehouse',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      }),
    ],
  ),
),

          Expanded(
            child: Obx(() {
              if (itemController.isLoading.value &&
                  itemController.items.isEmpty) {
                // return const Center(child: CircularProgressIndicator());
                return const Loading();
              }

              if (itemController.items.isEmpty &&
                  !itemController.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, color: Colors.grey, size: 60),
                      SizedBox(height: 10),
                      Text(
                        'No data Item.',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                );
                // return const Center(child: Text("Tidak ada item ditemukan."));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  // Dynamic crossAxisCount and childAspectRatio for fluid GridView layout
                  int crossAxisCount;
                  double childAspectRatio;
                  if (width > 1800) {
                    crossAxisCount = 6;
                    childAspectRatio = 1.0;
                  } else if (width > 1200) {
                    crossAxisCount = 4;
                    childAspectRatio = 1.0;
                  } else if (width > 800) {
                    crossAxisCount = 3;
                    childAspectRatio = 1.1;
                  } else if (width > 600) {
                    crossAxisCount = 2;
                    childAspectRatio = 1.3;
                  } else {
                    crossAxisCount = 1;
                    childAspectRatio = 1.2;
                  }

                  return GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount:
                        itemController.items.length +
                        (itemController.hasMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < itemController.items.length) {
                        final item = itemController.items[index];
                        final String warehouseCode =
                            item['WarehouseCode'] ?? '';
                        final String warehouseName =
                            item['WarehouseName'] ?? '';
                        final String itemCode = item['ItemCode'] ?? '';
                        final String itemName = item['ItemName'] ?? '';
                        final String? binLoc = item['lokasi'] ?? '-';
                        final int stockOnHand =
                            (item['InStock'] ?? 0.0).toInt();
                        final int stockCommitted =
                            (item['Committed'] ?? 0.0).toInt();
                        final int stockOrdered =
                            (item['Ordered'] ?? 0.0).toInt();

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
                              print('Card tapped for ${itemCode}');
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card Header
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$warehouseCode - ${warehouseName.toUpperCase()}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                // Card Content
                                Expanded(
                                  // ✅ Expanded to allow flexible content height
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween, // Distribute space
                                      children: [
                                        // Item Code and Name (can take multiple lines if needed)
                                        Text(
                                          "$itemCode - $itemName",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2, // Allow up to 2 lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),

                                        // Stock Rows - Using Wrap for horizontal fluidity
                                        // If there's enough space, they'll be side by side
                                        // If not, they'll wrap to the next line.
                                        Wrap(
                                          spacing:
                                              12, // Horizontal space between items
                                          runSpacing:
                                              4, // Vertical space between lines if wrapped
                                          children: [
                                            _stockRow(
                                              "Stock On Hand",
                                              stockOnHand.toString(),
                                              Colors.green[100]!,
                                            ),
                                            _stockRow(
                                              "Stock Committed",
                                              stockCommitted.toString(),
                                              Colors.orange[100]!,
                                            ),
                                            _stockRow(
                                              "Stock Ordered",
                                              stockOrdered.toString(),
                                              Colors.blue[100]!,
                                            ),
                                            _stockRow(
                                              "Bin Location",
                                              binLoc.toString().toUpperCase(),
                                              Colors.blueGrey[100]!,
                                            ),
                                          ],
                                        ),
                                        const Spacer(), // Pushes the Divider and button to the bottom

                                        const Divider(height: 16, thickness: 1),

                                        // Print Button - Aligned to bottom right
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton.icon(
                                                icon: const Icon(
                                                  Icons.edit_location_alt,
                                                  size: 18,
                                                ),
                                                label: const Text("Edit Bin"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.orange[50],
                                                  foregroundColor:
                                                      Colors.orange[800],
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                  side: const BorderSide(
                                                    color: Colors.orange,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  _showEditLokasiDialog(
                                                    item['ItemCode'],
                                                    item['WarehouseCode'],
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                icon: const Icon(
                                                  Icons.print,
                                                  size: 18,
                                                ),
                                                label: const Text("Print"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue[50],
                                                  foregroundColor:
                                                      Colors.blue[700],
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                  side: const BorderSide(
                                                    color: Colors.blue,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  _showPrintTypeDialog(
                                                    item['ItemName'] ?? '',
                                                    item['ItemCode'] ?? '',
                                                    item['lokasi'] ??
                                                        '', // lokasi BIN (kalau ada)
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Obx(
                          () =>
                              itemController.isLoadingMore.value
                                  ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                  : const SizedBox(),
                        );
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
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

  Widget _stockRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(value.toString(), style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showEditLokasiDialog(String? itemCode, String? warehouseCode) {
    final TextEditingController lokasiController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Update Bin",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lokasiController,
                  decoration: const InputDecoration(
                    labelText: "New Bin Location",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Input Location";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => Get.back(),
                        child: const Text("Close"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        label: const Text("Update"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final success = await itemController
                                .updateBinLocation(
                                  itemCode: itemCode ?? '',
                                  warehouseCode: warehouseCode ?? '',
                                  lokasiBaru: lokasiController.text.trim(),
                                );
                            if (success) {
                              Get.back(); // Tutup dialog input lokasi

                              Get.snackbar(
                                "Success",
                                "Bin loccation updated",
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                              // Delay sedikit biar snackbar muncul dulu
                              await Future.delayed(Duration(milliseconds: 300));
                            } else {
                              Get.back();
                              Get.snackbar(
                                "Failed",
                                "Failed to update bin location",
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              await Future.delayed(Duration(milliseconds: 300));
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showPrintTypeDialog(
    String itemName,
    String itemCode,
    String lokasiBin,
  ) {
    Get.defaultDialog(
      title: "QR Type",
      middleText: "",
      radius: 5,
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code),
          label: const Text("QR Item"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Get.back(); // tutup dialog
            _showPrintDialog(itemName, itemCode); // QR Item normal
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.location_on),
          label: const Text("QR Bin"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (lokasiBin.trim().isEmpty) {
              Get.snackbar(
                "Invalid",
                "Bin Location is not valid area",
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }
            Get.back(); // tutup dialog
            _showPrintDialog(lokasiBin, lokasiBin); // QR Bin
          },
        ),
      ],
    );
  }

  void _showPrintDialog(String itemName, String itemCode) {
    final qtyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // final previewHtml = Rx<String?>(null);
    final previewHtml = Rx<Uint8List?>(null);
    final previewImage = Rx<Uint8List?>(null);
    final isLoading = false.obs;

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Obx(
          () => SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      "Preview & Print QR",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Text(
                          itemName == itemCode
                              ? "Bin: $itemName"
                              : "Item: $itemName",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Total Print Out",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            final intValue = int.tryParse(value ?? "");
                            if (intValue == null || intValue <= 0) {
                              return "please fill qty";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: printerController.widthController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Width (cm)",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  final val = double.tryParse(value ?? "");
                                  if (val == null || val <= 0) {
                                    return "Fill the width";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: printerController.heightController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Height (cm)",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  final val = double.tryParse(value ?? "");
                                  if (val == null || val <= 0) {
                                    return "Fill the height";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.visibility),
                          label: const Text("Preview"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final qty = int.tryParse(qtyController.text) ?? 1;

                            // Simpan ke GetStorage

                            isLoading.value = true;

                            final htmlResult = await printerController
                                .getBarcodeImageFromServer(
                                  itemCode: itemCode,
                                  itemName: itemName,
                                  qty: qty,
                                  cmWidth: double.parse(
                                    printerController.widthController.text,
                                  ),
                                  cmHeight: double.parse(
                                    printerController.heightController.text,
                                  ),
                                );

                            if (htmlResult != null) {
                              previewHtml.value = htmlResult;
                              // if (kIsWeb) {
                              //      buildWebIframe(previewHtml.value!);
                              //   }
                            } else {
                              Get.snackbar(
                                "Error",
                                "Failed to generate preview",
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }

                            isLoading.value = false;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (isLoading.value)
                          // const Center(child: CircularProgressIndicator())
                          const Loading()
                        else if (previewHtml.value != null)
                          Container(
                            height: 400,
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  previewHtml.value!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(14),
                          ),
                          child: const Text("Close"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final qty = int.tryParse(qtyController.text) ?? 1;

                            // Simpan ke GetStorage

                            isLoading.value = true;

                            final htmlResult = await printerController
                                .getBarcodeImageFromServer(
                                  itemCode: itemCode,
                                  itemName: itemName,
                                  qty: qty,
                                  cmWidth: double.parse(
                                    printerController.widthController.text,
                                  ),
                                  cmHeight: double.parse(
                                    printerController.heightController.text,
                                  ),
                                );

                            if (htmlResult != null) {
                              previewHtml.value = htmlResult;
                            }
                            if (previewHtml.value == null) {
                              Get.snackbar(
                                "Warning",
                                "Pleas click preview first.",
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            if (kIsWeb) {
                              printQRController.printImageWeb(
                                previewHtml.value!,
                              );
                            } else if (Platform.isAndroid) {
                              //await printerController.printHtml(previewHtml.value.toString());
                              printerController.printQR(previewHtml.value!);
                            }

                            // printImage(previewHtml.value!);

                            Get.back();
                          },
                          icon: const Icon(Icons.print),
                          label: const Text("Print"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void showWarehouseFilterMenu(BuildContext context, Offset offset) {
    final controller = itemController;
    controller.filteredWarehouseList.assignAll(controller.selectedWarehouses);

    showDialog(
      context: context,
      barrierColor: Colors.white,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari warehouse...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged:
                            (value) =>
                                itemController.filterWarehouseSearch(value),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Container(
                          color: Colors.white,
                          constraints: const BoxConstraints(maxHeight: 380),
                          child: ListView.builder(
                            itemCount:
                                itemController.filteredWarehouseList.length,
                            itemBuilder: (_, index) {
                              final w =
                                  itemController.filteredWarehouseList[index];
                              return InkWell(
                                // onTap: () {
                                //   itemController.selectedWarehouseFilter.value =
                                //       w;
                                //   itemController.resetItems();
                                //   Navigator.pop(context);
                                // },
                                onTap: () {
                                  itemController.selectedWarehouseFilter.value =
                                      w;
                                  itemController.resetItems();
                                  Navigator.pop(context);
                                },

                                hoverColor: Colors.blue.withOpacity(0.1),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Text(
                                    w,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showWarehouseFilterBottomSheet(BuildContext context) {
    final itemController = Get.find<ItemController>();
    itemController.filteredWarehouseList.assignAll(
      itemController.selectedWarehouses,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 500,
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Cari warehouse...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged:
                      (value) => itemController.filterWarehouseSearch(value),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(
                    () => ListView.builder(
                      itemCount: itemController.filteredWarehouseList.length,
                      itemBuilder: (_, index) {
                        final code =
                            itemController.filteredWarehouseList[index];
                        final name =
                            itemController.warehouseCodeNameMap[code] ?? code;
                        return ListTile(
                          title: Text(name),
                          onTap: () {
                            itemController.selectedWarehouseFilter.value = code;
                            itemController.resetItems();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
