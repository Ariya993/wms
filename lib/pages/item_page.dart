import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/item_controller.dart';
// import '../controllers/print_qr_web_controller.dart';
// import '../helper/print_qr_stub.dart';
import '../controllers/printer_controller.dart';
import '../controllers/print_qr_controller.dart';
import '../widgets/loading.dart';

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

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage>
    with TickerProviderStateMixin {
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
                      itemController.fetchItems();
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
                // return const Center(child: CircularProgressIndicator());
                return const Loading();
              }

              if (itemController.items.isEmpty &&
                  !itemController.isLoading.value) {
                 return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory,
                          color: Colors.grey,
                          size: 60,
                        ),
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
                                                label: const Text(
                                                  "Edit Bin",
                                                ),
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
                                                  icon: const Icon(Icons.print, size: 18),
                                                  label: const Text("Print"),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blue[50],
                                                    foregroundColor: Colors.blue[700],
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                    side: const BorderSide(color: Colors.blue),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    _showPrintTypeDialog(
                                                      item['ItemName'] ?? '',
                                                      item['ItemCode'] ?? '',
                                                      item['lokasi'] ?? '', // lokasi BIN (kalau ada)
                                                    );
                                                  },
                                                ),

                                              // ElevatedButton.icon(
                                              //   icon: const Icon(
                                              //     Icons.print,
                                              //     size: 18,
                                              //   ),
                                              //   label: const Text("Print"),
                                              //   style: ElevatedButton.styleFrom(
                                              //     backgroundColor:
                                              //         Colors.blue[50],
                                              //     foregroundColor:
                                              //         Colors.blue[700],
                                              //     padding:
                                              //         const EdgeInsets.symmetric(
                                              //           horizontal: 14,
                                              //           vertical: 10,
                                              //         ),
                                              //     side: const BorderSide(
                                              //       color: Colors.blue,
                                              //     ),
                                              //     shape: RoundedRectangleBorder(
                                              //       borderRadius:
                                              //           BorderRadius.circular(
                                              //             10,
                                              //           ),
                                              //     ),
                                              //   ),
                                              //   onPressed: () {
                                              //     _showPrintDialog(
                                              //       item['ItemName'],
                                              //       item['ItemCode'],
                                              //     );
                                              //   },
                                              // ),
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
                           final success = await itemController.updateBinLocation(
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
void _showPrintTypeDialog(String itemName, String itemCode, String lokasiBin) {
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
                          itemName == itemCode ? "Bin: $itemName" : "Item: $itemName",
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
}
