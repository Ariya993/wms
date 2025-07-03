import 'package:flutter/material.dart';
import 'package:get/get.dart';  

import '../services/api_service.dart';

class UserGrantPage extends StatefulWidget {
  final int userId;
  final String namaUser;
  const UserGrantPage({super.key, required this.userId, required this.namaUser});

  @override
  State<UserGrantPage> createState() => _UserGrantPageState();
}

class _UserGrantPageState extends State<UserGrantPage> {
  final ApiService _userService = ApiService();
  List<Map<String, dynamic>> menus = [];
  Set<int> selectedMenuIds = {};
  bool isLoading = true;
  String namaUser = '';

  final Map<String, IconData> IconsMap = {
    'dashboard': Icons.dashboard,
    'receipt_long': Icons.receipt_long,
    'inventory': Icons.inventory,
    'print': Icons.print,
    'people': Icons.people,
    'settings': Icons.settings,
  };

  @override
  void initState() {
    super.initState();
    fetchUserMenus();
  }

  Future<void> fetchUserMenus() async {
    try {
      final List<dynamic> data = await _userService.fetchUserMenus(widget.userId);
   
      setState(() {
        menus = data.map((e) => Map<String, dynamic>.from(e)).toList();
 
       selectedMenuIds = menus
        .where((m) => m['akses'] == 1) // Ini adalah perbandingan integer yang benar
        .map<int>((m) => int.tryParse(m['id_menu'].toString()) ?? 0)
        .toSet(); 
        isLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    }
  }

  Future<void> saveAccess() async {
    try {
      await _userService.saveUserMenuAccess(widget.userId, selectedMenuIds);
      Get.snackbar('Success', 'Access has ben updated',snackPosition: SnackPosition.TOP,snackStyle: SnackStyle.FLOATING,backgroundColor: Colors.greenAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save access : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedMenus = <String, List<Map<String, dynamic>>>{};
    namaUser = widget.namaUser;
    for (var menu in menus) {
      final category = menu['category'] ?? 'Lainnya';
      if (!groupedMenus.containsKey(category)) {
        groupedMenus[category] = [];
      }
      groupedMenus[category]!.add(menu);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grant Akses'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white, 
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.blue.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Grant access : $namaUser',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: groupedMenus.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          ...items.map((menu) {
                            final idMenu = int.tryParse(menu['id_menu'].toString()) ?? 0;
                            return CheckboxListTile(
                              title: Text(menu['title'] ?? 'Menu'),
                              secondary: Icon(IconsMap[menu['icon']] ?? Icons.menu),
                              value: selectedMenuIds.contains(idMenu),
                              onChanged: (value) {
                                setState(() {
                                  print('Selected IDs: $selectedMenuIds');
                                  print('Raw menu data: $menus');

                                  if (value == true) {
                                    selectedMenuIds.add(idMenu);
                                  } else {
                                    selectedMenuIds.remove(idMenu);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: saveAccess,
          icon: const Icon(Icons.save),
          label: const Text('Save Access'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
