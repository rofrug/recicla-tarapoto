// lib/app/ui/pages/homecollector/homecollector_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../controllers/homecollector_controller.dart';
import '../../../data/models/waste_collection.dart';
import '../../../data/models/residue_item.dart';

class HomecollectorPage extends GetView<HomecollectorController> {
  // Cantidad a mostrar en el historial (6 en 6)
  final RxInt _historyShowCount = 6.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================
              // RECOLECCIONES PENDIENTES
              // ==========================
              Text(
                'Recolecciones Pendientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Lista de pendientes integrada al scroll padre
              StreamBuilder<List<WasteCollectionModel>>(
                stream: controller.wasteCollectionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No hay recolecciones pendientes.'),
                    );
                  }

                  final pending = snapshot.data!;
                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final waste = pending[index];
                      return _buildListItem(waste, context);
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // ==========================
              // HISTORIAL DE RECOLECCIONES
              // ==========================
              Text(
                'Historial de recolecciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              StreamBuilder<List<WasteCollectionModel>>(
                // Asegúrate de exponer este stream en tu HomecollectorController
                stream: controller.completedCollectionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sin recolecciones registradas.'),
                    );
                  }

                  // Orden opcional por fecha descendente si el stream no lo hace ya
                  data.sort((a, b) {
                    final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return bd.compareTo(ad);
                  });

                  return Obx(() {
                    final total = data.length;
                    final count = _historyShowCount.value < total
                        ? _historyShowCount.value
                        : total;

                    return Column(
                      children: [
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: count,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final it = data[index];
                            return _buildHistoryItem(it, context);
                          },
                        ),
                        if (count < total)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton(
                              onPressed: () {
                                _historyShowCount.value += 6;
                              },
                              child: const Text('Ver más'),
                            ),
                          ),
                      ],
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================
  // ITEM DE PENDIENTES (tapping abre diálogo)
  // ==========================
  Widget _buildListItem(WasteCollectionModel waste, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: () => _showFloatingDialog(context, waste),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 89, 217, 206),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            waste.address.isEmpty ? 'Sin dirección' : waste.address,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================
  // ITEM DE HISTORIAL (vista compacta)
  // ==========================
  Widget _buildHistoryItem(WasteCollectionModel waste, BuildContext context) {
    final dateStr = waste.date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(waste.date!)
        : 'Fecha no disponible';

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF59D999), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF31ADA0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waste.address.isEmpty ? 'Sin dirección' : waste.address,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(waste.totalKg).toStringAsFixed(1)} Kg',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF31ADA0),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================
  // DIALOG DE DETALLES (igual a tu versión)
  // ==========================
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight:
                    valueColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Abre el diálogo y llena automáticamente los campos (con tu lógica existente)
  void _showFloatingDialog(BuildContext context, WasteCollectionModel waste) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Tarifas por tipo (igual que en el Generador)
    final Map<String, int> ratesByType = {
      'Papel y Cartón': 50,
      'Plástico': 100,
      'Metales': 50,
    };
    const int bonusPerBag = 30;

    // Fecha formateada
    final dateFormatted = waste.date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(waste.date!)
        : 'Fecha no disponible';

    // Controladores para edición
    final kgControllers = <TextEditingController>[];
    final coinsControllers = <TextEditingController>[];
    final segregationControllers = <bool>[];

    // Variables reactivas para los totales
    final totalKg = waste.totalKg.obs;
    final totalCoins = waste.totalCoins.obs;
    final correctlySegregated = waste.correctlySegregated.obs;

    // Preparar controladores para cada residuo
    for (var residue in waste.residues) {
      final initialKg = residue.approxKg.toInt();
      kgControllers.add(TextEditingController(text: initialKg.toString()));
      final coinsText =
          (residue.coinsPerType.isEmpty ? "0" : residue.coinsPerType);
      coinsControllers.add(TextEditingController(text: coinsText));
      segregationControllers.add(residue.individualBag);
    }

    void _calculateTotals() {
      double newTotalKg = 0.0;
      int baseCoinsSum = 0;
      int segregatedCount = 0;

      for (int i = 0; i < waste.residues.length; i++) {
        final residue = waste.residues[i];
        final int kgInt = int.tryParse(kgControllers[i].text) ?? 0;
        final int kgValid = kgInt >= 1 ? kgInt : 0;

        final String type = residue.type;
        final int rate = ratesByType[type] ?? 0;
        final int baseCoins = kgValid * rate;

        final int bonus =
            (segregationControllers[i] && kgValid > 0) ? bonusPerBag : 0;

        final int perTypeTotal = baseCoins + bonus;

        coinsControllers[i].text = perTypeTotal.toString();

        newTotalKg += kgValid.toDouble();
        baseCoinsSum += baseCoins;
        if (segregationControllers[i] && kgValid > 0) segregatedCount++;
      }

      final int finalTotalCoins =
          baseCoinsSum + (segregatedCount * bonusPerBag);

      totalKg.value = newTotalKg;
      totalCoins.value = finalTotalCoins.toDouble();
      correctlySegregated.value = segregatedCount;
    }

    for (var controller in kgControllers) {
      controller.addListener(_calculateTotals);
    }
    _calculateTotals();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: screenWidth * 0.9,
            height: screenHeight * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                // Encabezado
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF31ADA0),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Detalles de Recolección",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Contenido principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información general
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Información General",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF31ADA0),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildDetailRow("Dirección:", waste.address),
                                _buildDetailRow("Fecha:", dateFormatted),
                                _buildDetailRow(
                                  "Estado:",
                                  waste.isRecycled ? "Reciclado" : "Pendiente",
                                  valueColor: waste.isRecycled
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Detalle de residuos
                        Text(
                          "Detalle de Residuos",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF31ADA0),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (waste.residues.isEmpty)
                          const Center(
                            child: Text("No hay residuos registrados."),
                          )
                        else
                          ...List.generate(waste.residues.length, (index) {
                            final residue = waste.residues[index];

                            String itemsText;
                            if (residue.selectedItems.isEmpty) {
                              itemsText = "Ninguno";
                            } else {
                              itemsText = residue.selectedItems.join(", ");
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: Color(0xFF59D999),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      residue.type.isEmpty
                                          ? "Tipo no especificado"
                                          : residue.type,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF31ADA0),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow("Ítems:", itemsText),

                                    // KG (enteros)
                                    Row(
                                      children: [
                                        Text(
                                          "Cantidad (Kg):",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: kgControllers[index],
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: const InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                              helperText: "Entero, mín. 1",
                                              helperStyle:
                                                  TextStyle(fontSize: 10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Monedas por tipo (calculadas)
                                    Row(
                                      children: [
                                        Text(
                                          "Monedas (tipo):",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: coinsControllers[index],
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                              fillColor: Colors.grey[100],
                                              filled: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Toggle segregación correcta
                                    Row(
                                      children: [
                                        Text(
                                          "Segregación correcta:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        StatefulBuilder(
                                          builder: (context, setState) {
                                            return Switch(
                                              value:
                                                  segregationControllers[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  segregationControllers[
                                                      index] = value;
                                                });
                                                _calculateTotals();
                                              },
                                              activeColor:
                                                  const Color(0xFF59D999),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 16),

                        // Totales
                        Card(
                          color: const Color(0xFFF4F6F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Totales",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF31ADA0),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Total Kg
                                Row(
                                  children: [
                                    Text(
                                      "Total Kg:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700]),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Obx(() => TextField(
                                            controller: TextEditingController(
                                                text: totalKg.value
                                                    .toStringAsFixed(0)),
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                              fillColor: Colors.grey[100],
                                              filled: true,
                                            ),
                                          )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Total Monedas
                                Row(
                                  children: [
                                    Text(
                                      "Total Monedas:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700]),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Obx(() => TextField(
                                            controller: TextEditingController(
                                                text: totalCoins.value
                                                    .toStringAsFixed(0)),
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                              fillColor: Colors.grey[100],
                                              filled: true,
                                            ),
                                          )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Correctamente segregados
                                Row(
                                  children: [
                                    Text(
                                      "Segregados correctamente:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700]),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Obx(() => TextField(
                                            controller: TextEditingController(
                                                text: correctlySegregated.value
                                                    .toString()),
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                              fillColor: Colors.grey[100],
                                              filled: true,
                                            ),
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botones de acción
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!waste.isRecycled)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Persistir con fórmula nueva
                              List<ResidueItem> updatedResidues = [];
                              int finalBaseSum = 0;
                              int segregatedCount = 0;

                              for (int i = 0; i < waste.residues.length; i++) {
                                final residue = waste.residues[i];
                                final int kgInt =
                                    int.tryParse(kgControllers[i].text) ?? 0;
                                final int kgValid = kgInt >= 1 ? kgInt : 0;

                                final int rate = {
                                      'Papel y Cartón': 50,
                                      'Plástico': 100,
                                      'Metales': 50
                                    }[residue.type] ??
                                    0;
                                final int baseCoins = kgValid * rate;
                                final bool bag = segregationControllers[i];
                                final int bonus = (bag && kgValid > 0) ? 30 : 0;
                                final int perTypeTotal = baseCoins + bonus;

                                if (bag && kgValid > 0) segregatedCount++;
                                finalBaseSum += baseCoins;

                                updatedResidues.add(ResidueItem(
                                  type: residue.type,
                                  approxKg: kgValid.toDouble(),
                                  coinsPerType: perTypeTotal.toString(),
                                  individualBag: bag,
                                  selectedItems: residue.selectedItems,
                                ));
                              }

                              final int finalTotalCoins =
                                  finalBaseSum + (segregatedCount * 30);

                              final updatedWaste = WasteCollectionModel(
                                id: waste.id,
                                address: waste.address,
                                isRecycled: true,
                                totalBags: waste.totalBags,
                                totalCoins: finalTotalCoins.toDouble(),
                                totalKg: waste.residues.fold<double>(
                                    0.0,
                                    (p, r) =>
                                        p +
                                        (double.tryParse(
                                                r.approxKg.toString()) ??
                                            0.0)),
                                correctlySegregated: segregatedCount,
                                residues: updatedResidues,
                                userReference: waste.userReference,
                                date: waste.date,
                              );

                              Navigator.of(ctx).pop();
                              await controller.markAsRecycled(updatedWaste);
                              Get.snackbar(
                                "Recolección completada",
                                "La recolección ha sido marcada como reciclada",
                                backgroundColor: Colors.green.withOpacity(0.7),
                                colorText: Colors.white,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF59D999),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Guardar y Marcar como Reciclado",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (waste.isRecycled)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("Cerrar"),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
