import 'package:get/get.dart';
import '../services/api_service.dart';

class ListUserController extends GetxController {
  var users = [].obs;
  var isLoading = false.obs;

  final ApiService _apiService = ApiService(); 

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  void loadUsers() async {
    try {
      isLoading(true);
      final fetchedUsers = await _apiService.getWMSUsers();
      users.assignAll(fetchedUsers);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }
}
