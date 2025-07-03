import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/home_controller.dart';
import '../widgets/loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController controller = Get.put(HomeController());
  final GetStorage box = GetStorage();

  int selectedCategoryIndex = 0; // 0 = Home (all), 1..n kategori

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
    };
    return iconMap[iconName] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final storedUsername = box.read('username') ?? 'Guest';
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid config
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
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      horizontalPadding = 32;
    } else if (screenWidth < 1200) {
      crossAxisCount = 4;
      childAspectRatio = 1;
      horizontalPadding = 48;
    } else {
      crossAxisCount = 5;
      childAspectRatio = 1.1;
      horizontalPadding = 84;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Row(
          children: [
            Icon(
              Icons.warehouse_outlined,
              color: Colors.blue.shade700,
              size: 30,
            ),
            const SizedBox(width: 8),
            screenWidth < 600 ?  
              Text(
                "WMS Mobile",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ) : 
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
                controller.logout();
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) { 
        return const Loading();
 
        }

        if (controller.menus.isEmpty) {
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

        // Group menus by category
        final Map<String, List<Map<String, dynamic>>> groupedMenus = {};
        for (var menu in controller.menus) {
          final kategori = menu['category'] ?? 'General Modules';
          groupedMenus.putIfAbsent(kategori, () => []).add(menu);
        }

        final kategoriList = groupedMenus.keys.toList();

        // Build list of category icons (from first menu icon of each category)
        final List<IconData> categoryIcons = [];
        for (var kategori in kategoriList) {
          final firstMenu = groupedMenus[kategori]?.first;
          if (firstMenu != null) {
            categoryIcons.add(_getMaterialIcon(firstMenu['icon']));
          } else {
            categoryIcons.add(Icons.category_outlined);
          }
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                      'Navigate your warehouse operations with ease.',
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
                                final accentColor = _getCardAccentColor(index);
                                return _buildModuleCard(
                                  context,
                                  title: item['title'] ?? 'Module',
                                  description:
                                      item['description'] ??
                                      '',
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
                      // Jika kategori dipilih selain Home, tampilkan 1 kategori saja
                      Builder(
                        builder: (context) {
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
                                    description:
                                        item['description'] ??
                                        '',
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

            // BottomNavigationBar tetap sama
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
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  ...kategoriList.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String cat = entry.value;
                    return BottomNavigationBarItem(
                      icon: Icon(categoryIcons[idx]),
                      label: cat,
                    );
                  }).toList(),
                ],
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
