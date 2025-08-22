// lib/app/ui/pages/homecollector/homecollector_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../controllers/homecollector_controller.dart';
import '../../../data/models/waste_collection.dart';
import '../../../data/models/residue_item.dart';

class HomecollectorPage extends GetView<HomecollectorController> {
  // Cantidad a mostrar en el historial (6 en 6)
  final RxInt _historyShowCount = 6.obs;

  // Índice expandido del historial (-1 = ninguno)
  final RxInt _expandedIndex = (-1).obs;

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
                            return _buildHistoryItem(it, context, index);
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
  // ITEM DE HISTORIAL (expandible)
  // ==========================
  Widget _buildHistoryItem(
      WasteCollectionModel waste, BuildContext context, int index) {
    final requested = waste.requestedAt ?? waste.date;
    final processed = waste.recycledAt;

    String fmt(DateTime? d) =>
        d == null ? '—' : DateFormat('dd/MM/yyyy HH:mm').format(d);

    return Obx(() {
      final isExpanded = _expandedIndex.value == index;

      return GestureDetector(
        onTap: () {
          _expandedIndex.value =
              isExpanded ? -1 : index; // toggle expand/collapse
        },
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F5),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFF59D999), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado (compacto)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF31ADA0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          waste.address.isEmpty
                              ? 'Sin dirección'
                              : waste.address,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // ↑ Primero SOLICITADO
                        Text('Solicitado: ${fmt(requested)}',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 12)),
                        // ↓ Luego PROCESADO
                        Text('Procesado: ${fmt(processed)}',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(waste.totalKg).toStringAsFixed(1)} Kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF31ADA0),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                ],
              ),

              // Sección expandida (resumen)
              if (isExpanded) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE1EFEA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Totales
                      _buildTotalRow(
                          'Total Kg', '${waste.totalKg.toStringAsFixed(1)}'),
                      _buildTotalRow(
                          'Monedas', '${waste.totalCoins.toStringAsFixed(0)}'),
                      _buildTotalRow(
                          'Seg. Correctamente', '${waste.correctlySegregated}'),
                      _buildTotalRow(
                          'Bolsas', '${waste.totalBags.toStringAsFixed(0)}'),

                      const SizedBox(height: 8),
                      const Divider(height: 16),
                      const Text(
                        'Por tipo',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF31ADA0),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Resumen por tipo
                      ...waste.residues.map((r) {
                        final kg = r.approxKg.toStringAsFixed(0);
                        final coins =
                            (r.coinsPerType.isEmpty ? '0' : r.coinsPerType)
                                .toString();
                        final bag = r.individualBag ? ' · Bolsa ✓' : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '• ${r.type} · $kg kg · $coins monedas$bag',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // ==========================
  // DIALOG DE DETALLES (igual a tu versión adaptada)
  // ==========================
  Widget _buildDetailBlock(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1EFEA)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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

    // Fechas para mostrar
    DateTime? requested = waste.requestedAt ?? waste.date;
    DateTime? processed = waste.recycledAt;

    String fmt(DateTime? d) =>
        d == null ? '—' : DateFormat('dd/MM/yyyy HH:mm').format(d);

    // Helpers UI
    String _initials(String s) {
      final t = s.trim();
      if (t.isEmpty) return 'U';
      final parts = t.split(RegExp(r'\s+'));
      return parts.first.characters.first.toUpperCase();
    }

    // Tarifas por tipo (igual que en el Generador)
    final Map<String, int> ratesByType = {
      'Papel y Cartón': 50,
      'Plástico': 100,
      'Metales': 50,
    };
    const int bonusPerBag = 30;

    // Controladores por residuo
    final kgControllers = <TextEditingController>[];
    final coinsControllers = <TextEditingController>[];
    final segregationControllers = <bool>[];

    // Totales reactivos
    final totalKg = waste.totalKg.obs;
    final totalCoins = waste.totalCoins.obs;
    final correctlySegregated = waste.correctlySegregated.obs;

    // Preparar controladores
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            width: screenWidth * 0.92,
            height: screenHeight * 0.86,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                // ===== Header estilizado =====
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF31ADA0), Color(0xFF59D999)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Detalles de Recolección",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          waste.isRecycled ? 'Procesado' : 'Pendiente',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor:
                            waste.isRecycled ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                ),

                // ===== Contenido =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==== Tarjeta de usuario (arriba de la descripción) ====
                        if (waste.userReference != null)
                          FutureBuilder<DocumentSnapshot>(
                            future: waste.userReference!.get(),
                            builder: (context, snap) {
                              String display = 'Usuario';
                              if (snap.hasData && snap.data!.data() != null) {
                                final data =
                                    snap.data!.data() as Map<String, dynamic>;
                                final name = (data['name'] ?? '').toString();
                                final last =
                                    (data['lastname'] ?? '').toString();
                                final joined = [name, last]
                                    .where((s) => s.trim().isNotEmpty)
                                    .join(' ')
                                    .trim();
                                if (joined.isNotEmpty) display = joined;
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FBFA),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFDCF4EF)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF31ADA0),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _initials(display),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(display,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700)),
                                          Text(
                                            waste.address.isEmpty
                                                ? 'Sin dirección'
                                                : waste.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        // ==== Información general / Fechas ====
                        Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Información General",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF31ADA0)),
                                ),
                                const SizedBox(height: 10),

                                // Orden: solicitado arriba / procesado abajo
                                _buildDetailBlock(
                                    "Fecha de solicitud", fmt(requested)),
                                _buildDetailBlock(
                                    "Fecha de procesamiento", fmt(processed)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==== Detalle de residuos ====
                        const Text(
                          "Detalle de Residuos",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF31ADA0)),
                        ),
                        const SizedBox(height: 10),

                        if (waste.residues.isEmpty)
                          const Center(
                              child: Text("No hay residuos registrados."))
                        else
                          ...List.generate(waste.residues.length, (index) {
                            final residue = waste.residues[index];

                            final String itemsText =
                                residue.selectedItems.isEmpty
                                    ? "Ninguno"
                                    : residue.selectedItems.join(", ");

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                    color: Color(0xFF59D999), width: 1),
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF31ADA0),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailBlock("Ítems:", itemsText),

                                    // KG (enteros)
                                    Row(
                                      children: [
                                        Text(
                                          "Cantidad (Kg):",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700]),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: kgControllers[index],
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly
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
                                              color: Colors.grey[700]),
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
                                              color: Colors.grey[700]),
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

                        const SizedBox(height: 14),

                        // ==== Totales ====
                        Card(
                          color: const Color(0xFFF4F6F5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Totales",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF31ADA0)),
                                ),
                                const SizedBox(height: 8),

                                // Total Kg
                                Row(
                                  children: [
                                    Text("Total Kg:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700])),
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
                                    Text("Total Monedas:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700])),
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
                                    Text("Seg. Correctamente:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700])),
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

                // ===== Botones de acción =====
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
                                totalKg: totalKg.value,
                                correctlySegregated: segregatedCount,
                                residues: updatedResidues,
                                userReference: waste.userReference,
                                date: waste.date,
                                requestedAt: waste.requestedAt ?? waste.date,
                                recycledAt:
                                    waste.recycledAt, // el provider lo sellará
                              );

                              Navigator.of(ctx).pop();
                              await controller.markAsRecycled(updatedWaste);
                              Get.snackbar(
                                "Recolección procesada",
                                "La recolección ha sido marcada como procesada",
                                backgroundColor: Colors.green.withOpacity(0.7),
                                colorText: Colors.white,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF59D999),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Guardar y Marcar como Procesado",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (waste.isRecycled)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
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
