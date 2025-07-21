import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/warehouse_auth_controller.dart';
import '../helper/encrypt.dart';
import '../widgets/custom_text_field.dart';

class WarehouseAuthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WarehouseAuthController());
    final searchController = TextEditingController();
    final isWideScreen = MediaQuery.of(context).size.width > 700;
    final box = GetStorage();
    controller.sapDbName.value = box.read('sap_db_name');
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            'Warehouse Authorization : ${controller.sapDbName.value}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomTextField(
                controller: searchController,
                labelText: 'Search Warehouse',
                hintText: 'Enter warehouse name or code',
                onChanged: controller.filterWarehouses,
              ),
            ),
            Expanded(
              child: Obx(() {
                final warehouses = controller.filteredWarehouses;
                if (isWideScreen) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: warehouses.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3,
                        ),
                    itemBuilder: (_, index) {
                      return _buildWarehouseCard(
                        context,
                        controller,
                        warehouses[index],
                      );
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: warehouses.length,
                    itemBuilder: (_, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildWarehouseCard(
                          context,
                          controller,
                          warehouses[index],
                        ),
                      );
                    },
                  );
                }
              }),
            ),
            // Obx(() => Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(16),
            //   child: ElevatedButton(
            //     onPressed: controller.isLoading.value ? null : controller.submitData,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.blue.shade700,
            //       padding: const EdgeInsets.symmetric(vertical: 14),
            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //     ),
            //     child: controller.isLoading.value
            //         ? const CircularProgressIndicator(color: Colors.white)
            //         : const Text(
            //             'Submit All',
            //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            //           ),
            //   ),
            // )),
          ],
        ),
      ),
    );
  }
Widget _buildWarehouseCard(
  BuildContext context,
  WarehouseAuthController controller,
  Map<String, dynamic> warehouse,
) {
  return FutureBuilder<Map<String, dynamic>?>(
    future: controller.getWarehouseAuth(warehouse['warehouseCode']),
    builder: (context, snapshot) {
      final hasData = snapshot.hasData &&
          snapshot.data?['sap_username'] != null &&
          snapshot.data!['sap_username'].toString().isNotEmpty;

      return GestureDetector(
        onTap: () => _showCredentialBottomSheet(
          context,
          warehouse['warehouseCode'],
          warehouse['warehouseName'],
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: hasData ? Colors.green.shade100 : Colors.blue.shade100,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '${warehouse['warehouseCode']} - ${warehouse['warehouseName']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasData)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Configured',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
 
  void _showCredentialBottomSheet(
    BuildContext context,
    String warehouseCode,
    String warehouseName,
  ) async {
    final controller = Get.find<WarehouseAuthController>();
    final box = GetStorage();
    // Ambil data dari API berdasarkan warehouse_code
    final data = await controller.getWarehouseAuth(warehouseCode);
    final sapDb = data?['sap_db_name'] ?? box.read('sap_db_name');
    final sapUser = data?['sap_username'] ?? '';
    final sapPass = data?['sap_password'] ?? '';

    // Buat controller text dari data tersebut
    String pass = '';
    if (sapPass.isNotEmpty) {
      try {
        pass = AESHelper.decryptData(sapPass);
      } catch (e) {
        pass = ''; // Fallback kalau gagal decrypt
      }
    }
    TextEditingController dbController = TextEditingController(text: sapDb);
    TextEditingController userController = TextEditingController(text: sapUser);
    TextEditingController passController = TextEditingController(text: pass);
    controller.sapDbName.value = sapDb;
    controller.sapUsername.value = sapUser;
    controller.sapPassword.value = pass;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$warehouseCode - $warehouseName",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Divider(thickness: 1),

                CustomTextField(
                  controller: dbController,
                  labelText: 'SAP DB Name',
                  onChanged: (value) => controller.sapDbName.value = value,
                ),
                CustomTextField(
                  controller: userController,
                  labelText: 'SAP Username',
                  onChanged:
                      (value) =>  controller.sapUsername.value = value,  
                      // controller.setUsername(warehouseCode, value),
                ),
                CustomTextField(
                  controller: passController,
                  labelText: 'SAP Password',
                  obscureText: true,
                  onChanged:
                      (value) => controller.sapPassword.value = value, 
                      //controller.setPassword(warehouseCode, value),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await controller.submitSingleWarehouse(
                        warehouseCode: warehouseCode,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
