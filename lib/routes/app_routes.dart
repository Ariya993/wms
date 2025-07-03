import 'package:get/get.dart';
import 'package:wms/controllers/home_controller.dart';
import 'package:wms/helper/list_user_binding.dart';
import '../helper/stock_in_binding.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart'; 
import '../pages/item_page.dart'; 
import '../pages/printer_page.dart'; 
import '../helper/printer_binding.dart';
import '../helper/item_binding.dart';
import '../pages/stock_in_page.dart';
import '../pages/list_user_page.dart';
class AppRoutes { 

  static final routes = [
      GetPage(
        name: '/home',
        page: () => HomePage(),
        binding: BindingsBuilder(() {
          Get.lazyPut(() => HomeController());
        }),
      ),
      GetPage(name: '/login', page: () => LoginPage()),
      GetPage(
        name: '/select-printer',
        page: () => SelectPrinterPage(),
        binding: PrinterBinding(),  
      ),
      GetPage(
        name: '/items',
        page: () => ItemPage(),
        binding: ItemBinding(),  
      ),
      GetPage(
        name: '/stock-in',
        page: () => StockInPage(),
        binding: StockInBinding(),
      ),
       GetPage(
        name: '/user-manage',
        page: () => ListUserPage(),
        binding: ListUserBinding(),  
      ),
  ];
}
