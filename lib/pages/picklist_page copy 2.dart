import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms/controllers/item_controller.dart';

import '../controllers/picklist_controller.dart';
import '../helper/format.dart';
import '../widgets/custom_dropdown_search.dart';
import '../widgets/loading.dart';
import '../widgets/statusbadge.dart';
import 'picklist_detail_page.dart';

class PicklistsPage extends StatefulWidget {
  const PicklistsPage({super.key});

  @override
  State<PicklistsPage> createState() => _PicklistsPageState();
}

class _PicklistsPageState extends State<PicklistsPage> {
  // const PicklistsPage({super.key});
  late final PicklistController controller = Get.put(PicklistController());
  late final ItemController itemController = Get.put(ItemController());

  // @override
  // void dispose() {
  //   scrollController.dispose();
  //   searchController.dispose();
  //   debounceTimer?.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick List Manager'),
        actions: [
          Obx(
            () => PopupMenuButton<String>(
              initialValue: controller.selectedStatusFilter.value,
              onSelected: (String result) {
                controller.changeStatusFilter(result);
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'R',
                      child: Text('Released (Open)'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Y',
                      child: Text('Closed (Picked)'),
                    ),
                  ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: colorScheme.onPrimary),
                    const SizedBox(width: 6),
                    Text(
                      controller.selectedStatusFilter.value == 'R'
                          ? 'Released'
                          : 'Closed',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: colorScheme.onPrimary),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
            tooltip: 'Refresh Picklists',
            onPressed: () => controller.fetchPickList(reset: true),
          ),
        ],
        elevation: 2,
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Loading();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: colorScheme.error, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchPickList(),
                    icon: const Icon(Icons.replay),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 16.0),
              // padding: const EdgeInsets.only(right: 16.0), // tambahkan ini
              child: Align(
                alignment: Alignment.centerRight,

                child: Obx(() {
                  final warehouses = itemController.selectedWarehouses.toList();

                  if (warehouses.isEmpty) return const SizedBox();

                  return GestureDetector(
                    onTapDown: (details) {
                      final Offset offset = details.globalPosition;
                      final double dx =
                          offset.dx + MediaQuery.of(context).size.width;
                      final double dy = offset.dy;

                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(dx, dy, 0, 0),
                        items: [
                          PopupMenuItem<String>(
                            enabled: false,
                            padding:
                                EdgeInsets.zero, // Hindari padding default item
                            child: Obx(
                              () => Material(
                                color: Colors.white, // 💥 Material putih solid
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ), // ukuran teks lebih besar
                                      decoration: const InputDecoration(
                                        hintText: 'Cari warehouse...',
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(),
                                        isDense:
                                            true, // rapat tapi tetap nyaman
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical:
                                              12, // padding lebih luas secara vertikal
                                        ),
                                      ),
                                      onChanged:
                                          (value) => itemController
                                              .filterWarehouseSearch(value),
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
                                                  w; // cari nama
                                              return ListTile(
                                                title: Text(
                                                  name,
                                                ), // ✅ tampilkan nama gudangnya
                                                tileColor: Colors.white,
                                                textColor: Colors.black,
                                                onTap: () {
                                                  itemController
                                                      .selectedWarehouseFilter
                                                      .value = w;
                                                  controller.fetchPickList(
                                                    reset: true,
                                                    source:
                                                        controller
                                                            .searchQuery
                                                            .value,
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
                            itemController.selectedWarehouseFilter.value.isEmpty
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
                  );
                }),
              ),
            ),
            if (controller.displayedPicklists.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        color: Colors.grey[400],
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No picklists found for ${controller.selectedStatusFilter.value == 'R' ? 'Released' : 'Closed'} status.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              // ... kode sebelum ListView tetap tidak diubah
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  controller: controller.scrollController,
                  itemCount:
                      MediaQuery.of(context).size.width > 800
                          ? controller.displayedPicklists.length +
                              1 // <— tambahkan header
                          : controller.displayedPicklists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final isWeb = screenWidth > 800;

                    if (isWeb) {
                      if (index == 0) {
                        // ===== HEADER BARIS =====
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Total Items',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Pick Date',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Remarks',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(width: 30),
                            ],
                          ),
                        );
                      }

                      // ===== ROW DATA ACTUAL =====
                      final actualIndex = index - 1; // <— penting
                      final picklist =
                          controller.displayedPicklists[actualIndex];
                      final bool isViewOnly = picklist['Status'] == 'Y';

                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: InkWell(
                          onTap: () {
                            controller
                                .currentProcessingPicklist
                                .value = Map<String, dynamic>.from(picklist);
                            Get.to(
                              () => PicklistDetailPage(isViewOnly: isViewOnly),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    picklist['Name'] ?? 'No Name',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${(picklist['DocumentLine'] as List).length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    format.formatPickDate(picklist['PickDate']),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    picklist['Remarks'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: StatusBadge(
                                    text: isViewOnly ? 'Closed' : 'Released',
                                    backgroundColor:
                                        isViewOnly
                                            ? Colors.red.shade100
                                            : Colors.blue.shade100,
                                    textColor:
                                        isViewOnly
                                            ? Colors.red.shade600
                                            : Colors.blue.shade600,
                                    icon:
                                        isViewOnly
                                            ? Icons.lock_outline
                                            : Icons.check_circle_outline,
                                  ),
                                ),
                                if (!isViewOnly) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      controller
                                          .currentProcessingPicklist
                                          .value = Map<String, dynamic>.from(
                                        picklist,
                                      );
                                      showPickListDialog(
                                        context,
                                        controller
                                            .currentProcessingPicklist
                                            .value!['Absoluteentry'],
                                      );
                                      // controller.currentProcessingPicklist.value =
                                      //     Map<String, dynamic>.from(picklist);
                                      // Get.to(() => PicklistDetailPage(isViewOnly: false));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: const Text('Edit'),
                                  ),
                                  // const SizedBox(width: 6),
                                  // OutlinedButton(
                                  //   onPressed: () {
                                  //     print(picklist);
                                  //     controller.currentProcessingPicklist.value =
                                  //               Map<String, dynamic>.from(picklist);
                                  //               controller.cancelPickList(
                                  //                 controller.currentProcessingPicklist.value!['Absoluteentry'],
                                  //               );
                                  //   },
                                  //   style: OutlinedButton.styleFrom(
                                  //     padding: const EdgeInsets.symmetric(
                                  //       horizontal: 10,
                                  //       vertical: 6,
                                  //     ),
                                  //     foregroundColor: Colors.red,
                                  //     side: const BorderSide(color: Colors.red),
                                  //     textStyle: const TextStyle(fontSize: 12),
                                  //   ),
                                  //   child: const Text('Cancel'),
                                  // ),
                                ],
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // ===== MOBILE VIEW (tetap seperti sebelumnya) =====
                    final picklist = controller.displayedPicklists[index];
                    final bool isViewOnly = picklist['Status'] == 'Y';

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              isViewOnly
                                  ? colorScheme.error
                                  : colorScheme.primary,
                          width: 1.2,
                        ),
                      ),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          controller
                              .currentProcessingPicklist
                              .value = Map<String, dynamic>.from(picklist);
                          Get.to(
                            () => PicklistDetailPage(isViewOnly: isViewOnly),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isViewOnly
                                        ? Icons.lock_outline
                                        : Icons.playlist_add_check,
                                    color:
                                        isViewOnly
                                            ? colorScheme.error
                                            : colorScheme.primary,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          picklist['Name'] ?? 'No Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Total Items: ${(picklist['DocumentLine'] as List).length}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pick Date: ${format.formatPickDate(picklist['PickDate'])}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Remarks: ${picklist['Remarks'] ?? '-'}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(
                                    text: isViewOnly ? 'Closed' : 'Released',
                                    backgroundColor:
                                        isViewOnly
                                            ? Colors.red.shade100
                                            : Colors.blue.shade100,
                                    textColor:
                                        isViewOnly
                                            ? Colors.red.shade600
                                            : Colors.blue.shade600,
                                    icon:
                                        isViewOnly
                                            ? Icons.lock_outline
                                            : Icons.check_circle_outline,
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Divider di luar padding
                            const Divider(height: 1, thickness: 1),

                            // Bagian tombol
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  if (!isViewOnly)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        controller
                                            .currentProcessingPicklist
                                            .value = Map<String, dynamic>.from(
                                          picklist,
                                        );
                                        showPickListDialog(
                                          context,
                                          controller
                                              .currentProcessingPicklist
                                              .value!['Absoluteentry'],
                                        );
                                      },
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  // const SizedBox(width: 8),
                                  // if (!isViewOnly)
                                  //   OutlinedButton.icon(
                                  //     onPressed: () {
                                  //       controller.currentProcessingPicklist.value =
                                  //           Map<String, dynamic>.from(picklist);
                                  //       controller.cancelPickList(
                                  //         controller.currentProcessingPicklist.value!['Absoluteentry'],
                                  //       );
                                  //     },
                                  //     icon: const Icon(Icons.cancel, size: 16),
                                  //     label: const Text('Cancel'),
                                  //     style: OutlinedButton.styleFrom(
                                  //       foregroundColor: colorScheme.error,
                                  //       side: BorderSide(color: colorScheme.error),
                                  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  //       textStyle: const TextStyle(fontSize: 13),
                                  //     ),
                                  //   ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusSummaryCard(String status, int total, Color color) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          children: [
            Text(
              '$total',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showWarehouseFilterMenu(BuildContext context, Offset offset) {
    final itemController = ItemController();
    itemController.filteredWarehouseList.assignAll(
      itemController.selectedWarehouses,
    );

    final controller = PicklistController();
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
                            (value) => controller.fetchPickList(
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
                                  controller.fetchPickList(
                                    reset: true,
                                    source: controller.searchQuery.value,
                                    warehouse: w,
                                  );
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

void showPickListDialog(BuildContext context, int id_picklist) {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<PicklistController>();
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

                        if (filter == null || filter.isEmpty) return allPickers;

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
                      // itemAsString: (picker) => picker['nama'] ?? '',
                      itemAsString: (picker) {
                        final nama = picker['nama'] ?? ''; 
                          final outstanding=   controller.outstandingPickList
                            .firstWhere(
                              (o) => o['Name'].toString().toLowerCase() == nama.toString().toLowerCase(),
                              orElse: () => {"Count": 0},
                            )['Count'];
                        return "$nama (Outstanding : ${outstanding ?? 0})";
                      },
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
                              controller.updatePickList(
                                pickDate: selectedDate.value,
                                pickerName:
                                    controller.selectedPicker.value?['nama'] ??
                                    '',
                                note: tempNote.text,
                                warehouse:
                                    ItemController()
                                        .selectedWarehouseFilter
                                        .value,
                                id_picklist: id_picklist,
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

class CircularLoadingIndicator extends StatelessWidget {
  const CircularLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
        const SizedBox(height: 18),
        Text(
          'Loading Picklists...',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class AnimatedStatusSummaryCard extends StatefulWidget {
  final String status;
  final int total;
  final Color startColor;
  final Color endColor;
  final IconData icon;

  const AnimatedStatusSummaryCard({
    super.key,
    required this.status,
    required this.total,
    required this.startColor,
    required this.endColor,
    required this.icon,
  });

  @override
  State<AnimatedStatusSummaryCard> createState() =>
      _AnimatedStatusSummaryCardState();
}

class _AnimatedStatusSummaryCardState extends State<AnimatedStatusSummaryCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.startColor, widget.endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.endColor.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.total}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
