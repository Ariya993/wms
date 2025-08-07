import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/list_user_controller.dart';
import 'user_manage_page.dart';
import 'user_grant_page.dart';
import 'user_setting_warehouse.dart';

class ListUserPage extends StatelessWidget {
  final ListUserController userController = Get.put(ListUserController());
  final TextEditingController searchController = TextEditingController();
  final RxString searchKeyword = ''.obs;

  ListUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List User'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) => searchKeyword.value = value.toLowerCase(),
              decoration: InputDecoration(
                hintText: 'Serach by nama, leader, warehouse ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // 📋 List User
          Expanded(
            child: Obx(() {
              if (userController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // ✨ filter + konversi ke List<Map<String,dynamic>>
              final filteredUsers =
                  userController.users
                      .where((user) {
                        final keyword = searchKeyword.value;
                        final nama =
                            (user['nama'] ?? '').toString().toLowerCase();
                        final username =
                            (user['username'] ?? '').toString().toLowerCase();
                        final atasan =
                            (user['atasan'] ?? '').toString().toLowerCase();
                        final warehouse =
                            (user['WarehouseName'] ?? '')
                                .toString()
                                .toLowerCase();
                        return nama.contains(keyword) ||
                            username.contains(keyword) ||
                            atasan.contains(keyword) ||
                            warehouse.contains(keyword);
                      })
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

              if (filteredUsers.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              final screenWidth = MediaQuery.of(context).size.width;
              final isWeb = screenWidth >= 800;

              // 🌐 ➝ TABLE (web)
              if (isWeb) {
                return buildUserTable(filteredUsers);
              }

              // 📱 ➝ LIST CARD (mobile)
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => _buildUserActionSheet(context, user),
                      );
                    },
                    child: _buildUserCard(user),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        onPressed: () async {
          await Get.to(() => UserManagePage());
          userController.loadUsers();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New User', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.grey[100],
    );
  }

 Widget buildUserTable(List<Map<String, dynamic>> users) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    child: DataTable(
      showCheckboxColumn: false, // << biar gak muncul checkbox
      columnSpacing: 36,
      headingRowColor:
          MaterialStateColor.resolveWith((states) => Colors.blue.shade50),
      columns: const [
        DataColumn(label: Text('Nama')),
        DataColumn(label: Text('Username')),
        DataColumn(label: Text('Warehouse')),
        DataColumn(label: Text('Leader')),
        DataColumn(label: Text('')),
      ],
      rows: users.map((user) {
        return DataRow(
          onSelectChanged: (selected) {
            showModalBottomSheet(
              context: Get.context!,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => _buildUserActionSheet(Get.context!, user),
            );
          },
          cells: [
            DataCell(Text(user['nama'] ?? '-')),
            DataCell(Text(user['username'] ?? '-')),
            DataCell(Text(user['WarehouseName'] ?? '-')),
            DataCell(Text(user['atasan'] ?? '-')),
            const DataCell(
              Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        );
      }).toList(),
    ),
  );
}


  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nama'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Username: ${user['username'] ?? '-'}"),
                  Text("Warehouse: ${user['WarehouseName'] ?? '-'}"),
                  Text("Leader: ${user['atasan'] ?? '-'}"),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, size: 28, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActionSheet(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    return SafeArea(
      // Ini akan menghindari area yang tertutup oleh sistem
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit User'),
            onTap: () async {
              Navigator.pop(context);
              await Get.to(() => UserManagePage(userData: user));
              userController.loadUsers();
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Grant Akses'),
            onTap: () {
              Navigator.pop(context);
              Get.to(
                () => UserGrantPage(
                  userId: user['id'] ?? 0,
                  namaUser: user['nama'] ?? '',
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Setting Warehouse'),
            onTap: () {
              Navigator.pop(context);
              Get.to(
                () => UserWarehouseSettingPage(
                  userId: user['id'] ?? 0,
                  username: user['nama'] ?? '',
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  
}
class UserDataSource extends DataTableSource {
  final List<Map<String, dynamic>> users;
  final void Function(Map<String, dynamic> user) onRowTap;

  UserDataSource(this.users, this.onRowTap);

  @override
  DataRow getRow(int index) {
    final user = users[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(user['nama'] ?? '-')),
        DataCell(Text(user['username'] ?? '-')),
        DataCell(Text(user['WarehouseName'] ?? '-')),
        DataCell(Text(user['atasan'] ?? '-')),
        const DataCell(Icon(Icons.chevron_right, color: Colors.grey)),
      ],
      onSelectChanged: (_) => onRowTap(user),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}
