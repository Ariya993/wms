import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import '../controllers/item_controller.dart';
import '../controllers/printer_controller.dart';

class ItemPage extends StatelessWidget {
  final ItemController itemController = Get.put(ItemController());
  final PrinterController printerController = Get.put(PrinterController());
  final ScrollController scrollController = ScrollController();

  ItemPage({super.key});

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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemController.searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari item...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Obx(
                        () =>
                            itemController.searchQuery.value.isNotEmpty
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
                SizedBox(
                  height: 48, // tinggi tombol agar terlihat kotak
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // warna latar biru
                      foregroundColor: Colors.white, // warna teks
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ), // padding horizontal
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4), // bentuk kotak
                      ),
                    ),
                    onPressed: () {
                      itemController.searchQuery.value =
                          itemController.searchController.text.trim();
                      itemController.fetchItems();
                    },
                    child: const Text("Cari"),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (itemController.isLoading.value &&
                  itemController.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (itemController.items.isEmpty &&
                  !itemController.isLoading.value) {
                return const Center(child: Text("Tidak ada item ditemukan."));
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
                  }
                  else if (width > 1200) {
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
                        final String itemCode = item['ItemCode'] ?? '';
                        final String itemName = item['ItemName'] ?? '';
                        final int stockOnHand = (item['QuantityOnStock'] ?? 0.0).toInt();
                        final int stockCommitted = (item['QuantityOrderedByCustomers'] ?? 0.0).toInt();

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
                                      itemName.toUpperCase(),
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
                                    padding: const EdgeInsets.all(12),
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
                                            fontSize: 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
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
                                              stockOnHand,
                                              Colors.green[100]!,
                                            ),
                                            _stockRow(
                                              "Stock Committed",
                                              stockCommitted,
                                              Colors.orange[100]!,
                                            ),
                                          ],
                                        ),
                                        const Spacer(), // Pushes the Divider and button to the bottom

                                        const Divider(height: 16, thickness: 1),

                                        // Print Button - Aligned to bottom right
                                        Align(
                                          alignment:
                                              Alignment
                                                  .bottomRight, // Explicitly align to bottom right
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[50],
                                              foregroundColor: Colors.blue,
                                              elevation: 1,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                    vertical: 12,
                                                  ),
                                              side: const BorderSide(
                                                color: Colors.blue,
                                                width: 1,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.print,
                                              size: 18,
                                            ),
                                            label: const Text("Print"),
                                            onPressed: () {
                                              _showPrintDialog(
                                                itemName,
                                                itemCode,
                                              );
                                            },
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
    );
  }

  Widget _stockRow(String title, int value, Color color) {
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

  void _showPrintDialog(String itemName, String itemCode) {
  final qtyController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final previewImage = Rx<Uint8List?>(null);
  final previewHtml = Rx<String?>(null);
  final isLoading = false.obs;

  Get.dialog(
    Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: IntrinsicHeight(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
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

                      // Form
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Item: $itemName",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Masukkan jumlah barcode yang ingin dicetak:",
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Jumlah Cetakan",
                                  hintText: "Contoh: 5",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  final intValue = int.tryParse(value ?? "");
                                  if (intValue == null || intValue <= 0) {
                                    return "Masukkan angka lebih dari 0";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.visibility),
                                label: const Text("Preview"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  minimumSize:
                                      const Size(double.infinity, 45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  if (!formKey.currentState!.validate())
                                    return;

                                  final qty =
                                      int.tryParse(qtyController.text) ?? 1;

                                  isLoading.value = true;
                                  printerController
                                      // .getBarcodeImageFromServer(
                                        .getBarcodeHtmlFromServer(
                                    itemCode: itemCode,
                                    itemName: itemName,
                                    qty: qty,
                                  )
                                      .then((result) {
                                    if (result != null) {
                                       previewHtml.value = result;
                                      // previewImage.value = result;
                                    } else {
                                      Get.snackbar(
                                        "Error",
                                        "Failed to get preview.",
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: Colors.redAccent,
                                        colorText: Colors.white,
                                      );
                                    }
                                   
                                  }).catchError((e) {
                                    Get.snackbar(
                                      "Error",
                                      "Failed to preview: $e",
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: Colors.redAccent,
                                      colorText: Colors.white,
                                    );
                                  }).whenComplete(() {
                                    isLoading.value = false;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              if (isLoading.value)
                                const Center(
                                    child: CircularProgressIndicator())
                              else if (previewImage.value != null)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      previewImage.value!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 1, thickness: 1),

                      // Footer buttons
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Get.back(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                child: const Text(
                                  "Clode",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.print),
                                label: const Text(
                                  "Print",
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                onPressed: () async {
                                  if (previewImage.value == null) {
                                    Get.snackbar(
                                      "Warning",
                                      "Klik 'Preview' first.",
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: Colors.orangeAccent,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  final selected = printerController
                                      .selectedDevice.value;
                                  if (selected == null) {
                                    Get.snackbar(
                                      "Printer",
                                      "Select a printer first.",
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: Colors.orangeAccent,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  // await printerController
                                  //     .printImageFromBytes(
                                  //         previewImage.value!);
                                  Get.back();
                                },
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
          );
        },
      ),
    ),
    barrierDismissible: false,
  );
}

}
