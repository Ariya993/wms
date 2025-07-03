import 'package:get/get.dart';
import '../models/pick_list_model.dart';
import '../services/sap_service.dart';

class PickListController extends GetxController {
  final SAPService _service = SAPService();
  var pickLists = <PickList>[].obs;
  var isLoading = false.obs;

  // Future<void> loadPickLists(String session) async {
  //   isLoading.value = true;
  //   try {
  //     final result = await _service.fetchPickLists(session);
  //     pickLists.value = result;
  //   } catch (e) {
  //     Get.snackbar('Error', e.toString());
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
}
