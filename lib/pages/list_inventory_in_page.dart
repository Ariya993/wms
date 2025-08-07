import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms/widgets/loading.dart';
import '../controllers/list_inventory_in_controller.dart';
import 'package:wms/controllers/item_controller.dart';

import 'inventory_in_detail_page.dart';

class ListInventoryInPage extends StatefulWidget {
  const ListInventoryInPage({super.key});

  @override
  State<ListInventoryInPage> createState() => _ListInventoryInPageState();
}

class _ListInventoryInPageState extends State<ListInventoryInPage> {
  final scroll = ScrollController();
  late ListInventoryInController controller;
  final ItemController itemController = Get.put(ItemController());
  @override
  void initState() {
    super.initState();
    controller = Get.find<ListInventoryInController>();
    // controller.fetchData(reset: true);
    scroll.addListener(() {
      if (scroll.position.pixels >= scroll.position.maxScrollExtent - 200) {
        controller.loadMore();
      }
    });
  }
  @override
  void dispose() {
    scroll.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(title: const Text("List Inventory In"),elevation: 4, 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Items',
            onPressed: () => controller.fetchData(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [filterBar(), Expanded(child: buildGrid(isMobile))],
      ),
    );
  }

  Widget buildGrid(bool isMobile) {
    return Obx(() {
      if (controller.isLoading.value && controller.items.isEmpty) {
        // return const Center(child: CircularProgressIndicator());
        return const Loading();
      }
      final width = MediaQuery.of(context).size.width;
      int crossAxisCount;
      double childAspectRatio;
      if (width > 1800) {
        crossAxisCount = 6;
        childAspectRatio = 1.8;
      } else if (width > 1200) {
        crossAxisCount = 4;
        childAspectRatio = 1.8;
      } else if (width > 800) {
        crossAxisCount = 3;
        childAspectRatio = 1.9;
      } else if (width > 600) {
        crossAxisCount = 2;
        childAspectRatio = 1.9;
      } else {
        crossAxisCount = 1;
        childAspectRatio = 1.9;
      }

      final data = controller.items;
      if (data.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center, color: Colors.grey, size: 60),
              SizedBox(height: 10),
              Text(
                'No Data Found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      } else {
        return GridView.builder(
          controller: scroll,
          padding: const EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: data.length + (controller.isLoadMore.value ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == data.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final e = data[i];
            return buildCard(e);
          },
        );
      }
    });
  }

  Widget filterBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field
              TextField(
                decoration: const InputDecoration(
                  hintText: "Search DocNum or Supplier...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onChanged: (val) => controller.searchText.value = val,
              ),
              const SizedBox(height: 8),

              // === STATUS + DROPDOWN ===
              isMobile
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FILTER STATUS (chips)
                      _buildStatusChips(),
                      const SizedBox(height: 8),

                      // DROPDOWNS (source + warehouse)
                      _buildDropdownFilters(),
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildStatusChips()),
                      _buildDropdownFilters(),
                    ],
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChips() {
    final statusList = ['All', 'Open', 'Closed', 'Cancelled'];
    return Obx(() {
      final selected = controller.filterStatus.value;
      return Wrap(
        spacing: 6,
        children:
            statusList.map((status) {
              final isSelected =
                  selected == status || (selected == '' && status == 'All');
              return RawChip(
                selected: isSelected,
                showCheckmark: false,
                selectedColor: Colors.blue.shade600,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, size: 16, color: Colors.white),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                shape: StadiumBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                onSelected: (_) {
                  controller.filterStatus.value =
                      (status == 'All') ? '' : status;
                  controller.fetchData(reset: true);
                },
              );
            }).toList(),
      );
    });
  }

  Widget _buildDropdownFilters() {
    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Filter Source
        PopupMenuButton<String>(
          initialValue: controller.filterSource.value,
          tooltip: 'Filter Type',
          onSelected: (val) {
            controller.filterSource.value = val;
            controller.fetchData(
              reset: true,
              source: val,
              warehouse: controller.filterWarehouse.value,
            );
          },
          itemBuilder:
              (context) => const [
                PopupMenuItem(value: '', child: Text('All')),
                PopupMenuItem(value: 'po', child: Text('PO Based')),
                PopupMenuItem(value: 'nonpo', child: Text('Non-PO Based')),
              ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.filterSource.value.isEmpty
                    ? 'All'
                    : controller.filterSource.value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Icon(Icons.filter_list, color: Colors.grey),
            ],
          ),
        ),

        // Warehouse filter
        Obx(() {
          final warehouses = itemController.selectedWarehouses.toList();
          if (warehouses.isEmpty) return const SizedBox();

          return GestureDetector(
            onTapDown: (details) {
              final offset = details.globalPosition;
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(offset.dx, offset.dy, 0, 0),
                items: [
                  PopupMenuItem<String>(
                    padding: EdgeInsets.zero,
                    child: Obx(
                      () => Material(
                        color: Colors.white,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Cari warehouse...',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged:
                                  (val) => controller.filterWarehouse(val),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 300,
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
                                        onTap: () {
                                          controller.filterWarehouse.value = w;
                                          controller.fetchData(
                                            reset: true,
                                            source:
                                                controller.filterSource.value,
                                            warehouse: w,
                                          );
                                          Navigator.pop(context);
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    itemController.selectedWarehouseFilter.value.isEmpty
                        ? 'Warehouse'
                        : itemController.warehouseCodeNameMap[controller
                                .filterWarehouse
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
          );
        }),
      ],
    );
  }

  Widget searchField() {
    return TextField(
      decoration: const InputDecoration(
        hintText: "Search DocNum or Card Name...",
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      onChanged: (val) => controller.searchText.value = val,
    );
  }

  Widget buildCard(Map<String, dynamic> e) {
    //---- STATUS ----
    String status;
    if ((e['Cancelled'] ?? '') == 'Y') {
      status = "Cancelled";
    } else if ((e['DocumentStatus'] ?? '') == 'C') {
      status = "Closed";
    } else {
      status = "Open";
    }

    Color badgeColor;
    switch (status) {
      case "Open":
        badgeColor = Colors.green;
        break;
      case "Closed":
        badgeColor = Colors.blue;
        break;
      default:
        badgeColor = Colors.red;
    }

    //---- SOURCE BADGE ----
    String sourceType = (e['SourceType'] ?? '').toString().toUpperCase();
    String sourceLabel = sourceType == "PO" ? "PO Based" : "Non-PO Based";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          // Badge status kanan atas
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${e['DocNum']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Supplier: ${e['CardName'] ?? '-'}"),
              Text(
                "Date    : ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(e['DocDate']))}",
              ),

              const SizedBox(height: 6),
              Divider(color: Colors.grey[300]),

              // Action Row
              Row(
                children: [
                  // Source badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sourceLabel,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const Spacer(), 
                  // Cancel button with dialog
                  if (status.toLowerCase()=='open')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      Get.defaultDialog(
                        title: "Confirmation",
                        middleText: "Are you sure to cancel this document?",
                        textConfirm: "Yes",
                        textCancel: "No",
                        confirmTextColor: Colors.white,
                        onConfirm: () {
                          Get.back();
                          controller.cancel(e);
                        },
                      );
                    },
                    child: const Text("Cancel"),
                  ),
                   const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[50],
                      foregroundColor: Colors.orange[700],
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),

                    onPressed: () async {
                      final result = await Get.to(
                        () => InventoryDetailPage(data: e),
                      );
                      if (result != null) {
                        controller.updateDocument(result);
                      }
                    },

                    child: const Text("View"),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
