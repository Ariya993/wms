import 'package:get/get.dart';
import 'package:wms/controllers/picklist_controller.dart'; 

class PickListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PicklistController>(() => PicklistController());
  }
}
