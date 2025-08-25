import 'package:get/get.dart';
import 'package:wms/controllers/home_controller.dart';
import 'package:wms/helper/list_user_binding.dart';
import 'package:wms/pages/pick_pack_page.dart';
import 'package:wms/pages/stock_opname_page.dart';
import '../helper/adjustment_stock_binding.dart';
import '../helper/list_inventory_binding.dart';
import '../helper/list_opname_binding.dart';
import '../helper/opname_binding.dart';
import '../helper/pick_pack_binding.dart';
import '../helper/picklist_binding.dart';
import '../helper/stock_in_binding.dart';
import '../helper/warehouse_auth_binding.dart';
import '../pages/adjustment_stock_page.dart';
import '../pages/list_inventory_in_page.dart';
import '../pages/list_opname.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart'; 
import '../pages/item_page.dart'; 
import '../pages/picklist_page.dart';
import '../pages/printer_page.dart'; 
import '../helper/printer_binding.dart';
import '../helper/item_binding.dart';
import '../pages/stock_in_page.dart';
import '../pages/list_user_page.dart';
import '../pages/unsupported_version.dart';
import '../pages/warehouse_auth_page.dart';
class AppRoutes { 

  static final routes = [
      GetPage(
        name: '/home',
        page: () => HomePage(),
        binding: BindingsBuilder(() {
          Get.lazyPut(() => HomeController());
        }),
      ),
      GetPage(name: '/unsupported', page: () => UnsupportedVersionPage()),
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
       GetPage(
        name: '/pickpack',
        page: () => PickPackManagerPage(),
        binding: PickPackBinding(),  
      ),
      GetPage(
        name: '/picklist',
        page: () => PicklistsPage(),
        binding: PickListBinding(),  
      ),
       GetPage(
        name: '/warehouse-auth',
        page: () => WarehouseAuthPage(),
        binding: WarehouseAuthBinding(),  
      ),
      GetPage(
        name: '/listinventory',
        page: () => ListInventoryInPage(),
        binding: ListInventoryBinding(),  
      ),
      GetPage(
        name: '/list-opname',
        page: () => ListOpnamePage(),
        binding: ListOpnameBinding(),  
      ),
      GetPage(
        name: '/opname',
        page: () => StockOpnamePage(),
        binding: OpnameBinding(),  
      ),
      GetPage(
        name: '/adjustment-stock',
        page: () => AdjustmentStockPage(),
        binding: AdjustmentStockBinding(),  
      ),
  ];
}
