import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/warehouse_auth_controller.dart';

class UserWarehouseSettingPage extends StatefulWidget  {
 final int userId;
  final String username;

  const UserWarehouseSettingPage({required this.userId, required this.username});

  @override
  _UserWarehouseSettingPageState createState() => _UserWarehouseSettingPageState();
}

class _UserWarehouseSettingPageState extends State<UserWarehouseSettingPage> {
   //final WarehouseAuthController controller = Get.put(WarehouseAuthController());
 late final WarehouseAuthController controller;

 @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<WarehouseAuthController>()) {
      controller = Get.put(WarehouseAuthController());
    } else {
      controller = Get.find<WarehouseAuthController>();
    }
    controller.loadUserWarehouses(widget.userId); // ✅ Load userId saat halaman dibuka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      appBar: AppBar(title: Text('Setting Warehouse: ${widget.username}')),
      body: Obx(() {
        if (controller.warehouses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: controller.filterWarehouses,
                decoration: const InputDecoration(
                  hintText: 'Search warehouse...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // Select All Checkbox
            Obx(() {
              final allCodes = controller.filteredWarehouses
                  .map<String>((w) => w['warehouseCode'].toString())
                  .toSet();

              final isAllSelected = allCodes.isNotEmpty &&
                  allCodes.every((code) => controller.selectedWarehouses.contains(code));

              return CheckboxListTile(
                title: const Text('Select All'),
                value: isAllSelected,
                onChanged: (_) => controller.toggleSelectAll(),
              );
            }),

            const Divider(),

            // List of checkboxes
            Expanded(
              child: Obx(() => ListView(
                children: controller.filteredWarehouses.map<Widget>((warehouse) {
                  final id = warehouse['warehouseCode'].toString();
                  final name = warehouse['warehouseName'] ?? 'Unnamed';

                  return Obx(() => CheckboxListTile(
                    title: Text(name),
                    value: controller.selectedWarehouses.contains(id),
                    onChanged: (_) => controller.toggleWarehouseSelection(id),
                  ));
                }).toList(),
              )),
            ),
          ],
        );
      }),
      bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(12.0),
  child: ElevatedButton.icon(
    icon: const Icon(Icons.save, color: Colors.white),
    label: const Text('Save', style: TextStyle(color: Colors.white)),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue, // warna background
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    onPressed: () => controller.saveWarehouseSetting(widget.userId),
  ),
),

    );
  }
}
