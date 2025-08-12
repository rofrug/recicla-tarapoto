import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/homecollector_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/homescreen_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/incentives_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/information_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/user_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/userinventory_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/notification_controller.dart'; // 👈 NUEVO

import '../controllers/allredeemedincentives_controller.dart';
import '../controllers/home_controller.dart';
import '../ui/pages/notifications_page/notifications_page.dart';
import '../ui/pages/profilecollector_page/profilecollector_page.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    // Core / user first
    Get.lazyPut<UserController>(() => UserController(), fenix: true);

    // Notificaciones: una sola instancia viva para header + modal
    Get.lazyPut<NotificationController>(() => NotificationController(),
        fenix: true); // 👈 NUEVO

    // Resto de controladores/páginas
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<HomeScreenController>(() => HomeScreenController(),
        fenix: true);
    Get.lazyPut<InformationController>(() => InformationController(),
        fenix: true);
    Get.lazyPut<IncentivesController>(() => IncentivesController(),
        fenix: true);
    Get.lazyPut<HomecollectorController>(() => HomecollectorController(),
        fenix: true);
    Get.lazyPut<UserinventoryController>(() => UserinventoryController(),
        fenix: true);

    Get.lazyPut<NotificationsPage>(() => NotificationsPage(), fenix: true);
    Get.lazyPut<ProfilecollectorPage>(() => ProfilecollectorPage(),
        fenix: true);

    Get.lazyPut<AllRedeemedIncentivesController>(
      () => AllRedeemedIncentivesController(),
      fenix: true,
    );
  }
}
