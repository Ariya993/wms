import 'package:get/get.dart';
import 'package:wms/controllers/stock_opname_controller.dart';
import '../controllers/item_controller.dart'; 

class OpnameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ItemController>(() => ItemController());
    Get.lazyPut<StockOpnameController>(() => StockOpnameController());
  }
}
