import 'package:get/get.dart';
import 'package:wms/controllers/pick_pack_controller.dart';

import '../controllers/item_controller.dart'; 

class PickPackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PickPackController>(() => PickPackController());
     Get.lazyPut<ItemController>(() => ItemController());
  }
}
