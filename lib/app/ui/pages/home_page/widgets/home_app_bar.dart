import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/home_controller.dart';
import 'package:recicla_tarapoto_1/app/controllers/user_controller.dart';
import 'package:recicla_tarapoto_1/app/ui/pages/home_page/widgets/balance_dialog.dart';
import 'package:recicla_tarapoto_1/app/ui/pages/home_page/widgets/notifications_dialog.dart';
import 'dart:developer' as developer;

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  bool _isOpeningBalanceDialog = false;
  bool isCollector = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Método para cargar datos de usuario y (si aplica) disparar el fetch de monedas
  Future<void> _loadUserData() async {
    try {
      final userController = Get.find<UserController>();
      isCollector = userController.userModel.value?.iscollector ?? true;

      // Si no es recolector, precarga el saldo (solo una vez al abrir)
      if (!isCollector) {
        final homeController = Get.find<HomeController>();
        // await homeController.fetchTotalCoins();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homeController.fetchTotalCoins();
        });
      }

      if (mounted) setState(() {});
    } catch (e) {
      developer.log('Error al cargar datos de usuario: $e', name: 'HomeAppBar');
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Logo
          Image.asset(
            'lib/assets/logo_completo.png',
            height: 39,
          ),
        ],
      ),
      actions: [
        // Ícono de notificaciones
        Transform.translate(
          offset: const Offset(-12, 0),
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                color: Colors.white,
                iconSize: 33,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NotificationsDialog(),
                  );
                },
              ),
              Positioned(
                right: 0,
                top: 1,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 89, 217, 153),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 21,
                    minHeight: 21,
                  ),
                  child: const Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Ícono de balance (oculto para recolector)
        Builder(
          builder: (context) {
            if (isCollector) {
              return const SizedBox.shrink();
            }

            return GestureDetector(
              onTap: () async {
                if (_isOpeningBalanceDialog) return; // evita taps repetidos
                _isOpeningBalanceDialog = true;
                try {
                  // Abre y espera a que se cierre (sin addPostFrameCallback)
                  await showDialog(
                    context: context,
                    builder: (_) => const BalanceDialog(),
                    barrierDismissible: true, // permite cerrar tocando fuera
                    useSafeArea: true,
                  );
                } catch (e) {
                  developer.log('Error al mostrar diálogo: $e',
                      name: 'BalanceIcon');
                } finally {
                  _isOpeningBalanceDialog = false;
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 4),

                    // 🔹 Reactivo: muestra spinner mientras carga, y luego las monedas en vivo
                    Obx(() {
                      if (home.isLoadingCoins.value) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      final coins = home.totalCoins.value;
                      return Text(
                        coins.toStringAsFixed(0),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF59D999), Color(0xFF31ADA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}
