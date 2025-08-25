// lib/screens/picklist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms/controllers/stock_opname_controller.dart';
import 'package:wms/widgets/loading.dart';

import '../helper/format.dart';
import 'scanner.dart';

class OpnameDetailPage extends StatefulWidget {
  final bool isViewOnly;
  final int docEntry;

  const OpnameDetailPage({
    super.key,
    this.isViewOnly = false,
    this.docEntry = 0,
  });

  @override
  State<OpnameDetailPage> createState() => _OpnameDetailPageState();
}

class _OpnameDetailPageState extends State<OpnameDetailPage> {
  late final StockOpnameController controller = Get.put(
    StockOpnameController(),
  );
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
    // debugPrint("🔥 INITSTATE jalan, docEntry = ${widget.docEntry}");
    if (widget.docEntry > 0) {
      controller.soNumberController.text = widget.docEntry.toString();
      controller.searchSO();
    }
  }

  Future<void> _navigateToScanner() async {
    final result = await Get.to(() => const BarcodeScannerPage());
    if (result != null && result is String && result.isNotEmpty) {
      final picklist = controller.currentProcessingPicklist.value!;
      final List<dynamic> lines = picklist['DocumentLine'] ?? [];

      // Ambil semua row dengan ItemCode yang sama
      final matchingRows =
          lines.where((line) => line['ItemCode'] == result).toList();
      if (matchingRows.isEmpty) {
        Get.snackbar(
          'Warning',
          'Scanned item ($result) not found in stock opname.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final totalNeed = matchingRows.fold<double>(0, (sum, row) {
        final releasedQty = (row['InWarehouseQuantity'] ?? 0).toDouble();
        final pickedQty = (row['CountedQuantity'] ?? 0).toDouble();
        final newPickedQty = (row['NewPickedQty'] ?? 0).toDouble();
        return sum + (releasedQty - pickedQty - newPickedQty);
      });

      // Ambil info tambahan dari baris pertama
      final itemName = matchingRows.first['ItemDescription'] ?? '';
      final binLoc = matchingRows.first['BinLoc'] ?? '';
      final itemCode = result;

      if (totalNeed == 0) {
        Get.snackbar(
          'Warning',
          'Scanned item ($result) maximum quantity.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      showDistributionDialog(
        Get.context!,
        itemCode,
        itemName,
        binLoc,
        totalNeed.toInt(),
        matchingRows.map((row) {
          final releasedQty = (row['InWarehouseQuantity'] ?? 0).toDouble();
          final pickedQty = (row['CountedQuantity'] ?? 0).toDouble();
          final newPickedQty = (row['NewPickedQty'] ?? 0).toDouble();
          return {
            'row': row['LineNumber'] ?? '',
            'qty': (releasedQty - pickedQty - newPickedQty).toInt(),
            'ref': row, // simpan referensi asli untuk update nanti
          };
        }).toList(),
        0, // default inputQty awalnya 0, nanti user isi di modal
      );

      //REQ 20240814.. munculin modal dan input qty
      //controller.processScannedItem(result);
    }
  }

  void showDistributionDialog(
    BuildContext context,
    String itemCode,
    String itemName,
    String binLocation,
    int totalNeeded,
    List<Map<String, dynamic>> rows,
    int inputQty,
  ) {
    int remaining = inputQty;

    List<Map<String, dynamic>> updatedRows =
        rows.map((row) {
          int allocate = 0;
          if (remaining > 0) {
            int available = row['qty'] ?? 0;
            allocate = remaining >= available ? available : remaining;
            remaining -= allocate;
            // if(allocate==0)
            // {
            //   allocate=1;
            // }
          }
          return {
                ...row,
                'allocated': (row['allocated'] ?? 1), // default awal = 1
              };
          // return {...row, 'allocated': allocate};
        }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // BODY
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Item Code: $itemCode'),
                      Text('Item Name: $itemName'),
                      Text('Bin Location: $binLocation'),
                      Text('Qty in Warehouse: $totalNeeded'),
                      const SizedBox(height: 10),
                      const Divider(),
                      Column(
                        children:
                            updatedRows.map((row) {
                              // kalau belum ada value, set default 1
                              row['allocated'] ??= 1;

                              // bikin controller biar bisa update text langsung
                              final controller = TextEditingController(
                                text: row['allocated'].toString(),
                              );

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    // tombol minus
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,color:Colors.red,
                                      ),
                                      onPressed: () {
                                        if (row['allocated'] > 1) {
                                          row['allocated'] =
                                              row['allocated'] - 1;
                                          controller.text =
                                              row['allocated'].toString();
                                        }
                                      },
                                    ),

                                    // input angka
                                    Expanded(
                                      child: TextFormField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 12,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (val) {
                                          row['allocated'] =
                                              int.tryParse(val) ?? 1;
                                        },
                                      ),
                                    ),

                                    // tombol plus
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,color:Colors.green
                                      ),
                                      onPressed: () {
                                        row['allocated'] = row['allocated'] + 1;
                                        controller.text =
                                            row['allocated'].toString();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),

                      // Column(
                      //   children:
                      //       updatedRows.map((row) {
                      //         return Padding(
                      //           padding: const EdgeInsets.symmetric(
                      //             vertical: 6,
                      //           ),
                      //           child: Column(
                      //             crossAxisAlignment: CrossAxisAlignment.start,
                      //             children: [
                      //               TextFormField(
                      //                 initialValue: row['allocated'].toString(),
                      //                 keyboardType: TextInputType.number,
                      //                 textAlign: TextAlign.center,
                      //                 decoration: const InputDecoration(
                      //                   isDense: true,
                      //                   contentPadding: EdgeInsets.symmetric(
                      //                     vertical: 6,
                      //                     horizontal: 12,
                      //                   ),
                      //                   border: OutlineInputBorder(),
                      //                 ),
                      //                 onChanged: (val) {
                      //                   row['allocated'] =
                      //                       int.tryParse(val) ?? 0;
                      //                 },
                      //               ),
                      //             ],
                      //           ),
                      //         );
                      //       }).toList(),
                      // ),
                    ],
                  ),
                ),
              ),

              // FOOTER
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        for (var row in updatedRows) {
                          controller.updatePickedQtyByItemCode(
                            itemCode,
                            row['allocated'].toDouble(),
                          );
                        }
                        // updatePickedQtyByItemCode(itemCode,row['allocated']);
                        Navigator.pop(context); 

                        final picklist = controller.currentProcessingPicklist.value!;
                      final picklistLines = picklist['DocumentLine'] ?? [];

                      // cari index itemCode terakhir yang discan
                      int savedIndex = picklistLines.indexWhere(
                        (line) => line['ItemCode'] == itemCode,
                      );

                      // kalau ga ketemu atau item paling bawah -> scroll ke paling bawah
                      if (savedIndex == -1) {
                        savedIndex = picklistLines.length - 1;
                      }

                      Future.delayed(const Duration(milliseconds: 300), () {
                        focusOnItem(savedIndex);
                      });
                            
                      },
                      child: const Text("Simpan"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Reset semua newPicked sebelum keluar page

        var picklist = controller.currentProcessingPicklist.value;
        if (picklist == null) {
          return true;
        }
        final List<dynamic> picklistLines = picklist['DocumentLine'] ?? [];
        for (var line in picklistLines) {
          line['NewPickedQty'] = 0;
        }

        return true;
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text('Detail Stock Opname'),

          actions:
              widget.isViewOnly
                  ? null
                  : [
                    TextButton.icon(
                      onPressed: () {
                        if (controller.currentProcessingPicklist.value !=
                            null) {
                          _navigateToScanner();
                        } else {
                          Get.snackbar(
                            'Error',
                            'Please select a data first.',
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
          if (controller.isLoading.value) {
            return const Loading();
          }
          final picklist = controller.currentProcessingPicklist.value;
          if (picklist == null) {
            return const Loading();
          }

          // final List<dynamic> picklistLines = picklist['DocumentLine'] ?? [];
          final picklistLines =
              (picklist['DocumentLine'] ?? []).map((e) => e).toList()..sort(
                (a, b) => (a["BinLoc"] ?? "").toString().compareTo(
                  (b["BinLoc"] ?? "").toString(),
                ),
              );

          // picklistLines.sortedBy((p) => (p["BinLoc"] ?? "").toString()); // ASC by BinLoc

          // picklistLines.sort((a, b) {
          //   final binA = (a["BinLoc"] ?? "").toString();
          //   final binB = (b["BinLoc"] ?? "").toString();
          //   return binA.compareTo(binB);
          // });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doc Date: ${format.formatPickDate(picklist['CountDate'])}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Remarks: ${picklist['Remarks']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Status: ${widget.isViewOnly ? 'Closed' : 'Released'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.isViewOnly ? Colors.red : Colors.green,
                      ),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'List Items:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: picklistLines.length,
                  itemBuilder: (context, lineIndex) {
                    final line = picklistLines[lineIndex];
                    // debugPrint("ListView.builder = ${line}");
                    final double releasedQty =
                        line['InWarehouseQuantity']?.toDouble() ?? 0.0;
                    final double newPicked =
                        line['NewPickedQty']?.toDouble() ??
                        (line['CountedQuantity']?.toDouble() ?? 0);
                    final double pickedQty =
                        line['CountedQuantity']?.toDouble() ?? 0.0;
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
                        borderRadius: BorderRadius.circular(16),
                        border:
                            (releasedQty == newPicked)
                                ? Border.all(
                                  color: Colors.green.shade400,
                                  width: 4,
                                )
                                : null,
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
                              color:
                                  (releasedQty == newPicked)
                                      ? Colors.green.shade400
                                      : Colors.lightBlue.shade400,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${line['ItemDescription']} (${line['ItemCode']})',
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
                                  'Doc No: ${picklist['DocumentNumber'] ?? '-'}  - Doc Date: ${format.formatPickDate(picklist['CountDate'])}',
                                ),
                                Text('Bin Loc: ${line['BinLoc'] ?? '-'}'),
                                 Text('UOM: ${line['MeasureUnit'] ?? '-'}'),
                                Text(
                                  'Qty Warehouse: ${releasedQty.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    const Text('Qty: '),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        controller: TextEditingController(
                                          text: newPicked.toStringAsFixed(0),
                                        ),
                                        textAlign: TextAlign.center,
                                        onChanged:
                                            widget.isViewOnly
                                                ? null
                                                : (value) {
                                                  controller
                                                      .updatePickedQuantity(
                                                        lineIndex,
                                                        double.tryParse(
                                                              value,
                                                            ) ??
                                                            0.0,
                                                      );
                                                },
                                        // readOnly: isViewOnly,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor:
                                              widget.isViewOnly
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
                                          widget.isViewOnly
                                              ? null
                                              : () {
                                                controller.updatePickedQuantity(
                                                  lineIndex,
                                                  0,
                                                );
                                              },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              widget.isViewOnly
                                                  ? Colors.grey[200]
                                                  : Colors.red[700],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.clear,
                                          size: 20,
                                          color:
                                              widget.isViewOnly
                                                  ? Colors.red[600]
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
                                widget.isViewOnly
                                    ? null
                                    : controller.completeStockOpname,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Submit Stock Opname'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  widget.isViewOnly
                                      ? Colors
                                          .grey // warna tombol kalau disabled
                                      : Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
