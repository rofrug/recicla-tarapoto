import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/allredeemedincentives_controller.dart';
import '../../../data/models/redeemed_incentive_model.dart';

class AllRedeemedIncentivesPage
    extends GetView<AllRedeemedIncentivesController> {
  AllRedeemedIncentivesPage({Key? key}) : super(key: key);
  final RxBool _confirming = false.obs;
  // Colores primarios de la app
  static const Color colorPrimaryLight = Color(0xFF59D999);
  static const Color colorPrimaryDark = Color(0xFF31ADA0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<RedeemedIncentiveModel>>(
        stream: controller.allRedeemedIncentivesStream,
        builder: (context, snapshot) {
          // Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error
          if (snapshot.hasError) {
            return Center(child: Text('Ocurrió un error: ${snapshot.error}'));
          }
          // Sin datos
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay canjes registrados.'));
          }

          final redeemedIncentives = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: redeemedIncentives.length,
            itemBuilder: (context, index) {
              final incentive = redeemedIncentives[index];
              return _buildIncentiveCard(incentive);
            },
          );
        },
      ),
    );
  }

  /// Construye la tarjeta para cada canje
  Widget _buildIncentiveCard(RedeemedIncentiveModel incentive) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila con la imagen/avatar y la info del usuario
            Row(
              children: [
                _buildImageAvatar(incentive.image),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre de usuario
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 18, color: colorPrimaryDark),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                print(
                                    '[DEBUG UI] userName: \'${incentive.userName}\'');
                                return Text(
                                  incentive.userName.isNotEmpty
                                      ? incentive.userName
                                      : 'No userName',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Dirección
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 18, color: colorPrimaryDark),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                print(
                                    '[DEBUG UI] userAddress: \'${incentive.userAddress}\'');
                                return Text(
                                  incentive.userAddress.isNotEmpty
                                      ? incentive.userAddress
                                      : 'No address',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info del incentivo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.card_giftcard,
                    size: 20, color: colorPrimaryDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre incentivo
                      Text(
                        incentive.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Descripción
                      if (incentive.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            incentive.description,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Fila con estado + botón/indicador
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusWidget(incentive),
                if (incentive.status == 'pendiente')
                  ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog(incentive),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Completar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  // Si ya está completado, mostramos un texto/ícono
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: colorPrimaryLight),
                      SizedBox(width: 4),
                      Text(
                        'Completado',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Diálogo de confirmación antes de completar el canje
  void _showConfirmDialog(RedeemedIncentiveModel incentive) {
    Get.defaultDialog(
      title: 'Confirmar entrega',
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colorPrimaryDark,
      ),
      middleText:
          'Vas a confirmar la entrega del incentivo\n“${incentive.name}” a ${incentive.userName}.\n\n'
          'Esta acción marcará el canje como *Completado* y no se puede deshacer.',
      textConfirm: 'Sí, confirmar',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      buttonColor: colorPrimaryDark,

      // ✅ evita cerrar por toque fuera
      barrierDismissible: false,

      onConfirm: () async {
        // ✅ anti doble-tap
        if (_confirming.value) return;
        _confirming.value = true;

        try {
          // ✅ cierra TODOS los overlays antes de procesar
          if (Get.isDialogOpen ?? false) {
            Get.back(closeOverlays: true);
          }

          // 🔧 procesa
          await controller.markAsCompleted(incentive);

          // ✅ feedback
          Get.snackbar(
            'Entrega confirmada',
            'El incentivo fue marcado como entregado.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black.withOpacity(0.75),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
          );
        } catch (e) {
          // Mensaje de error visible
          Get.snackbar(
            'Error',
            'No se pudo completar la entrega. Inténtalo de nuevo.',
            snackPosition: SnackPosition.BOTTOM,
          );
        } finally {
          _confirming.value = false;

          // 🧯 por si quedara algún overlay abierto (defensivo)
          if (Get.isDialogOpen ?? false) {
            Get.back(closeOverlays: true);
          }
        }
      },

      // ✅ no hace falta cerrar manual aquí; pero si lo dejas, que sea defensivo
      onCancel: () {
        if (Get.isDialogOpen ?? false) {
          Get.back(closeOverlays: true);
        }
      },
      radius: 10,
    );
  }

  /// Avatar/Circle con imagen o ícono por defecto
  Widget _buildImageAvatar(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[200],
        backgroundImage: NetworkImage(imageUrl),
      );
    } else {
      // Ícono por defecto
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[300],
        child:
            const Icon(Icons.card_giftcard, size: 24, color: colorPrimaryDark),
      );
    }
  }

  /// Chip/Widget para mostrar el estado del canje
  Widget _buildStatusWidget(RedeemedIncentiveModel incentive) {
    // Podríamos mostrar un simple Icon + texto
    final isPending = incentive.status == 'pendiente';
    final icon = isPending ? Icons.hourglass_empty : Icons.check_circle;
    final color = isPending ? Colors.amber : colorPrimaryLight;
    final text = isPending ? 'Pendiente' : 'Completado';

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
