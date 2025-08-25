// lib/screens/picklist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/picklist_controller.dart';
import '../helper/format.dart';
import 'scanner.dart';

class PicklistDetailPage extends StatelessWidget {
  final bool isViewOnly;

  PicklistDetailPage({super.key, this.isViewOnly = false});

  final PicklistController controller = Get.find<PicklistController>();
  Future<void> _navigateToScanner() async {
    final result = await Get.to(() => const BarcodeScannerPage());
    if (result != null && result is String && result.isNotEmpty) {
      // print(result);
      controller.processScannedItem(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            // Pastikan akses menggunakan .value
            controller.currentProcessingPicklist.value != null
                ? 'Pick List: ${controller.currentProcessingPicklist.value!['Name']}'
                : 'Pick List Detail',
          ),
        ),
        actions:
            isViewOnly
                ? null
                : [
                  TextButton.icon(
                    onPressed: () {
                      if (controller.currentProcessingPicklist.value != null) {
                        _navigateToScanner();
                      } else {
                        Get.snackbar(
                          'Error',
                          'Please select a picklist first.',
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text(
                      'Scan QR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ), // 🔍 Lebih lega
                    ),
                  ),
                ],
      ),
      body: Obx(() {
        final picklist = controller.currentProcessingPicklist.value;
        if (picklist == null) {
          return const Center(child: Text('No picklist selected.'));
        }

        final List<dynamic> picklistLines = picklist['DocumentLine'] ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick Date: ${format.formatPickDate(picklist['PickDate'])}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Remarks: ${picklist['Remarks']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Status: ${isViewOnly ? 'Closed' : 'Released'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isViewOnly ? Colors.red : Colors.green,
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Items in Pick List:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: picklistLines.length,
                itemBuilder: (context, lineIndex) {
                  final line = picklistLines[lineIndex];
                  final double releasedQty =
                      line['ReleasedQuantity']?.toDouble() ?? 0.0;
                  final double newPicked =
                      line['NewPickedQty']?.toDouble() ??
                      (line['PickedQuantity']?.toDouble() ?? 0);
                  final double pickedQty =
                      line['PickedQuantity']?.toDouble() ?? 0.0;
                  final double orderQty =
                      line['PreviouslyReleasedQuantity']?.toDouble() ?? 0.0;
                  final double stockOnHand =
                      double.tryParse(
                        line['StockOnHand']?.toString() ?? '0.0',
                      ) ??
                      0.0;
                  final double displayQty = newPicked;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER TITLE
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.shade400,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${line['ItemName']} (${line['ItemCode']})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Doc No: ${line['DocNum'] ?? '-'}  - Doc Date: ${format.formatPickDate(line['DocDate'])}',
                              ),
                              Text('Bin Loc: ${line['Bin_Loc'] ?? '-'}'),
                              Text(
                                'Stock On Hand: ${stockOnHand.toStringAsFixed(0)}',
                              ),
                              Text(
                                'Qty Order: ${orderQty.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              Text(
                                'Qty Picked: ${pickedQty.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                              Text(
                                'Qty Release: ${releasedQty.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.orange),
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  const Text('Picked Qty: '),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap:
                                        isViewOnly
                                            ? null
                                            : () {
                                              controller.updatePickedQuantity(
                                                lineIndex,
                                                newPicked - 1,
                                              );
                                            },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            isViewOnly
                                                ? Colors.grey[200]
                                                : Colors.blue[700],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 20,
                                        color:
                                            isViewOnly
                                                ? Colors.grey[600]
                                                : Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: newPicked.toStringAsFixed(0),
                                      ),
                                      textAlign: TextAlign.center,
                                      onChanged:
                                          isViewOnly
                                              ? null
                                              : (value) {
                                                controller.updatePickedQuantity(
                                                  lineIndex,
                                                  double.tryParse(value) ?? 0.0,
                                                );
                                              },
                                      readOnly: isViewOnly,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            isViewOnly
                                                ? Colors.grey[100]
                                                : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap:
                                        isViewOnly
                                            ? null
                                            : () {
                                              controller.updatePickedQuantity(
                                                lineIndex,
                                                newPicked + 1,
                                              );
                                            },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            isViewOnly
                                                ? Colors.grey[200]
                                                : Colors.blue[700],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color:
                                            isViewOnly
                                                ? Colors.grey[600]
                                                : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  // return Card(
                  //   margin: const EdgeInsets.symmetric(
                  //     vertical: 4,
                  //     horizontal: 16,
                  //   ),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(12.0),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           'Item: ${line['ItemName']} (${line['ItemCode']})',
                  //           style: const TextStyle(fontWeight: FontWeight.bold),
                  //         ),
                  //         Text(
                  //           'Doc No: ${line['DocNum'] ?? '-'}  - Doc Date: ${format.formatPickDate(line['DocDate'])}',
                  //         ),
                  //         Text('Bin Loc: ${line['Bin_Loc'] ?? '-'}'),
                  //         Text(
                  //           'Stock On Hand: ${stockOnHand.toStringAsFixed(0)}',
                  //         ),
                  //         Text(
                  //           'Qty Order: ${orderQty.toStringAsFixed(0)}',
                  //           style: const TextStyle(color: Colors.blue),
                  //         ),
                  //         Text(
                  //           'Qty Picked: ${pickedQty.toStringAsFixed(0)}',
                  //           style: const TextStyle(color: Colors.green),
                  //         ),
                  //         Text(
                  //           'Qty Release: ${releasedQty.toStringAsFixed(0)}',
                  //           style: const TextStyle(color: Colors.orange),
                  //         ),

                  //         const Divider(),
                  //         Row(
                  //           children: [
                  //             const Text('Picked Qty: '),
                  //             const SizedBox(width: 8), // Sedikit spasi
                  //             // Tombol Kurang (-)
                  //             InkWell(
                  //               onTap:
                  //                   isViewOnly
                  //                       ? null
                  //                       : () {
                  //                         double newQty = pickedQty - 1.0;
                  //                         controller.updatePickedQuantity(
                  //                           lineIndex,
                  //                           newQty,
                  //                         );
                  //                       },
                  //               child: Container(
                  //                 padding: const EdgeInsets.all(8),
                  //                 decoration: BoxDecoration(
                  //                   color:
                  //                       isViewOnly
                  //                           ? Colors.grey[200]
                  //                           : Colors.blue[700], // Warna tombol
                  //                   borderRadius: BorderRadius.circular(8),
                  //                 ),
                  //                 child: Icon(
                  //                   Icons.remove,
                  //                   size: 20,
                  //                   color:
                  //                       isViewOnly
                  //                           ? Colors.grey[600]
                  //                           : Colors.white,
                  //                 ),
                  //               ),
                  //             ),
                  //             const SizedBox(
                  //               width: 8,
                  //             ), // Spasi antara tombol dan input
                  //             // Input Kuatitas (TextField tetap ada tapi dengan lebar yang diatur)
                  //             Expanded(
                  //               // Expanded agar TextField mengambil sisa ruang
                  //               child: TextField(
                  //                 keyboardType: TextInputType.number,
                  //                 controller: TextEditingController(
                  //                   text:displayQty.toStringAsFixed(0), //pickedQty.toStringAsFixed(0),
                  //                 ),
                  //                 textAlign:
                  //                     TextAlign
                  //                         .center, // Pusatkan teks di TextField
                  //                 onChanged:
                  //                     isViewOnly
                  //                         ? null
                  //                         : (value) {
                  //                           double newQty =
                  //                               double.tryParse(value) ?? 0.0;
                  //                           controller.updatePickedQuantity(
                  //                             lineIndex,
                  //                             newQty,
                  //                           );
                  //                         },
                  //                 readOnly: isViewOnly,
                  //                 style: TextStyle(
                  //                   color:
                  //                       isViewOnly
                  //                           ? Colors.grey[600]
                  //                           : Colors.grey[800],
                  //                   fontWeight: FontWeight.w500,
                  //                 ),
                  //                 decoration: InputDecoration(
                  //                   isDense: true,
                  //                   filled: true,
                  //                   fillColor:
                  //                       isViewOnly
                  //                           ? Colors.grey[100]
                  //                           : Colors.white,
                  //                   border: OutlineInputBorder(
                  //                     borderRadius: BorderRadius.circular(8),
                  //                     borderSide: BorderSide(
                  //                       color: Colors.grey[300]!,
                  //                     ),
                  //                   ),
                  //                   focusedBorder: OutlineInputBorder(
                  //                     borderRadius: BorderRadius.circular(8),
                  //                     borderSide: BorderSide(
                  //                       color: Colors.blue[700]!,
                  //                       width: 2,
                  //                     ),
                  //                   ),
                  //                   contentPadding: const EdgeInsets.symmetric(
                  //                     vertical: 10,
                  //                     horizontal: 12,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //             const SizedBox(
                  //               width: 8,
                  //             ), // Spasi antara input dan tombol
                  //             // Tombol Tambah (+)
                  //             InkWell(
                  //               onTap:
                  //                   isViewOnly
                  //                       ? null
                  //                       : () {
                  //                         double newQty = pickedQty + 1.0;
                  //                         controller.updatePickedQuantity(
                  //                           lineIndex,
                  //                           newQty,
                  //                         );
                  //                       },
                  //               child: Container(
                  //                 padding: const EdgeInsets.all(8),
                  //                 decoration: BoxDecoration(
                  //                   color:
                  //                       isViewOnly
                  //                           ? Colors.grey[200]
                  //                           : Colors.blue[700], // Warna tombol
                  //                   borderRadius: BorderRadius.circular(8),
                  //                 ),
                  //                 child: Icon(
                  //                   Icons.add,
                  //                   size: 20,
                  //                   color:
                  //                       isViewOnly
                  //                           ? Colors.grey[600]
                  //                           : Colors.white,
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Obx(
                () =>
                    controller.isLoading.value
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                          onPressed:
                              isViewOnly
                                  ? controller.openPicklist
                                  : controller.completePicklist,
                          icon: const Icon(Icons.check_circle),
                          label: Text(
                            isViewOnly ? 'Open Picklist' : 'Complete Pick',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isViewOnly ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
              ),
            ),

            // if (!isViewOnly)
            // Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: Obx(
            //       () =>
            //           controller.isLoading.value
            //               ? const CircularProgressIndicator()
            //               : ElevatedButton.icon(
            //                 onPressed: controller.completePicklist,
            //                 icon: const Icon(Icons.check_circle),
            //                 label: const Text('Complete Pick'),
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: Colors.green,
            //                   foregroundColor: Colors.white,
            //                   minimumSize: const Size.fromHeight(50),
            //                 ),
            //               ),
            //     ),
            //   ),
          ],
        );
      }),
    );
  }
}
