import 'package:get/get.dart'; 
import 'package:wms/controllers/list_user_controller.dart';
 import 'package:wms/controllers/user_manage_controller.dart';
class ListUserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListUserController>(() => ListUserController()); 
     Get.lazyPut<UserManageController>(() => UserManageController());
  }
}
