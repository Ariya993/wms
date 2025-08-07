import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/item_controller.dart';
import '../controllers/pick_pack_controller.dart';
import '../widgets/custom_dropdown_search.dart';
import '../widgets/loading.dart';
import 'scanner.dart';

class PickPackManagerPage extends GetView<PickPackController> {
  const PickPackManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final ItemController itemController = Get.put(ItemController());
    final TextEditingController searchController = TextEditingController(
      text: controller.searchQuery.value,
    );
    Future<void> _navigateToScanner() async {
      final result = await Get.to(() => const BarcodeScannerPage());
      if (result != null && result is String && result.isNotEmpty) {
        // print(result);
        controller.searchQuery.value = result;
        searchController.text=result;
        controller.scanPickableItems(
          reset: true,
          source: controller.filterType.value,
          warehouse: itemController.selectedWarehouseFilter.value,
        );
      }
    }

    //  final TextEditingController searchController = TextEditingController(
    //     );
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 ) {
        controller.fetchPickableItems();
      }
      // if (scrollController.position.pixels >=
      //         scrollController.position.maxScrollExtent - 200 &&
      //     !controller.isFetchingMore.value &&
      //     controller.hasMoreData.value) {
      //   controller.fetchPickableItems();
      // }
    });
    // searchController.addListener(() {
    //   controller.searchQuery.value = searchController.text;
    //   // controller.fetchPickableItems(reset: true); // Terapkan
    // });
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
          TextButton.icon(
            onPressed: () {
              _navigateToScanner();
            },
            icon: const Icon(Icons.qr_code_scanner, size: 24),
            label: const Text('Scan QR', style: TextStyle(fontSize: 16)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40, // Atur tinggi sesuai yang diinginkan
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Search by Doc Num, Customer, Item Code or Name',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged:
                                (value) => controller.searchQuery.value = value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol cari
                      Container(
                        height: 40, // Sama dengan tinggi TextField
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // controller.fetchPickableItems(reset: true);
                            controller.fetchPickableItems(
                              reset: true,
                              source: "",
                              warehouse:
                                  itemController.selectedWarehouseFilter.value,
                            );
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween, // atau end / start / center
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Kiri: Filter Type (Align sudah tidak perlu)
                      PopupMenuButton<String>(
                        initialValue: controller.filterType.value,
                        tooltip: 'Filter Type',
                        onSelected: (String value) {
                          controller.filterType.value = value;
                          controller.fetchPickableItems(
                            reset: true,
                            source: value,
                            warehouse:
                                itemController.selectedWarehouseFilter.value,
                          );
                        },
                        itemBuilder:
                            (BuildContext context) => const [
                              PopupMenuItem<String>(
                                value: 'ALL',
                                child: Text('All'),
                              ),
                              PopupMenuItem<String>(
                                value: 'ORDER',
                                child: Text('Order'),
                              ),
                              PopupMenuItem<String>(
                                value: 'TRANSFER',
                                child: Text('Transfer'),
                              ),
                            ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.filterType.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const Icon(Icons.filter_list, color: Colors.grey),
                          ],
                        ),
                      ),

                      // Kanan: Dropdown Warehouse (Padding + Align DIHAPUS, langsung pakai Container)
                      Obx(() {
                        final warehouses =
                            itemController.selectedWarehouses.toList();
                        if (warehouses.isEmpty) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: GestureDetector(
                            onTapDown: (details) {
                              final Offset offset = details.globalPosition;
                              final double dx = offset.dx;
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
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText: 'Cari warehouse...',
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              onChanged:
                                                  (value) => itemController
                                                      .filterWarehouseSearch(
                                                        value,
                                                      ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 350,
                                              width: 200,
                                              child: ListView(
                                                shrinkWrap: true,
                                                children:
                                                    itemController.filteredWarehouseList.map((
                                                      w,
                                                    ) {
                                                      final name =
                                                          itemController
                                                              .warehouseCodeNameMap[w] ??
                                                          w;
                                                      return ListTile(
                                                        title: Text(name),
                                                        tileColor: Colors.white,
                                                        textColor: Colors.black,
                                                        onTap: () {
                                                          itemController
                                                              .selectedWarehouseFilter
                                                              .value = w;
                                                          // itemController
                                                          //     .resetItems();
                                                          controller
                                                              .fetchPickableItems(
                                                                reset: true,
                                                                source:
                                                                    controller
                                                                        .searchQuery
                                                                        .value,
                                                                warehouse: w,
                                                              );
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                      );
                                                    }).toList(),
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
                                    itemController
                                            .selectedWarehouseFilter
                                            .value
                                            .isEmpty
                                        ? 'Warehouse'
                                        : itemController
                                                .warehouseCodeNameMap[itemController
                                                .selectedWarehouseFilter
                                                .value] ??
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
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final filteredItems = controller.pickableItems;

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
                final screenWidth = MediaQuery.of(context).size.width;
                final isWeb = screenWidth > 800;
                if (isWeb) {
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount:
                        filteredItems.length +
                        (controller.isFetchingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredItems.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final item = filteredItems[index];

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile =
                              constraints.maxWidth < 600; // breakpoint
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              runSpacing: 8,
                              children: [
                                // checkbox
                                SizedBox(
                                  width: isMobile ? constraints.maxWidth : 40,
                                  child: Obx(() {
                                    bool canCheckInitially =
                                        item.openQuantity <=
                                            item
                                                .simulatedAvailableQuantity
                                                .value &&
                                        item.simulatedAvailableQuantity.value >
                                            0;
                                    bool enableCheckboxInteraction =
                                        item.isSelected.value ||
                                        canCheckInitially;

                                    return Checkbox(
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
                                    );
                                  }),
                                ),

                                // Item
                                SizedBox(
                                  width:
                                      isMobile
                                          ? constraints.maxWidth
                                          : constraints.maxWidth * .25,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item.itemCode} - ${item.itemName}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              item.docType.toLowerCase() ==
                                                      'order'
                                                  ? Colors.blueAccent
                                                  : Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          item.docType.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Order/Customer
                                SizedBox(
                                  width:
                                      isMobile
                                          ? constraints.maxWidth
                                          : constraints.maxWidth * .3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('ORDER NO: ${item.docNum}'),
                                      Text(
                                        item.cardName.toString(),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),

                                // QTY & Stock
                                SizedBox(
                                  width:
                                      isMobile
                                          ? constraints.maxWidth
                                          : constraints.maxWidth * .2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ordered: ${item.orderedQuantity.toStringAsFixed(0)}',
                                      ),
                                      Text(
                                        'Open: ${item.openQuantity.toStringAsFixed(0)}',
                                      ),
                                      Obx(
                                        () => Text(
                                          'Available: ${item.simulatedAvailableQuantity.toStringAsFixed(0)}',
                                          style: TextStyle(
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
                                      ),
                                    ],
                                  ),
                                ),

                                // Picked Qty
                                SizedBox(
                                  width:
                                      isMobile
                                          ? constraints.maxWidth
                                          : constraints.maxWidth * .2,
                                  child: Obx(() {
                                    double pickedQty =
                                        item.pickedQuantity.value;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap:
                                              item.isSelected.value
                                                  ? () {
                                                    controller
                                                        .updatePickedQuantity(
                                                          controller
                                                              .pickableItems
                                                              .indexOf(item),
                                                          (pickedQty - 1)
                                                              .toString(),
                                                        );
                                                  }
                                                  : null,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  item.isSelected.value
                                                      ? Colors.blue[700]
                                                      : Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              size: 18,
                                              color:
                                                  item.isSelected.value
                                                      ? Colors.white
                                                      : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                item.pickedQtyController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            textAlign: TextAlign.center,
                                            enabled: item.isSelected.value,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              filled: true,
                                              fillColor:
                                                  item.isSelected.value
                                                      ? Colors.white
                                                      : Colors.grey[100],
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              controller.updatePickedQuantity(
                                                controller.pickableItems
                                                    .indexOf(item),
                                                value,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap:
                                              item.isSelected.value
                                                  ? () {
                                                    controller
                                                        .updatePickedQuantity(
                                                          controller
                                                              .pickableItems
                                                              .indexOf(item),
                                                          (pickedQty + 1)
                                                              .toString(),
                                                        );
                                                  }
                                                  : null,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  item.isSelected.value
                                                      ? Colors.blue[700]
                                                      : Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 18,
                                              color:
                                                  item.isSelected.value
                                                      ? Colors.white
                                                      : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
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
                                        item.simulatedAvailableQuantity.value >
                                            0;

                                    bool enableCheckboxInteraction =
                                        item.isSelected.value ||
                                        canCheckInitially;

                                    String tooltipText = '';
                                    if (!enableCheckboxInteraction &&
                                        !item.isSelected.value) {
                                      if (item
                                              .simulatedAvailableQuantity
                                              .value <=
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${item.cardName}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Stock: ${item.inStock.toStringAsFixed(0)}',
                                        ),

                                        Text(
                                          'Available to release: ${item.simulatedAvailableQuantity.toStringAsFixed(0)}',
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
                              Obx(() {
                                // Pastikan 'item' adalah instance dari PickableItem
                                // Anda perlu memastikan bahwa pickedQty adalah hasil dari item.pickedQuantity.value
                                final double pickedQty =
                                    item
                                        .pickedQuantity
                                        .value; // Ambil nilai reaktif

                                return Row(
                                  children: [
                                    const Text('Picked Qty: '),
                                    const SizedBox(width: 8),

                                    // Tombol Kurang (-)
                                    InkWell(
                                      onTap:
                                          item
                                                  .isSelected
                                                  .value // Hanya bisa diklik jika item terpilih
                                              ? () {
                                                double newQty = pickedQty - 1.0;
                                                controller.updatePickedQuantity(
                                                  controller.pickableItems
                                                      .indexOf(
                                                        item,
                                                      ), // Dapatkan index item
                                                  newQty.toString(),
                                                );
                                              }
                                              : null,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              item.isSelected.value
                                                  ? Colors.blue[700]
                                                  : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 20,
                                          color:
                                              item.isSelected.value
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // TextField untuk Quantity
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            item.pickedQtyController, // Controller dari PickableItem
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: 'Enter quantity',
                                          border: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(8),
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.blue[700]!,
                                              width: 2,
                                            ),
                                          ),
                                          suffixIcon:
                                              (pickedQty > 0 &&
                                                      (pickedQty >
                                                          item.openQuantity
                                                      // Perhatikan: validasi ini di UI mungkin tidak perlu
                                                      // jika sudah ada di controller. Atau bisa jadi indikator warning.
                                                      // item.pickedQuantity.value > item.simulatedAvailableQuantity.value
                                                      // lebih tepatnya adalah item.pickedQuantity.value > item.originalAvailableQuantity
                                                      // jika melihat seluruh item yang dipick untuk kode barang ini.
                                                      // Untuk warning di UI, mungkin lebih baik pakai item.simulatedAvailableQuantity.value < 0
                                                      // atau total picked melebihi originalAvailableQuantity
                                                      // (item.pickedQuantity.value > item.simulatedAvailableQuantity.value + (nilai sebelum perubahan))
                                                      // Jika Anda ingin icon warningnya muncul ketika total pick untuk itemCode itu melebihi originalAvailable
                                                      // Maka Anda perlu menghitung ulang total picked untuk itemCode di sini atau di PickableItem.
                                                      // Untuk kesederhanaan, mari kita pertimbangkan pickedQty > openQuantity sebagai salah satu indikator
                                                      // atau jika totalPicked for itemCode > originalAvailableQuantity
                                                      ))
                                                  ? const Icon(
                                                    Icons.warning,
                                                    color: Colors.orange,
                                                  )
                                                  : null,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                          isDense: true,
                                          filled: true,
                                          fillColor:
                                              item.isSelected.value
                                                  ? Colors.white
                                                  : Colors.grey[100],
                                        ),
                                        onChanged: (value) {
                                          // Panggil metode update di controller
                                          controller.updatePickedQuantity(
                                            controller.pickableItems.indexOf(
                                              item,
                                            ), // Dapatkan index item
                                            value,
                                          );
                                        },
                                        enabled: item.isSelected.value,
                                        style: TextStyle(
                                          color:
                                              item.isSelected.value
                                                  ? Colors.grey[800]
                                                  : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Tombol Tambah (+)
                                    InkWell(
                                      onTap:
                                          item.isSelected.value
                                              ? () {
                                                double newQty = pickedQty + 1.0;
                                                controller.updatePickedQuantity(
                                                  controller.pickableItems
                                                      .indexOf(
                                                        item,
                                                      ), // Dapatkan index item
                                                  newQty.toString(),
                                                );
                                              }
                                              : null,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              item.isSelected.value
                                                  ? Colors.blue[700]
                                                  : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: 20,
                                          color:
                                              item.isSelected.value
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
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
                                  warehouse:
                                      ItemController()
                                          .selectedWarehouseFilter
                                          .value,
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
                            child: const Text("Submit"),
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

  void showWarehouseFilterMenu(BuildContext context, Offset offset) {
    final itemController = ItemController();
    itemController.filteredWarehouseList.assignAll(
      itemController.selectedWarehouses,
    );

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
                            (value) => controller.fetchPickableItems(
                              reset: true,
                              source: controller.searchQuery.value,
                              warehouse: value,
                            ),
                        // itemController.filterWarehouseSearch(value),
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
                                onTap: () {
                                  itemController.selectedWarehouseFilter.value =
                                      w;
                                  // print (w);
                                  //    controller.fetchPickableItems(reset: true,source:controller.searchQuery.value, warehouse:w);
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
}
