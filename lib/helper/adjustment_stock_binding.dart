import 'package:get/get.dart';
import 'package:wms/controllers/adjustment_stock_controller.dart';
import '../controllers/item_controller.dart'; 

class AdjustmentStockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ItemController>(() => ItemController());
    Get.lazyPut<AdjutsmentStockController>(() => AdjutsmentStockController());
  }
}
