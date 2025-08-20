import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/home_controller.dart';
import 'package:recicla_tarapoto_1/app/ui/pages/allredeemedincentives_page/allredeemedincentives_page.dart';

// Importaciones de las páginas
import '../home_screen/home_screen.dart';
// Páginas para el collector
import '../homecollector_page/homecollector_page.dart';
import '../incentives_page/incentives_page.dart';
import '../information_page/information_page.dart';
import '../notifications_page/notifications_page.dart';
import '../user_page/user_page.dart';
// NUEVO: perfil del recolector
import '../profilecollector_page/profilecollector_page.dart';

// Importaciones de widgets separados
import 'widgets/home_app_bar.dart';
import 'widgets/home_bottom_navigation_bar.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Verificamos si es collector
      final bool isCollector = controller.isCollector.value;

      // Listas de páginas para usuario normal y para collector
      final List<Widget> pagesUser = [
        HomeScreen(),
        InformationScreen(),
        IncentivesScreen(),
        UserScreen(), // Perfil (ciudadano)
      ];

      final List<Widget> pagesCollector = [
        HomecollectorPage(), // Inventario / principal recolector
        NotificationsPage(), // Notificaciones
        AllRedeemedIncentivesPage(), // Canjes/incentivos
        ProfilecollectorPage(), // 👈 Perfil (recolector) — CAMBIADO
      ];

      // Items del BottomNavigationBar
      final List<BottomNavigationBarItem> itemsUser = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.info), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ];

      final List<BottomNavigationBarItem> itemsCollector = const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_repair_service), label: ''), // Inventario
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active), label: ''), // Notificación
        BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard), label: ''), // Regalo
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''), // Perfil
      ];

      // Seleccionamos las páginas e items dependiendo de isCollector
      final pages = isCollector ? pagesCollector : pagesUser;
      final items = isCollector ? itemsCollector : itemsUser;

      return Scaffold(
        // AppBar separado en un widget
        appBar: HomeAppBar(),

        // Cuerpo: la página seleccionada
        body: Center(
          child: pages.elementAt(controller.selectedIndex.value),
        ),

        // BottomNavigationBar separado en un widget
        bottomNavigationBar: HomeBottomNavigationBar(
          items: items,
          currentIndex: controller.selectedIndex.value,
          onTap: controller.onItemTapped,
        ),
      );
    });
  }
}
