import 'package:get/get.dart';
import '../controllers/item_controller.dart';
import '../controllers/stock_in_controller.dart';

class StockInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ItemController>(() => ItemController());
    Get.lazyPut<StockInController>(() => StockInController());
  }
}
