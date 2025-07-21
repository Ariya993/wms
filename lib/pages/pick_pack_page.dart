import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pick_pack_controller.dart';
import '../widgets/custom_dropdown_search.dart';
import '../widgets/loading.dart';

class PickPackManagerPage extends GetView<PickPackController> {
  const PickPackManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final TextEditingController searchController = TextEditingController(
      text: controller.searchQuery.value,
    );

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !controller.isFetchingMore.value &&
          controller.hasMoreData.value) {
        controller.fetchPickableItems();
      }
    });
    searchController.addListener(() {
      controller.searchQuery.value = searchController.text;
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pick & Pack Manager',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Items',
            onPressed: () => controller.fetchPickableItems(reset: true),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          // return const Center(child: CircularProgressIndicator());
          return const Loading();
        }
        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    'Error: ${controller.errorMessage.value}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchPickableItems(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (var item in controller.pickableItems) {
            item.pickedQuantity.refresh();
          }
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),

              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by Item Code or Name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    //  onChanged: (value) => controller.searchQuery.value = value,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children:
                        ['ALL', 'ORDER', 'TRANSFER'].map((type) {
                          return Obx(
                            () => ElevatedButton(
                              onPressed: () {
                                controller.filterType.value = type;
                                controller.fetchPickableItems(
                                  reset: true,
                                  source: type,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                    backgroundColor: controller.filterType.value == type
                                        ? Colors.blueAccent
                                        : Colors.white,
                                    foregroundColor: controller.filterType.value == type
                                        ? Colors.white
                                        : Colors.blueAccent,
                                    side: BorderSide(
                                      color: controller.filterType.value == type
                                          ? Colors.blueAccent
                                          : Colors.blueAccent, // warna border saat tidak aktif
                                      width: 1.5,
                                    ),
                                  ),

                              child: Text(
                                type,
                                style: TextStyle(color: controller.filterType.value == type
                                        ? Colors.white 
                                        : Colors.blueAccent),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final filteredItems =
                    controller.pickableItems.where((item) {
                      final matchesSearch =
                          item.itemCode.toLowerCase().contains(
                            controller.searchQuery.value.toLowerCase(),
                          ) ||
                          item.itemName.toLowerCase().contains(
                            controller.searchQuery.value.toLowerCase(),
                          );
                      final matchesFilter =
                          controller.filterType.value == 'ALL' ||
                          item.docType.toUpperCase() ==
                              controller.filterType.value;
                      return matchesSearch && matchesFilter;
                    }).toList();
                if (controller.pickableItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey,
                          size: 60,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No open items for picking.',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount:
                      filteredItems.length +
                      (controller.isFetchingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredItems.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                           // child: Loading(),
                           child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final item = filteredItems[index];
                    final TextEditingController qtyController =
                        TextEditingController(
                          text: item.pickedQuantity.value.toStringAsFixed(0),
                        );
                    qtyController.selection = TextSelection.fromPosition(
                      TextPosition(offset: qtyController.text.length),
                    );

                    item.pickedQuantity.listen((p0) {
                      if (p0.toStringAsFixed(0) != qtyController.text) {
                        qtyController.text = p0.toStringAsFixed(0);
                        qtyController.selection = TextSelection.fromPosition(
                          TextPosition(offset: qtyController.text.length),
                        );
                      }
                    });

                    return Card(
                      color: Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 4.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  bool canCheckInitially =
                                      item.openQuantity <=
                                          item
                                              .simulatedAvailableQuantity
                                              .value &&
                                      item.simulatedAvailableQuantity.value > 0;

                                  bool enableCheckboxInteraction =
                                      item.isSelected.value ||
                                      canCheckInitially;

                                  String tooltipText = '';
                                  if (!enableCheckboxInteraction &&
                                      !item.isSelected.value) {
                                    if (item.simulatedAvailableQuantity.value <=
                                        0) {
                                      tooltipText =
                                          'Tidak ada stok tersedia untuk Item ini.';
                                    } else {
                                      tooltipText =
                                          'Tidak bisa dicentang: Kuantitas Open (${item.openQuantity.toStringAsFixed(0)}) melebihi stok tersedia (${item.simulatedAvailableQuantity.toStringAsFixed(0)}).';
                                    }
                                  }

                                  return Tooltip(
                                    message: tooltipText,
                                    child: Checkbox(
                                      value: item.isSelected.value,
                                      onChanged:
                                          enableCheckboxInteraction
                                              ? (val) => controller
                                                  .toggleItemSelection(
                                                    controller.pickableItems
                                                        .indexOf(item),
                                                    val,
                                                  )
                                              : null,
                                      activeColor: Colors.blueAccent,
                                    ),
                                  );
                                }),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.itemCode} - ${item.itemName.toUpperCase()}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  item.docType.toLowerCase() ==
                                                          'order'
                                                      ? Colors.blueAccent
                                                      : Colors.orangeAccent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              item.docType.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'ORDER NO: ${item.docNum}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Warehouse: ${item.sourceWarehouseCode}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ordered: ${item.orderedQuantity.toStringAsFixed(0)}',
                                    ),
                                    Text(
                                      'Open: ${item.openQuantity.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                                Obx(
                                  () => Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'In Stock: ${item.inStock.toStringAsFixed(0)}',
                                      ),
                                      Text(
                                        'Available: ${item.simulatedAvailableQuantity.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              item
                                                          .simulatedAvailableQuantity
                                                          .value >=
                                                      item.openQuantity
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Obx(
                              () => TextField(
                                controller: item.pickedQtyController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'Quantity to Pick',
                                  hintText: 'Enter quantity',
                                  border: const OutlineInputBorder(),
                                  suffixIcon:
                                      (item.pickedQuantity.value > 0 &&
                                              (item.pickedQuantity.value >
                                                      item.openQuantity ||
                                                  item.pickedQuantity.value >
                                                      item
                                                          .simulatedAvailableQuantity
                                                          .value))
                                          ? const Icon(
                                            Icons.warning,
                                            color: Colors.orange,
                                          )
                                          : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  final qty = double.tryParse(value) ?? 0.0;
                                  item.updatePickedQuantity(qty);
                                },
                                enabled: item.isSelected.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      controller.isLoading.value
                          ? null
                          // : () => controller.generatePickList(),
                          : () => showPickListDialog(context),
                  icon:
                      controller.isLoading.value
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(
                            Icons.playlist_add_check,
                            color: Colors.white,
                          ),
                  label: Text(
                    controller.isLoading.value
                        ? 'Generating...'
                        : 'Generate Pick List',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void showPickListDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final controller = Get.find<PickPackController>();
    final tempNote = TextEditingController();
    Rx<DateTime> selectedDate = DateTime.now().obs;

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
            child: Obx(
              () => Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      const Text(
                        'Detail Pick List',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(thickness: 1, color: Colors.grey),

                      // Picker Dropdown
                      CustomDropdownSearch<Map<String, dynamic>>(
                        labelText: "Picker",
                        selectedItem: controller.selectedPicker.value,
                        asyncItems: (String? filter) async {
                          final allPickers = controller.Picker.toList();

                          if (filter == null || filter.isEmpty)
                            return allPickers;

                          return allPickers.where((wh) {
                            final name =
                                (wh['nama'] ?? '').toString().toLowerCase();
                            final username =
                                (wh['username'] ?? '').toString().toLowerCase();
                            final filterText = filter.toLowerCase();
                            return name.contains(filterText) ||
                                username.contains(filterText);
                          }).toList();
                        },
                        onChanged: (picker) {
                          controller.selectedPicker.value = picker;
                        },
                        itemAsString: (picker) => picker['nama'] ?? '',
                        compareFn: (a, b) => a['UserCode'] == b['UserCode'],
                        validator:
                            (picker) =>
                                picker == null
                                    ? 'Please select the Picker'
                                    : null,
                      ),

                      const SizedBox(height: 16),

                      // Note Input
                      TextFormField(
                        controller: tempNote,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Pick Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate.value,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                selectedDate.value = picked;
                              }
                            },
                            child: Text(
                              'Tanggal: ${selectedDate.value.toLocal().toIso8601String().split("T")[0]}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                controller.generatePickList(
                                  pickDate: selectedDate.value,
                                  pickerName:
                                      controller
                                          .selectedPicker
                                          .value?['nama'] ??
                                      '',
                                  note: tempNote.text,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: const Text("Lanjut"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
