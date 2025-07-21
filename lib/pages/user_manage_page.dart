import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_manage_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown_search.dart';

class UserManagePage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  UserManagePage({super.key, this.userData});

  final UserManageController controller = Get.put(UserManageController());
  final RxBool isInitialized = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Manage"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!isInitialized.value && userData != null) {
          controller.usernameController.text = userData!['username'] ?? '';
          
          controller.nameController.text = userData!['nama'] ?? '';
          controller.passwordController.text = '';
        controller.emailController.text = userData!['email'] ?? '';
        controller.phoneController.text = userData!['phone'] ?? '';
          final warehouse = controller.warehouses.firstWhereOrNull(
            (w) => w['warehouseCode'] == userData!['warehouse_code'],
          );
          if (warehouse != null) controller.selectedWarehouse.value = warehouse;

          final atasan = controller.wmsUsers.firstWhereOrNull(
            (u) => u['id'] == userData!['id_atasan'],
          );
          if (atasan != null) controller.selectedSuperior.value = atasan;

          isInitialized.value = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   userData != null ? "Edit User" : "Tambah User Baru",
              //   style: TextStyle(
              //     fontSize: 24,
              //     fontWeight: FontWeight.bold,
              //     color: Theme.of(context).primaryColor,
              //   ),
              // ),
             // const SizedBox(height: 20),
              CustomTextField(
                controller: controller.usernameController,
                labelText: "Username",
                hintText: "Fill username", 
                readOnly: userData != null,
              ),
              CustomTextField(
                controller: controller.nameController,
                labelText: "Name",
                hintText: "Fill the name ", 
              ),
              CustomTextField(
                controller: controller.passwordController,
                labelText: "Password",
                hintText: "Fill password",
                obscureText: true, 
                // suffixIcon: IconButton(
                //   icon: const Icon(Icons.visibility),
                //   onPressed: () {
                //     // Implementasi toggle visibility password jika diperlukan
                //   },
                // ),
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: controller.emailController,
                labelText: "Email",
                hintText: "Fill the email ", 
              ),
               const SizedBox(height: 10),
              CustomTextField(
                controller: controller.phoneController,
                labelText: "Phone Number",
                hintText: "Fill the phone number ", 
              ),
                const SizedBox(height: 10),
              CustomDropdownSearch<Map<String, dynamic>>(
                labelText: "Atasan",
                selectedItem: controller.selectedSuperior.value,
                asyncItems: (String? filter) async {
                  if (filter == null || filter.isEmpty) {
                    return controller.wmsUsers.toList();
                  }
                  return controller.wmsUsers
                      .where((user) =>
                          (user['username'] as String).toLowerCase().contains(filter.toLowerCase()) ||
                          (user['nama'] as String).toLowerCase().contains(filter.toLowerCase()))
                      .toList();
                },
                onChanged: (user) {
                  controller.selectedSuperior.value = user;
                  final warehouseCode = user?['warehouse_code'];
                    if (warehouseCode != null) {
                      final matchingWarehouse = controller.warehouses.firstWhereOrNull(
                        (w) => w['warehouseCode'] == warehouseCode,
                      );
                      if (matchingWarehouse != null) {
                        controller.selectedWarehouse.value = matchingWarehouse;
                      }
                    }
                },
                itemAsString: (Map<String, dynamic> user) => '${user['nama']}',
                compareFn: (item1, item2) => item1['id'] == item2['id'],
                validator: (Map<String, dynamic>? user) {
                  if (user == null) {
                    return "Please select a leader";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              CustomDropdownSearch<Map<String, dynamic>>(
                labelText: "Warehouse",
                selectedItem: controller.selectedWarehouse.value,
                asyncItems: (String? filter) async {
                  if (filter == null || filter.isEmpty) {
                    return controller.warehouses.toList();
                  }
                  return controller.warehouses
                      .where((wh) =>
                          (wh['warehouseCode'] as String).toLowerCase().contains(filter.toLowerCase()) ||
                          (wh['warehouseName'] as String).toLowerCase().contains(filter.toLowerCase()))
                      .toList();
                },
                onChanged: (warehouse) {
                  controller.selectedWarehouse.value = warehouse;
                },
                itemAsString: (Map<String, dynamic> wh) =>
                    '${wh['warehouseCode']} - ${wh['warehouseName']}',
                compareFn: (item1, item2) => item1['warehouseCode'] == item2['warehouseCode'],
                // validator: (Map<String, dynamic>? wh) {
                //   if (wh == null) {
                //     return "Warehouse harus dipilih";
                //   }
                //   return null;
                // },
              ),
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading.value ? null : () => (userData != null ?  controller.updateUser(userData!['id']) :  controller.createUser()) ,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add_task),
                  label: Text(
                    controller.isLoading.value
                        ? (userData != null ? "Please wait..." : "Please wait...")
                        : (userData != null ? "Update User" : "Save User"),
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
