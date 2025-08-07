import 'package:get/get.dart';
import 'package:wms/controllers/list_inventory_in_controller.dart';

import '../controllers/item_controller.dart';
 

class ListInventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListInventoryInController>(() => ListInventoryInController());
      Get.lazyPut<ItemController>(() => ItemController());
  }
}
