import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/notification_controller.dart';

class NotificationsDialog extends StatelessWidget {
  NotificationsDialog({super.key});

  static const Color primaryGreen = Color(0xFF16A34A);

  // Usamos el controlador existente; si no existe, lo registramos.
  final NotificationController controller =
      Get.isRegistered<NotificationController>()
          ? Get.find<NotificationController>()
          : Get.put(NotificationController(), permanent: true);

  IconData _getIconForType(String type) {
    switch (type) {
      case 'monedas':
        return Icons.monetization_on_outlined;
      case 'incentivo':
        return Icons.star_outline;
      case 'actualizacion':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'monedas':
        return primaryGreen;
      case 'incentivo':
        return Colors.blueAccent;
      case 'actualizacion':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54, size: 28),
                onPressed: () {
                  final ctrl = Get.find<NotificationController>();
                  ctrl.closeModal(); // persiste "visto ahora" y quita resaltos
                  Get.back();
                },
              ),
            ),
            const Text(
              "Notificaciones",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),

            // Contenido
            Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                );
              }

              if (controller.notifications.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    "No tienes notificaciones.",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Paginación
              final total = controller.notifications.length;
              final toShow = controller.notificationsToShow.value;
              final showCount = toShow < total ? toShow : total;
              final hasMore = toShow < total;

              return Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: hasMore ? showCount + 1 : showCount,
                  itemBuilder: (context, index) {
                    // Último item: botón "Ver más"
                    if (hasMore && index == showCount) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: TextButton(
                            onPressed: controller.loadMore,
                            child: const Text(
                              "Ver más",
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final notification = controller.notifications[index];
                    final icon = _getIconForType(notification.type);
                    final color = _getColorForType(notification.type);
                    final date = controller.formatDate(notification.date);

                    return Column(
                      children: [
                        _buildNotificationCard(
                          context,
                          icon: icon,
                          color: color,
                          title: notification.title,
                          date: date,
                          description: notification.description,
                          isNew: notification.isNew,
                        ),
                        // separador suave entre tarjetas
                        const Divider(
                          color: Colors.black12,
                          height: 20,
                          thickness: 1,
                        ),
                      ],
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String date,
    required String description,
    required bool isNew,
  }) {
    // Estilos diferenciados: recientes (isNew) con fondo ligeramente más oscuro + punto indicador
    final bgColor = isNew ? Colors.black.withOpacity(0.05) : Colors.white;
    final titleStyle = TextStyle(
      fontSize: 17,
      fontWeight: isNew ? FontWeight.w700 : FontWeight.w600,
      color: isNew ? Colors.black : Colors.black.withOpacity(0.85),
    );
    final descStyle = TextStyle(
      fontSize: 14.5,
      color: isNew
          ? Colors.black.withOpacity(0.85)
          : Colors.black.withOpacity(0.75),
      height: 1.4,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNew
              ? Colors.black.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono + punto indicador si es nuevo
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 28),
              if (isNew)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(description, style: descStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
