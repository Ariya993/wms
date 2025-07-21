import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/home_controller.dart';
import '../main_common.dart';
import '../widgets/loading.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Penting untuk deteksi platform

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController controller = Get.put(HomeController());
  final GetStorage box = GetStorage();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double webLayoutThreshold = 800;

    if (kIsWeb && screenWidth >= webLayoutThreshold) {
      return _WebLayout(controller: controller, box: box);
    } else {
      return _MobileLayout(controller: controller, box: box);
    }
  }
}

// --- Widget untuk Tampilan Mobile (Tidak Ada Perubahan) ---
class _MobileLayout extends StatefulWidget {
  final HomeController controller;
  final GetStorage box;

  const _MobileLayout({required this.controller, required this.box});

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  int selectedCategoryIndex = 0;

  Color _getCardAccentColor(int index) {
    final List<Color> colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.amber.shade600,
    ];
    return colors[index % colors.length];
  }

  IconData _getMaterialIcon(String? iconName) {
    final iconMap = <String, IconData>{
      "inventory": Icons.inventory_2_outlined,
      "receipt_long": Icons.receipt_long_outlined,
      "assignment": Icons.assignment_outlined,
      "print": Icons.print_outlined,
      "settings": Icons.settings_outlined,
      "dashboard": Icons.dashboard_outlined,
      "people": Icons.people_outline,
      "analytics": Icons.analytics_outlined,
      "notifications": Icons.notifications_outlined,
      "add_shopping_cart": Icons.add_shopping_cart_outlined,
      "bar_chart": Icons.bar_chart_outlined,
      "calendar_today": Icons.calendar_today_outlined,
      "security": Icons.security_outlined,
      "data_usage": Icons.data_usage_outlined,
      "category": Icons.category_outlined,
      "location_on": Icons.location_on_outlined,
      "support": Icons.support_agent_outlined,
      "swap_horiz": Icons.swap_horiz_outlined,
      "rule": Icons.rule_outlined,
      "auto_responders": Icons.chat_bubble_outline,
      "phone_book": Icons.book_outlined,
      "campaigns": Icons.mail_outline,
      "single_sender": Icons.send_outlined,
      "rest_api": Icons.local_fire_department_outlined,
    };
    return iconMap[iconName] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final storedUsername = widget.box.read('username') ?? 'Guest';
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;
    double horizontalPadding;

    if (screenWidth < 400) {
      crossAxisCount = 2;
      childAspectRatio = 0.6;
      horizontalPadding = 16;
    } else if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.7;
      horizontalPadding = 16;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      horizontalPadding = 32;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Row(
          children: [
            if (screenWidth < 600)
              Text(
                (appEnvironment==Environment.dev ? 'DEV WMS Mobile' :'WMS Mobile'),
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              )
            else
              Text(
                "Warehouse Management System",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade600,
                size: 28,
              ),
              onPressed: () {
                widget.controller.logout();
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() {
        if (widget.controller.isLoading.value) {
          return const Loading();
        }

        if (widget.controller.menus.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 20),
                Text(
                  "No modules available yet.",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please check your permissions or contact administrator.",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final Map<String, List<Map<String, dynamic>>> groupedMenus = {};
        for (var menu in widget.controller.menus) {
          final kategori = menu['category'] ?? 'General Modules';
          groupedMenus.putIfAbsent(kategori, () => []).add(menu);
        }
        final kategoriList = groupedMenus.keys.toList();

        final List<IconData> categoryIconsForNav = [Icons.home_outlined];
        for (var kategori in kategoriList) {
          final firstMenu = groupedMenus[kategori]?.first;
          if (firstMenu != null) {
            categoryIconsForNav.add(_getMaterialIcon(firstMenu['icon']));
          } else {
            categoryIconsForNav.add(Icons.category_outlined);
          }
        }
        final List<String> categoryLabelsForNav = ['Home', ...kategoriList];

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await widget.controller
                      .fetchData(); // Pastikan fetchData adalah Future
                },
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // wajib agar bisa di-refresh meski data pendek
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $storedUsername!',
                        style: TextStyle(
                          fontSize: screenWidth < 600 ? 20 : 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome to Warehouse Management System - PT Sany Makmur Perkasa',
                        style: TextStyle(
                          fontSize: screenWidth < 600 ? 16 : 19,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (selectedCategoryIndex == 0)
                        ...kategoriList.map((cat) {
                          final moduls = groupedMenus[cat]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: screenWidth < 600 ? 22 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                              const Divider(
                                height: 24,
                                thickness: 1,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: moduls.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio: childAspectRatio,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                    ),
                                itemBuilder: (context, index) {
                                  final item = moduls[index];
                                  final accentColor = _getCardAccentColor(
                                    index,
                                  );
                                  return _buildModuleCard(
                                    context,
                                    title: item['title'] ?? 'Module',
                                    description: item['description'] ?? '',
                                    icon: _getMaterialIcon(item['icon']),
                                    accentColor: accentColor,
                                    onTap: () => Get.toNamed(item['route']),
                                    screenWidth: screenWidth,
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }).toList()
                      else
                        Builder(
                          builder: (context) {
                            if (selectedCategoryIndex - 1 < 0 ||
                                selectedCategoryIndex - 1 >=
                                    kategoriList.length) {
                              return const Center(
                                child: Text("Kategori tidak ditemukan."),
                              );
                            }
                            final selectedCategory =
                                kategoriList[selectedCategoryIndex - 1];
                            final displayedMenus =
                                groupedMenus[selectedCategory]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedCategory,
                                  style: TextStyle(
                                    fontSize: screenWidth < 600 ? 22 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                const Divider(
                                  height: 24,
                                  thickness: 1,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: displayedMenus.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: childAspectRatio,
                                        crossAxisSpacing: 20,
                                        mainAxisSpacing: 20,
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = displayedMenus[index];
                                    final accentColor = _getCardAccentColor(
                                      index,
                                    );
                                    return _buildModuleCard(
                                      context,
                                      title: item['title'] ?? 'Module',
                                      description: item['description'] ?? '',
                                      icon: _getMaterialIcon(item['icon']),
                                      accentColor: accentColor,
                                      onTap: () => Get.toNamed(item['route']),
                                      screenWidth: screenWidth,
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 5,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: selectedCategoryIndex,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.blue.shade700,
                unselectedItemColor: Colors.grey.shade600,
                onTap: (index) {
                  setState(() {
                    selectedCategoryIndex = index;
                  });
                },
                items: List.generate(
                  categoryLabelsForNav.length,
                  (index) => BottomNavigationBarItem(
                    icon: Icon(categoryIconsForNav[index]),
                    label: (categoryLabelsForNav[index]),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(height: 8, color: accentColor.withOpacity(0.8)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: screenWidth < 600 ? 45 : 55,
                        color: accentColor.withOpacity(0.8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth < 600 ? 17 : 20,
                          color: accentColor.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: screenWidth < 600 ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widget untuk Tampilan Web (MODIFIKASI DISINI) ---
class _WebLayout extends StatefulWidget {
  final HomeController controller;
  final GetStorage box;

  const _WebLayout({required this.controller, required this.box});

  @override
  State<_WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<_WebLayout> {
  // selectedCategoryIndex akan melacak kategori yang dipilih di sidebar.
  // Indeks 0 = Home (tampilkan semua modul dari semua kategori)
  // Indeks 1..n = Kategori spesifik
  int selectedCategoryIndex = 0;

  Color _getCardAccentColor(int index) {
    final List<Color> colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.amber.shade600,
    ];
    return colors[index % colors.length];
  }

  IconData _getMaterialIcon(String? iconName) {
    final iconMap = <String, IconData>{
      "inventory": Icons.inventory_2_outlined,
      "receipt_long": Icons.receipt_long_outlined,
      "assignment": Icons.assignment_outlined,
      "print": Icons.print_outlined,
      "settings": Icons.settings_outlined,
      "dashboard": Icons.dashboard_outlined,
      "people": Icons.people_outline,
      "analytics": Icons.analytics_outlined,
      "notifications": Icons.notifications_outlined,
      "add_shopping_cart": Icons.add_shopping_cart_outlined,
      "bar_chart": Icons.bar_chart_outlined,
      "calendar_today": Icons.calendar_today_outlined,
      "security": Icons.security_outlined,
      "data_usage": Icons.data_usage_outlined,
      "category": Icons.category_outlined,
      "location_on": Icons.location_on_outlined,
      "support": Icons.support_agent_outlined,
      "swap_horiz": Icons.swap_horiz_outlined,
      "rule": Icons.rule_outlined,
      "auto_responders": Icons.chat_bubble_outline,
      "phone_book": Icons.book_outlined,
      "campaigns": Icons.mail_outline,
      "single_sender": Icons.send_outlined,
      "rest_api": Icons.local_fire_department_outlined,
    };
    return iconMap[iconName] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final storedUsername = widget.box.read('username') ?? 'Guest';
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;
    double horizontalPadding;

    if (screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      horizontalPadding = 32;
    } else if (screenWidth < 1200) {
      crossAxisCount = 4;
      childAspectRatio = 1;
      horizontalPadding = 48;
    } else {
      crossAxisCount = 5;
      childAspectRatio = 1;
      horizontalPadding = 84;
    }

    final Map<String, List<Map<String, dynamic>>> groupedMenus = {};
    for (var menu in widget.controller.menus) {
      final kategori = menu['category'] ?? 'General Modules';
      groupedMenus.putIfAbsent(kategori, () => []).add(menu);
    }
    final kategoriList = groupedMenus.keys.toList();

    final List<Map<String, dynamic>> sidebarNavItems = [
      {'title': 'Home', 'icon': Icons.home_outlined},
      ...kategoriList.map((catName) {
        final firstMenuInCat = groupedMenus[catName]?.first;
        return {
          'title': catName,
          'icon': _getMaterialIcon(firstMenuInCat?['icon']),
        };
      }).toList(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Row(
          children: [
            Text(
              "Warehouse Management System",
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade600,
                size: 28,
              ),
              onPressed: () {
                widget.controller.logout();
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Kustom (Tidak ada perubahan signifikan di sini)
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(3, 0),
                ),
              ],
            ),
            child: Obx(() {
              if (widget.controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              if (widget.controller.menus.isEmpty &&
                  sidebarNavItems.length <= 1) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "No modules or categories to display.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Text(
                      'MAIN',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...List.generate(sidebarNavItems.length, (index) {
                    final item = sidebarNavItems[index];
                    return _buildSidebarMenuItem(
                      context,
                      title: item['title'],
                      icon: item['icon'],
                      isSelected: selectedCategoryIndex == index,
                      onTap: () {
                        setState(() {
                          selectedCategoryIndex = index;
                        });
                      },
                    );
                  }),
                ],
              );
            }),
          ),
          // Area konten utama yang diubah
          Expanded(
            child: Column(
              // Menggunakan Column agar header tetap dan konten bisa discroll
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // Header "Hi, ariya!" dan "Welcome to..." dipisahkan
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $storedUsername!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome to Warehouse Management System - PT Sany Makmur Perkasa',
                        style: TextStyle(
                          fontSize: 19,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                // Bagian ini yang akan berubah dan dapat digulir secara terpisah
                Expanded(
                  // Tambahkan Expanded di sini agar ListView bisa mengambil sisa ruang
                  child: Obx(() {
                    if (widget.controller.isLoading.value) {
                      return const Loading();
                    }

                    if (widget.controller.menus.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dashboard_customize_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "No modules available yet.",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Please check your permissions or contact administrator.",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    List<Map<String, dynamic>> displayedMenus;
                    String currentTitle = "Modules";

                    if (selectedCategoryIndex == 0) {
                      displayedMenus =
                          widget.controller.menus
                              .toList()
                              .cast<Map<String, dynamic>>(); // Cast for safety
                      currentTitle = "All Modules";
                    } else {
                      final int actualCategoryIndex = selectedCategoryIndex - 1;
                      if (actualCategoryIndex < 0 ||
                          actualCategoryIndex >= kategoriList.length) {
                        displayedMenus = [];
                        currentTitle = "Category Not Found";
                      } else {
                        final selectedCategoryName =
                            kategoriList[actualCategoryIndex];
                        // Pastikan ini juga di-cast
                        displayedMenus =
                            (groupedMenus[selectedCategoryName] ?? [])
                                .cast<Map<String, dynamic>>();
                        currentTitle = selectedCategoryName;
                      }
                    }

                    return SingleChildScrollView(
                      // Hanya bagian grid yang di-scroll
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical:
                            0, // Padding vertikal bisa 0 karena sudah ada di atas
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTitle,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                          const Divider(
                            height: 24,
                            thickness: 1,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          if (displayedMenus.isEmpty)
                            Center(
                              child: Text(
                                "No modules in this category.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(), // Penting: Jangan gulir grid itu sendiri
                              itemCount: displayedMenus.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                  ),
                              itemBuilder: (context, index) {
                                final item = displayedMenus[index];
                                final accentColor = _getCardAccentColor(index);
                                return _buildModuleCard(
                                  context,
                                  title: item['title'] ?? 'Module',
                                  description: item['description'] ?? '',
                                  icon: _getMaterialIcon(item['icon']),
                                  accentColor: accentColor,
                                  onTap: () => Get.toNamed(item['route']),
                                  screenWidth: screenWidth,
                                );
                              },
                            ),
                          const SizedBox(
                            height: 24,
                          ), // Memberi sedikit ruang di bawah grid
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Pembantu untuk Item Sidebar (di _WebLayout) ---
  Widget _buildSidebarMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration:
                isSelected
                    ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.shade400,
                          Colors.blueAccent.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    )
                    : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget untuk card modul (tetap sama)
  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(height: 8, color: accentColor.withOpacity(0.8)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: screenWidth < 600 ? 35 : 45,
                        color: accentColor.withOpacity(0.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth < 600 ? 16 : 18,
                          color: accentColor.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      // const SizedBox(height: 6),
                      // Text(
                      //   description,
                      //   style: TextStyle(
                      //     fontSize: screenWidth < 600 ? 12 : 14,
                      //     color: Colors.grey.shade600,
                      //   ),
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      //   textAlign: TextAlign.center,
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
