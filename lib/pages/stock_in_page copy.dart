// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/stock_in_controller.dart';
// // import 'package:mobile_scanner/mobile_scanner.dart'; // Hapus impor ini
// import 'package:qr_code_scanner/qr_code_scanner.dart'; // Tambahkan impor ini

// // --- BarcodeScannerPage Baru menggunakan qr_code_scanner ---
// class BarcodeScannerPage extends StatefulWidget {
//   const BarcodeScannerPage({super.key});

//   @override
//   State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
// }

// class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller; // Controller untuk qr_code_scanner
//   bool _isScanned = false; // Flag untuk mencegah multiple scan cepat
//   bool _isFlashOn = false; // State lokal untuk status flash
//   CameraFacing _currentCameraFacing =
//       CameraFacing.back; // State lokal untuk status kamera

//   // Digunakan untuk melanjutkan kamera setelah hot reload (khusus Android)
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (Theme.of(context).platform == TargetPlatform.android) {
//       controller?.pauseCamera();
//     }
//     controller?.resumeCamera();
//   }

//   // Penting: dispose controller untuk mencegah memory leak
//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Scan QR/Barcode',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.blue.shade700,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           // Tombol Torch/Flash
//           IconButton(
//             color: Colors.white,
//             icon: Icon(
//               _isFlashOn ? Icons.flash_on : Icons.flash_off,
//               color: _isFlashOn ? Colors.yellow : Colors.grey,
//             ),
//             iconSize: 26.0,
//             onPressed: () async {
//               await controller?.toggleFlash();
//               // Update state lokal flash berdasarkan status yang dikembalikan toggleFlash
//               setState(() {
//                 _isFlashOn = !_isFlashOn;
//               });
//             },
//           ),
//           // Tombol Switch Camera
//           IconButton(
//             color: Colors.white,
//             icon: Icon(
//               _currentCameraFacing == CameraFacing.front
//                   ? Icons.camera_front
//                   : Icons.camera_rear,
//             ),
//             iconSize: 26.0,
//             onPressed: () async {
//               await controller?.flipCamera();
//               // Update state lokal kamera secara manual karena `flipCamera` tidak reaktif
//               setState(() {
//                 _currentCameraFacing =
//                     (_currentCameraFacing == CameraFacing.front)
//                         ? CameraFacing.back
//                         : CameraFacing.front;
//               });
//             },
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           // Widget scanner utama dari qr_code_scanner
//           _buildQrView(context),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               alignment: Alignment.bottomCenter,
//               height: 80,
//               // color: Colors.black.withOpacity(0.6),
//               child: const Center(
//                 child: Text(
//                   'Arahkan QR/Barcode ke dalam bingkai',
//                   style: TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Method untuk membangun tampilan QR scanner
//   Widget _buildQrView(BuildContext context) {
//     // Ukuran area scan yang akan ditampilkan
//     var scanArea =
//         (MediaQuery.of(context).size.width < 400 ||
//                 MediaQuery.of(context).size.height < 400)
//             ? 300.0
//             : 500.0;
//     return QRView(
//       key: qrKey,
//       onQRViewCreated: _onQRViewCreated,
//       overlay: QrScannerOverlayShape(
//         borderColor: Colors.red,
//         borderRadius: 10,
//         borderLength: 30,
//         borderWidth: 10,
//         cutOutSize: scanArea,
//       ),
//       onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
//     );
//   }

//   // Callback ketika QRView selesai dibuat dan controller tersedia
//   void _onQRViewCreated(QRViewController controller) {
//     setState(() {
//       this.controller = controller;
//     });
//     // Mendengarkan stream data hasil scan
//     controller.scannedDataStream.listen((scanData) {
//       if (!_isScanned) {
//         _isScanned = true; // Set flag untuk mencegah scan ganda
//         if (scanData.code != null && scanData.code!.isNotEmpty) {
//           final String scannedValue = scanData.code!;
//           Get.back(
//             result: scannedValue,
//           ); // Kembali ke halaman sebelumnya dengan hasil
//         } else {
//           _isScanned = false; // Reset flag jika hasil scan kosong
//         }
//       }
//     });

//     // Inisialisasi status flash saat controller pertama kali dibuat
//     controller.getFlashStatus().then((status) {
//       setState(() {
//         _isFlashOn = status ?? false; // Jika null, anggap flash mati
//       });
//     });
//     // Untuk `qr_code_scanner`, kita asumsikan kamera belakang aktif secara default.
//     // Tidak ada API reaktif langsung untuk mengetahui kamera mana yang sedang aktif.
//     _currentCameraFacing = CameraFacing.back;
//   }

//   // Callback untuk menangani izin kamera
//   void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
//     if (!p) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Tidak ada izin untuk mengakses kamera')),
//       );
//     }
//   }
// }

// // Enum sederhana untuk CameraFacing, karena qr_code_scanner tidak menyediakannya langsung
// enum CameraFacing { front, back }

// class StockInPage extends StatefulWidget {
//   const StockInPage({super.key});

//   @override
//   State<StockInPage> createState() => _StockInPageState();
// }

// class _StockInPageState extends State<StockInPage>
//     with TickerProviderStateMixin {
//   final StockInController controller = Get.put(StockInController());
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(
//       length: 2,
//       vsync: this,
//       initialIndex: controller.currentMode.value == StockInMode.poBased ? 0 : 1,
//     );

//     _tabController.addListener(() {
//       if (_tabController.indexIsChanging) return;
//       if (_tabController.index == 0) {
//         controller.setMode(StockInMode.poBased);
//       } else {
//         controller.setMode(StockInMode.nonPo);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _navigateToScanner() async {
//     final result = await Get.to(() => const BarcodeScannerPage());
//     if (result != null && result is String && result.isNotEmpty) {
//       controller.handleScanResult(result);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Stock In", style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade700,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           ElevatedButton.icon(
//             onPressed: () {
//               if (controller.currentMode.value == StockInMode.poBased) {
//                 controller.submitPoGoodsReceipt();
//               } else {
//                 controller.submitNonPoGoodsReceipt();
//               }
//             },
//             icon: const Icon(Icons.save),
//             label: Obx(
//               () => Text(
//                 controller.currentMode.value == StockInMode.poBased
//                     ? "Submit"
//                     : "Submit",
//                 style: const TextStyle(fontSize: 14),
//               ),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.white,
//               foregroundColor: Colors.blue,
//               elevation: 0,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         return TabBarView(
//           controller: _tabController,
//           children: [_buildPoBasedForm(context), _buildNonPoForm(context)],
//         );
//       }),
//       bottomNavigationBar: SizedBox(
//         height: 42, // <--- atur tinggi eksplisit yang kecil
//         child: Material(
//           color: Colors.blue.shade50,
//           elevation: 6,
//           child: TabBar(
//             controller: _tabController,
//             indicator: BoxDecoration(
//               color: Colors.blue.shade300,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             indicatorPadding: EdgeInsets.zero,
//             labelPadding: EdgeInsets.zero,
//             padding: EdgeInsets.zero,
//             indicatorSize: TabBarIndicatorSize.tab,
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.blueGrey.shade500,
//             labelStyle: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//             ),
//             unselectedLabelStyle: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//             ),
//             tabs: const [Tab(text: "PO Based"), Tab(text: "Non-PO")],
//             //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // <- ini menghapus padding default
//           ),
//         ),
//       ),

//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _navigateToScanner,
//         label: const Text("Scan QR/Barcode"),
//         icon: const Icon(Icons.qr_code_scanner),
//         backgroundColor: Colors.blue.shade600,
//         foregroundColor: Colors.white,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }

//   // FORM PO
//   Widget _buildPoBasedForm(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0), // ✅ Tambahkan padding di sini
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: controller.poNumberController,
//                   decoration: InputDecoration(
//                     labelText: "PO Number",
//                     hintText: "Enter Purchase Order Number",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     prefixIcon: const Icon(Icons.receipt_long),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton.icon(
//                 onPressed: controller.searchPo,
//                 icon: const Icon(Icons.search),
//                 label: const Text("Search PO"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue.shade500,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Obx(() {
//             if (controller.purchaseOrder.value == null) {
//               return const Center(
//                 child: Text(
//                   "Search a Purchase Order to view items.",
//                   style: TextStyle(color: Colors.grey, fontSize: 16),
//                 ),
//               );
//             }
//             final po = controller.purchaseOrder.value!;
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "PO Details: ${po.docNum}",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text("Vendor: ${po.cardName} (${po.cardCode})"),
//                 Text("Date: ${po.docDate.toLocal().toString().split(' ')[0]}"),
//                 const SizedBox(height: 10),
//                 const Divider(),
//                 const Text(
//                   "Items to Receive:",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 10),
//                 // ✅ Expanded dipindah ke atas _jika_ ini berada dalam layout scrollable
//                 ListView.builder(
//                   shrinkWrap:
//                       true, // Tambah ini agar tidak conflict dengan Column
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: controller.poItems.length,
//                   itemBuilder: (context, index) {
//                     final item = controller.poItems[index];
//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       elevation: 2,
//                       child: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "${item.itemName} (${item.itemCode})",
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               "Ordered: ${item.orderedQuantity} | Received: ${item.receivedQuantity} | Open: ${item.openQuantity}",
//                             ),
//                             const SizedBox(height: 8),
//                             TextField(
//                               controller: TextEditingController(
//                                 text:
//                                     item.currentReceivedQuantity == 0.0
//                                         ? ''
//                                         : item.currentReceivedQuantity
//                                             .toStringAsFixed(2),
//                               ),
//                               decoration: InputDecoration(
//                                 labelText: "Receive Quantity",
//                                 hintText: "Enter quantity to receive",
//                                 border: const OutlineInputBorder(),
//                                 suffixIcon: IconButton(
//                                   icon: const Icon(Icons.clear),
//                                   onPressed: () {
//                                     controller.updatePoItemQuantity(index, 0.0);
//                                   },
//                                 ),
//                               ),
//                               keyboardType:
//                                   const TextInputType.numberWithOptions(
//                                     decimal: true,
//                                   ),
//                               onChanged: (value) {
//                                 controller.updatePoItemQuantity(
//                                   index,
//                                   double.tryParse(value) ?? 0.0,
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildNonPoForm(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),

//           // 🔽 Header Collapse
//           GestureDetector(
//             onTap: () => controller.isNonPoExpanded.toggle(),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     "Form Penerimaan Non-PO",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue.shade700,
//                     ),
//                   ),
//                 ),
//                 Obx(
//                   () => Icon(
//                     controller.isNonPoExpanded.value
//                         ? Icons.expand_less
//                         : Icons.expand_more,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           // 🔁 Input Item (collapsable)
//           Obx(
//             () =>
//                 controller.isNonPoExpanded.value
//                     ? Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextField(
//                           controller: controller.nonPoItemCodeController,
//                           decoration: InputDecoration(
//                             labelText: "Item Code",
//                             hintText: "Enter Item Code",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             prefixIcon: const Icon(Icons.qr_code),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         TextField(
//                           controller: controller.nonPoItemNameController,
//                           decoration: InputDecoration(
//                             labelText: "Item Name",
//                             hintText: "Enter Item Name",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             prefixIcon: const Icon(Icons.abc),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         TextField(
//                           controller: controller.nonPoQuantityController,
//                           decoration: InputDecoration(
//                             labelText: "Quantity",
//                             hintText: "Enter Quantity",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             prefixIcon: const Icon(
//                               Icons.production_quantity_limits,
//                             ),
//                           ),
//                           keyboardType: const TextInputType.numberWithOptions(
//                             decimal: true,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton.icon(
//                             onPressed: controller.addNonPoItem,
//                             icon: const Icon(Icons.add_shopping_cart),
//                             label: const Text("Add Item to List"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green.shade500,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     )
//                     : const SizedBox(),
//           ),

//           // 🔹 Selalu tampil: List items
//           const Text(
//             "Items to Receive (Non-PO):",
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),

//           // Gunakan Flexible supaya aman di dalam Column
//           Flexible(
//             child: Obx(() {
//               if (controller.nonPoItems.isEmpty) {
//                 return const Center(
//                   child: Text(
//                     "No items added yet.",
//                     style: TextStyle(color: Colors.grey, fontSize: 16),
//                   ),
//                 );
//               }
//               return ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: controller.nonPoItems.length,
//                 itemBuilder: (context, index) {
//                   final item = controller.nonPoItems[index];
//                   return Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     elevation: 2,
//                     child: Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "${item.itemName} (${item.itemCode})",
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 TextField(
//                                   controller: TextEditingController(
//                                     text:
//                                         item.currentReceivedQuantity == 0.0
//                                             ? ''
//                                             : item.currentReceivedQuantity
//                                                 .toStringAsFixed(2),
//                                   ),
//                                   decoration: const InputDecoration(
//                                     labelText: "Quantity",
//                                     border: OutlineInputBorder(),
//                                     isDense: true,
//                                     contentPadding: EdgeInsets.symmetric(
//                                       vertical: 8,
//                                       horizontal: 12,
//                                     ),
//                                   ),
//                                   keyboardType:
//                                       const TextInputType.numberWithOptions(
//                                         decimal: true,
//                                       ),
//                                   onChanged: (value) {
//                                     controller.updateNonPoItemQuantity(
//                                       index,
//                                       double.tryParse(value) ?? 0.0,
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () => controller.removeNonPoItem(index),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
// }
