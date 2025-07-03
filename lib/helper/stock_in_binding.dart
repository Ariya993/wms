import 'package:get/get.dart';
import '../controllers/stock_in_controller.dart';

class StockInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockInController>(() => StockInController());
  }
}
