// lib/screens/list_picklists_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; 

import '../controllers/picklist_controller copy.dart'; // Sesuaikan path

class PickListPage1 extends StatelessWidget {
  const PickListPage1({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller
    final PicklistController controller = Get.put(PicklistController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick List Manager'),
        actions: [
          // Filter button for status
          Obx(
            () => PopupMenuButton<String>(
              initialValue: controller.selectedStatusFilter.value,
              onSelected: (String result) {
                controller.changeStatusFilter(result);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'R',
                  child: Text('Released (Open)'),
                ),
                const PopupMenuItem<String>(
                  value: 'C',
                  child: Text('Closed'),
                ),
                // const PopupMenuItem<String>( // Opsi untuk menampilkan semua
                //   value: 'All',
                //   child: Text('All Picklists'),
                // ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 4),
                    Text(controller.selectedStatusFilter.value == 'R' ? 'Released' : 'Closed'),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchPickList(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        if (controller.displayedPicklists.isEmpty) {
          return const Center(child: Text('No picklists found for this status.'));
        }

        return ListView.builder(
          itemCount: controller.displayedPicklists.length,
          itemBuilder: (context, index) {
            final picklist = controller.displayedPicklists[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              child: ExpansionTile(
                title: Text(
                  'Pick List: ${picklist['Name']} (Abs Entry: ${picklist['AbsoluteEntry']})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Status: ${picklist['Status'] == 'R' ? 'Released' : 'Closed'} - Remarks: ${picklist['Remarks']}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text(
                          'Items to Pick:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (picklist['PickListsLines'] != null &&
                            picklist['PickListsLines'].isNotEmpty)
                          ...List.generate(
                            picklist['PickListsLines'].length,
                            (lineIndex) {
                              final line = picklist['PickListsLines'][lineIndex];
                              // Pastikan semua nilai adalah tipe yang benar, terutama angka
                              final double releasedQty = line['ReleasedQuantity']?.toDouble() ?? 0.0;
                              final double pickedQty = line['PickedQuantity']?.toDouble() ?? 0.0;
                              final double stockOnHand = double.tryParse(line['Stock_On_Hand']?.toString() ?? '0.0') ?? 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Item: ${line['ItemName']} (${line['ItemCode']})'),
                                    Text('Bin Loc: ${line['Bin_Loc']} - Stock: ${stockOnHand.toStringAsFixed(0)}'),
                                    Text('Released Qty: ${releasedQty.toStringAsFixed(0)}'),
                                    Row(
                                      children: [
                                        const Text('Picked Qty: '),
                                        Expanded(
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: pickedQty.toStringAsFixed(0)),
                                            onChanged: (value) {
                                              double newQty = double.tryParse(value) ?? 0.0;
                                              controller.updatePickedQuantity(
                                                  index, lineIndex, newQty);
                                            },
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        // Optional: Barcode Scan button per line
                                        // IconButton(
                                        //   icon: Icon(Icons.barcode_reader),
                                        //   onPressed: () {
                                        //     // Implement barcode scanning logic here
                                        //     // Upon scan, update the relevant TextField
                                        //   },
                                        // ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            },
                          )
                        else
                          const Text('No items in this picklist.'),
                        if (picklist['Status'] == 'R') // Hanya tampilkan tombol complete jika status Released
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => controller.completePicklist(picklist),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Complete Pick'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, // Background color
                                foregroundColor: Colors.white, // Text color
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}