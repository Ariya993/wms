import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class InventoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  InventoryDetailPage({super.key, required this.data});

  final TextEditingController commentCtrl = TextEditingController();
  final Rx<DateTime> selectedDate = Rx(DateTime.now());
  final RxList<Map<String, dynamic>> lines = <Map<String, dynamic>>[].obs;

  @override
  Widget build(BuildContext context) {
    // Init values
    commentCtrl.text = data['Comments'] ?? '';
    selectedDate.value =
        DateTime.tryParse(data['DocDate'] ?? '') ?? DateTime.now();
    lines.assignAll(
      List<Map<String, dynamic>>.from(data['DocumentLine'] ?? []),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Detail Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Card(
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === DOC NO + BADGE SOURCE ===
        Row(
          children: [
            Expanded(
              child: Text(
                "Doc No: ${data['DocNum'] ?? '-'}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (data['SourceType']?.toString().toLowerCase() == 'po')
                    ? Colors.orange
                    : Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data['SourceType']?.toString().toLowerCase() == 'po'
                    ? 'PO Based'
                    : 'Non-PO Based',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // === DOC DATE ===
        Obx(
          () => Row(
            children: [
              const Text(
                "Doc Date:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd-MMM-yyyy').format(selectedDate.value),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // === SUPPLIER ===
        Text(
          "Supplier: ${data['CardName'] ?? '-'}",
          style: const TextStyle(fontSize: 16),
        ),
 
      ],
    ),
  ),
),
            const SizedBox(height: 12),

            // Item Lines
            const Text(
              "Item List",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: DataTable(
                        columnSpacing: 24,
                        dataRowMinHeight: 48,
                        columns: const [
                          DataColumn(label: Text('Item Code')),
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Quantity')),
                        ],
                        rows:
                            lines.map((line) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(line['ItemCode'] ?? '-')),
                                  DataCell(
                                    Text(line['ItemDescription'] ?? '-'),
                                  ),
                                  DataCell(Text(line['Quantity'].toString())),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // const SizedBox(height: 16),

            // // Save button
            // SizedBox(

            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     onPressed: () {
            //       final updatedData = {
            //         "DocEntry": data['DocEntry'],
            //         "DocDate": DateFormat('yyyy-MM-dd').format(selectedDate.value),
            //         "Comments": commentCtrl.text,
            //         "DocumentLines": lines,
            //       };
            //       Get.back(result: updatedData);
            //     },
            //     icon: const Icon(Icons.save),
            //     label: const Text("Save"),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
