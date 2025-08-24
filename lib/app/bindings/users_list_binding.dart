import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/users_list_controller.dart';

class UsersListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UsersListController>(() => UsersListController());
  }
}
