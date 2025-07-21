// lib/screens/picklist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; 

import '../controllers/picklist_controller.dart';
import 'scanner.dart';

class PicklistDetailPage extends StatelessWidget {
  final bool isViewOnly;

  PicklistDetailPage({super.key, this.isViewOnly = false});

  final PicklistController controller = Get.find<PicklistController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              // Pastikan akses menggunakan .value
              controller.currentProcessingPicklist.value != null
                  ? 'Pick List: ${controller.currentProcessingPicklist.value!['Name']}'
                  : 'Pick List Detail',
            )),
        actions: isViewOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    // Pastikan currentProcessingPicklist sudah diset sebelum ke scanner
                    if (controller.currentProcessingPicklist.value != null) {
                      Get.to(() => BarcodeScannerPage());
                    } else {
                      Get.snackbar('Error', 'Please select a picklist first.',
                          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
                    }
                  },
                ),
              ],
      ),
      body: Obx(() {
        // PENTING: Gunakan null-check dan ! di sini
        final picklist = controller.currentProcessingPicklist.value;
        if (picklist == null) {
          return const Center(child: Text('No picklist selected.'));
        }

        final List<dynamic> picklistLines = picklist['DocumentLine']?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Absolute Entry: ${picklist['Absoluteentry']}', style: const TextStyle(fontSize: 16)),
                  Text('Remarks: ${picklist['Remarks']}', style: const TextStyle(fontSize: 16)),
                  Text('Status: ${isViewOnly ? 'Closed' : 'Released'}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isViewOnly ? Colors.red : Colors.green)),
                  const Divider(height: 24),
                  const Text('Items in Pick List:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: picklistLines.length,
                itemBuilder: (context, lineIndex) {
                  final line = picklistLines[lineIndex];
                  final double releasedQty = line['ReleasedQuantity']?.toDouble() ?? 0.0;
                  final double pickedQty = line['PickedQuantity']?.toDouble() ?? 0.0;
                  final double stockOnHand = double.tryParse(line['StockOnHand']?.toString() ?? '0.0') ?? 0.0;

                  // Pastikan TextField memiliki key yang unik jika Anda mengalami masalah dengan nilai yang tidak terupdate
                  // Key key = ValueKey('picklist_${picklist['AbsoluteEntry']}_line_$lineIndex');

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Item: ${line['ItemName']} (${line['ItemCode']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Bin Loc: ${line['Bin_Loc'] ?? '-' }'),
                          Text('Stock On Hand: ${stockOnHand.toStringAsFixed(0)}'),
                          Text('Released Qty: ${releasedQty.toStringAsFixed(0)}'),
                          Row(
                            children: [
                              const Text('Picked Qty: '),
                              Expanded(
                                child: TextField(
                                  // key: key, // Gunakan key jika perlu
                                  keyboardType: TextInputType.number,
                                  // Inisialisasi controller di sini dengan nilai yang sudah ada
                                  controller: TextEditingController(text: pickedQty.toStringAsFixed(0)),
                                  onChanged: isViewOnly ? null : (value) {
                                    double newQty = double.tryParse(value) ?? 0.0;
                                    controller.updatePickedQuantity(lineIndex, newQty);
                                  },
                                  readOnly: isViewOnly,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    border: const OutlineInputBorder(),
                                    fillColor: isViewOnly ? Colors.grey[200] : Colors.white,
                                    filled: isViewOnly,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!isViewOnly)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(() => controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: controller.completePicklist,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Complete Pick'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                        ),
                      )),
              ),
          ],
        );
      }),
    );
  }
}