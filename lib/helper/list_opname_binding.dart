import 'package:get/get.dart';
 
import '../controllers/item_controller.dart';
import '../controllers/list_opname_controller.dart';  

class ListOpnameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListOpnameController>(() => ListOpnameController());
     Get.lazyPut<ItemController>(() => ItemController());
  }
}
