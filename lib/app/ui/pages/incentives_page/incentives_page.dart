import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/incentives_controller.dart';

class IncentivesScreen extends GetView<IncentivesController> {
  const IncentivesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ==== Layout del grid (sin overflow) ====
    const outerPadding = 8.0;
    const crossAxisSpacing = 12.0;
    const mainAxisSpacing = 12.0;
    const crossAxisCount = 2;

    final gridItemWidth = (size.width -
            (outerPadding * 2) -
            (crossAxisSpacing * (crossAxisCount - 1))) /
        crossAxisCount;

    // Alto objetivo por card (ajusta según pantallas angostas)
    final desiredHeight = size.width < 380 ? 390.0 : 370.0;
    final cardAspectRatio = gridItemWidth / desiredHeight;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(outerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            const Text(
              "Incentivos Disponibles",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                final incentives = controller.incentivesList;
                if (incentives.isEmpty) {
                  return const Center(
                    child: Text('No hay incentivos disponibles.',
                        style: TextStyle(fontSize: 16)),
                  );
                }

                return GridView.builder(
                  itemCount: incentives.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                  ).copyWith(childAspectRatio: cardAspectRatio),
                  itemBuilder: (context, i) {
                    final inc = incentives[i];
                    return IncentiveCard(
                      name: inc.name,
                      price: inc.price,
                      description: inc.description,
                      imageUrl: inc.image,
                      stock: inc.stock,
                      onRedeem: () => _openRedeemDialog(context, inc),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openRedeemDialog(BuildContext context, dynamic inc) {
    final bool sinStock = inc.stock <= 0;
    if (sinStock) {
      Get.snackbar('Sin stock', 'Este incentivo ya no está disponible.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible:
          false, // 👈 evita que se cierre mientras está procesando
      builder: (ctx) {
        // Capturamos el navigator ANTES de cualquier await para no depender del ctx luego
        final navigator = Navigator.of(ctx, rootNavigator: true);

        return Obx(() {
          final busy = controller.isRedeeming.value;
          final bool sinStockDialog = inc.stock <= 0;

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.monetization_on,
                            color: Color(0xFF31ADA0), size: 30),
                        SizedBox(width: 8),
                        Text("150 Monedas",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        inc.image,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 140,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image,
                              size: 60, color: Colors.grey),
                        ),
                        loadingBuilder: (context, child, loading) {
                          if (loading == null) return child;
                          return const SizedBox(
                            height: 140,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(inc.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Costo: ${inc.price} monedas",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sinStockDialog
                            ? Colors.redAccent
                            : const Color(0x1431ADA0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sinStockDialog
                            ? 'Sin stock'
                            : 'Stock disponible: ${inc.stock}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sinStockDialog
                              ? Colors.white
                              : const Color(0xFF31ADA0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(inc.description,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54)),
                    const Divider(height: 30),
                    const Text("Proceso para recibir tu premio:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      "- Una vez confirmado el canje, se descontarán las monedas de tu cuenta.\n"
                      "- Tu unidad será reservada según nuestro stock de insentivos.\n"
                      "- El incentivo será entregado en la próxima visita del recolector.\n"
                      "- Se tomará evidencia de la entrega mediante una fotografía.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: busy ? null : () => navigator.pop(),
                          child: const Text("Cerrar"),
                        ),
                        ElevatedButton(
                          onPressed: (busy || inc.stock <= 0)
                              ? null
                              : () async {
                                  if (controller.isRedeeming.value) return;
                                  final ok =
                                      await controller.confirmRedeem(inc);
                                  // Cerrar SOLO si fue exitoso
                                  if (ok) {
                                    // no usamos ctx aquí: ya tenemos navigator
                                    navigator.pop();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF31ADA0),
                            foregroundColor: Colors.white,
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Confirmar Canje"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class IncentiveCard extends StatelessWidget {
  const IncentiveCard({
    super.key,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.stock,
    required this.onRedeem,
  });

  final String name;
  final int price;
  final String description;
  final String imageUrl;
  final int stock;
  final VoidCallback onRedeem;

  // Paleta (Recicla Tarapoto)
  static const Color kPrimary = Color(0xFF31ADA0); // celeste/verde
  static const Color kPrimary2 = Color(0xFF59D999);
  static const Color kPrimaryDark = Color(0xFF136F66);

  @override
  Widget build(BuildContext context) {
    final agotado = stock <= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ===== Zona superior: Imagen =====
          AspectRatio(
            aspectRatio: 1 / 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 150),
                    useOldImageOnUrlChange: true,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image,
                          size: 60, color: Colors.grey),
                    ),
                  ),
                  if (stock <= 0)
                    Container(
                      color: Colors.black.withOpacity(0.35),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ===== Panel blanco con info =====
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Chip de stock
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: agotado
                            ? Colors.redAccent
                            : const Color(0x1431ADA0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: agotado
                              ? Colors.redAccent
                              : const Color(0x2231ADA0),
                        ),
                      ),
                      child: Text(
                        agotado ? 'Sin stock' : 'Stock: $stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: agotado ? Colors.white : kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Descripción
                    Expanded(
                      child: Text(
                        description,
                        maxLines: 4,
                        textAlign: TextAlign.justify,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // ===== Footer: Precio + Botón =====
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRECIO',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "\$${price.toString()}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: agotado ? null : onRedeem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    agotado ? Colors.black12 : kPrimary,
                                foregroundColor:
                                    agotado ? Colors.black45 : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Canjear',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    )),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper para ajustar childAspectRatio
extension _SliverGridDelegateCopy on SliverGridDelegateWithFixedCrossAxisCount {
  SliverGridDelegateWithFixedCrossAxisCount copyWith({
    int? crossAxisCount,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    double? childAspectRatio,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount ?? this.crossAxisCount,
      mainAxisSpacing: mainAxisSpacing ?? this.mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing ?? this.crossAxisSpacing,
      childAspectRatio: childAspectRatio ?? this.childAspectRatio,
    );
  }
}
