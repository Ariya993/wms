import 'package:get/get.dart'; 
import '../controllers/warehouse_auth_controller.dart';

class WarehouseAuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WarehouseAuthController>(() => WarehouseAuthController());
  }
}
