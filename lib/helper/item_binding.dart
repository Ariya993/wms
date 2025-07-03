import 'package:get/get.dart';
import 'package:wms/controllers/item_controller.dart';
import 'package:wms/controllers/printer_controller.dart';
 
class ItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ItemController>(() => ItemController());
    Get.lazyPut<PrinterController>(() => PrinterController());
  }
}
