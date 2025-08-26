import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// Asegúrate de importar tu HomeScreenController
import 'package:recicla_tarapoto_1/app/controllers/homescreen_controller.dart';
// Importa también tu UserController para acceder al userModel
import 'package:recicla_tarapoto_1/app/controllers/user_controller.dart';
import 'package:recicla_tarapoto_1/app/data/models/residue_item.dart';
// Modelos
import 'package:recicla_tarapoto_1/app/data/models/waste_collection.dart';

// ✅ NUEVO: carga eficiente de imágenes
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends GetView<HomeScreenController> {
  const HomeScreen({Key? key}) : super(key: key);

  //------------------------------------------------------------------
  // 1. Diálogo de confirmación final (resumen) — FIXED
  //------------------------------------------------------------------
  void _showConfirmationDialog(
    BuildContext context, {
    required List<Map<String, dynamic>> resumenResiduos,
    required double totalKg,
    required double totalMonedasBase,
    required int totalBolsas,
    required int segregadosCorrectamente,
  }) {
    if (totalKg <= 0) {
      Get.snackbar("Datos inválidos", "Debes ingresar al menos 1 Kg.",
          snackPosition: SnackPosition.TOP);
      return;
    }

    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) {
        final int bonusCoinsFromSegregados = segregadosCorrectamente * 30;
        final double finalTotalMonedasARecibir =
            totalMonedasBase + bonusCoinsFromSegregados.toDouble();

        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Resumen de Solicitud",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (resumenResiduos.isEmpty)
                      const Text("No seleccionaste ningún residuo.")
                    else
                      ...resumenResiduos.map((res) {
                        final tipo = res["tipo"];
                        final kg = res["kg"];
                        final bolsa = res["bolsa"] == true ? "Sí" : "No";
                        final items = (res["items"] as List).join(", ");
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF59D999),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("• $tipo",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1FDB9D),
                                  )),
                              const SizedBox(height: 4),
                              Text("Items: $items"),
                              Text("Cantidad: $kg Kg"),
                              Text("Bolsa individual: $bolsa"),
                            ],
                          ),
                        );
                      }),
                    const Divider(thickness: 1.2),
                    Text("Total de Residuos: $totalKg"),
                    Text(" - Monedas (base): $totalMonedasBase"),
                    Text("Segregados Correctamente: $segregadosCorrectamente"),
                    Text(" - Bono por bolsas: $bonusCoinsFromSegregados"),
                    Text(
                        "Total de Monedas a Recibir: $finalTotalMonedasARecibir"),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              saving ? null : () => Navigator.of(ctx).pop(),
                          child: const Text("Cancelar"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (Get.isDialogOpen == true) {
                                    setState(() => saving = true);
                                  }

                                  try {
                                    final userController =
                                        Get.find<UserController>();
                                    final userData =
                                        userController.userModel.value;
                                    if (userData == null) {
                                      throw "No se encontró información de usuario.";
                                    }

                                    final Map<String, int> ratesByType = {
                                      'Papel y Cartón': 50,
                                      'Plástico': 100,
                                      'Metales': 50,
                                    };

                                    final residueItems =
                                        resumenResiduos.map((res) {
                                      final int kgInt =
                                          (res["kg"] as double).toInt();
                                      final String tipo = res["tipo"] as String;
                                      final bool bolsa = res["bolsa"] as bool;
                                      final int rate = ratesByType[tipo] ?? 0;

                                      final int coinsBase = kgInt * rate;
                                      final int coinsFinal =
                                          coinsBase + (bolsa ? 30 : 0);

                                      return ResidueItem(
                                        approxKg: kgInt.toDouble(),
                                        coinsPerType: coinsFinal.toString(),
                                        individualBag: bolsa,
                                        selectedItems: (res["items"] as List)
                                            .cast<String>(),
                                        type: tipo,
                                      );
                                    }).toList();

                                    final totalCoinsFinal = totalMonedasBase +
                                        (segregadosCorrectamente * 30);

                                    final wasteCollection =
                                        WasteCollectionModel(
                                      id: '',
                                      address: userData.address,
                                      isRecycled: false,
                                      totalBags: totalBolsas.toDouble(),
                                      totalCoins: totalCoinsFinal,
                                      totalKg: totalKg,
                                      correctlySegregated:
                                          segregadosCorrectamente,
                                      residues: residueItems,
                                      userReference: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userData.uid),
                                      date: DateTime.now(),
                                    );

                                    await Get.find<HomeScreenController>()
                                        .createWasteCollection(wasteCollection)
                                        .timeout(const Duration(seconds: 15));

                                    await Navigator.of(ctx).maybePop();

                                    Get.snackbar(
                                      "Solicitud Enviada",
                                      "Tu solicitud ha sido confirmada y guardada.",
                                      backgroundColor: const Color(0xFF59D999),
                                      colorText: Colors.white,
                                    );
                                  } catch (e) {
                                    Get.snackbar(
                                      "Error",
                                      e.toString(),
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  } finally {
                                    if (Get.isDialogOpen == true) {
                                      setState(() => saving = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF59D999),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Confirmar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. Diálogo de marcar bolsa individual (actualizado a +30)
  //------------------------------------------------------------------
  void _showBolsaDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF31ADA0),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "¿El residuo está en bolsa individual?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Cada tipo de residuo debe ir en su bolsa individual. Si está correctamente segregado se te asignarán 30 monedas extras.",
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                "Será verificado por el recolector asignado.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //------------------------------------------------------------------
  // 3. Helpers de Totales e Items
  //------------------------------------------------------------------
  Widget _buildRowTotal(String label, String value) {
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

  Widget _buildTotales(
    RxDouble totalKg,
    RxDouble totalMonedasBase,
    RxInt totalBolsas,
    RxInt segregadosCorrectamente,
  ) {
    return Obx(
      () {
        final int bonus = segregadosCorrectamente.value * 30; // +30 por tipo
        final double totalFinal = totalMonedasBase.value + bonus;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRowTotal(
              "Total de Residuos:",
              "${totalKg.value.toStringAsFixed(2)} Kg",
            ),
            _buildRowTotal(
              " - Monedas (base):",
              totalMonedasBase.value.toStringAsFixed(0),
            ),
            _buildRowTotal(
              "Segregados Correctamente",
              "${segregadosCorrectamente.value}",
            ),
            _buildRowTotal(
              " - Bono por bolsas:",
              "$bonus",
            ),
            _buildRowTotal(
              "Total de Monedas a recibir:",
              totalFinal.toStringAsFixed(0),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResiduoItem(
    Map<String, dynamic> residuo,
    int index,
    List<TextEditingController> kgControllers,
    RxList<bool> isKgFieldEnabled,
    List<RxDouble> unitValuesBase,
    RxList<bool> selectedIcons,
    List<RxList<bool>> selectedButtons,
    List<RxBool> isKgFieldNotEmpty,
    VoidCallback calculateTotals,
    VoidCallback showBolsaDialog,
    double screenWidth,
  ) {
    final String tipo = residuo["tipo"] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado: tipo de residuo + ícono bolsa
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tipo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            // Icono de bolsa usando el controlador para la activación
            Obx(() {
              controller.updateUI.value;

              final bool hasText = kgControllers[index].text.isNotEmpty;
              final bool anyButtonSelected =
                  selectedButtons[index].contains(true);
              final bool isEnabled = hasText && anyButtonSelected;

              if (!anyButtonSelected && selectedIcons[index]) {
                selectedIcons[index] = false;
                calculateTotals();
              }

              return Semantics(
                button: true,
                label: selectedIcons[index]
                    ? "Desmarcar bolsa individual para $tipo"
                    : "Marcar bolsa individual para $tipo",
                child: IconButton(
                  icon: Icon(
                    Icons.shopping_bag,
                    color: isEnabled
                        ? (selectedIcons[index]
                            ? const Color(0xFF59D999)
                            : Colors.grey)
                        : Colors.grey.withOpacity(0.5),
                  ),
                  onPressed: isEnabled
                      ? () {
                          selectedIcons[index] = !selectedIcons[index];
                          if (selectedIcons[index]) {
                            _showBolsaDialog();
                          }
                          calculateTotals();
                        }
                      : null,
                ),
              );
            }),
          ],
        ),
        // Botones de ítems
        Wrap(
          spacing: 8.0,
          children:
              (residuo["items"] as List<String>).asMap().entries.map((entry) {
            final itemIndex = entry.key;
            final item = entry.value;
            return Obx(
              () => ElevatedButton(
                onPressed: () {
                  selectedButtons[index][itemIndex] =
                      !selectedButtons[index][itemIndex];

                  final anySelected = selectedButtons[index].contains(true);

                  if (!anySelected) {
                    isKgFieldEnabled[index] = false;
                    kgControllers[index].clear();
                    selectedIcons[index] = false;
                    unitValuesBase[index].value = 0.0;
                    controller.refreshUI();
                  } else {
                    isKgFieldEnabled[index] = true;
                  }

                  calculateTotals();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedButtons[index][itemIndex]
                      ? const Color(0xFF59D999)
                      : const Color.fromARGB(255, 255, 255, 255),
                  foregroundColor: selectedButtons[index][itemIndex]
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(item),
              ),
            );
          }).toList(),
        ),
        // Campo para ingresar Kg + Muestra de monedas
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 110,
              child: Obx(
                () => TextField(
                  controller: kgControllers[index],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // solo enteros
                  ],
                  enabled: isKgFieldEnabled[index],
                  onChanged: (value) {
                    controller.refreshUI();
                    calculateTotals();
                  },
                  decoration: InputDecoration(
                    labelText: "Kg (entero)",
                    helperText: "Mín. 1",
                    helperStyle: TextStyle(
                      color: isKgFieldEnabled[index]
                          ? Colors.black54
                          : Colors.grey,
                      fontSize: 11,
                    ),
                    labelStyle: TextStyle(
                      color:
                          isKgFieldEnabled[index] ? Colors.black : Colors.grey,
                    ),
                    border: const OutlineInputBorder(),
                    disabledBorder: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Monedas a Recibir",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Obx(
                  () {
                    final int bonus = selectedIcons[index] ? 30 : 0;
                    final double display =
                        unitValuesBase[index].value + bonus.toDouble();
                    return Text(
                      display.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 18),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  //------------------------------------------------------------------
  // 4. Diálogo principal de "Solicitar Recolección"
  //------------------------------------------------------------------
  void _showFloatingDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final residuos = [
      {
        "tipo": "Papel y Cartón",
        "items": ["Papel", "Cartón"]
      },
      {
        "tipo": "Plástico",
        "items": ["Botellas", "Plást. Grueso"]
      },
      {
        "tipo": "Metales",
        "items": ["Latas", "Chatarra"]
      },
    ];

    final Map<String, int> ratesByType = {
      'Papel y Cartón': 50,
      'Plástico': 100,
      'Metales': 50,
    };

    final kgControllers = <TextEditingController>[];
    final unitValuesBase = <RxDouble>[]; // solo base (kg * rate), sin bono
    final totalKg = 0.0.obs;
    final totalMonedasBase = 0.0.obs;
    final totalBolsas = 0.obs;
    final segregadosCorrectamente = 0.obs;
    final selectedIcons = List.filled(residuos.length, false).obs;
    final selectedButtons = List.generate(
      residuos.length,
      (index) =>
          List.filled((residuos[index]["items"] as List).length, false).obs,
    );
    final isKgFieldEnabled = List.filled(residuos.length, false).obs;
    final isKgFieldNotEmpty = List.generate(residuos.length, (_) => false.obs);

    for (var _ in residuos) {
      kgControllers.add(TextEditingController());
      unitValuesBase.add(0.0.obs);
    }

    void _calculateTotals() {
      totalKg.value = 0.0;
      totalMonedasBase.value = 0.0;
      totalBolsas.value = 0;
      segregadosCorrectamente.value = 0;

      for (var i = 0; i < residuos.length; i++) {
        if (isKgFieldEnabled[i]) {
          final int kgInt = int.tryParse(kgControllers[i].text) ?? 0;
          final int kgValid = kgInt >= 1 ? kgInt : 0;

          final String tipo = residuos[i]["tipo"] as String;
          final int rate = ratesByType[tipo] ?? 0;

          final int baseCoins = kgValid * rate;
          unitValuesBase[i].value = baseCoins.toDouble();

          totalKg.value += kgValid.toDouble();
          totalMonedasBase.value += unitValuesBase[i].value;

          if (selectedIcons[i] && kgValid > 0) {
            segregadosCorrectamente.value += 1;
          }
        }
      }

      totalBolsas.value = 0;
      for (var i = 0; i < residuos.length; i++) {
        if (isKgFieldEnabled[i]) {
          final int kgInt = int.tryParse(kgControllers[i].text) ?? 0;
          if (kgInt >= 1) totalBolsas.value += 1;
        }
      }
    }

    for (var controllerTF in kgControllers) {
      controllerTF.addListener(_calculateTotals);
    }

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
                    "Solicitud de Recolección",
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
                        const Text(
                          "Instrucciones:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          "1. Selecciona el tipo de residuo.",
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 6),

                        const Text(
                          "2. Ingresa la cantidad estimada en kilogramos (solo números enteros).",
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 6),

                        const Text(
                          "3. Marca el ícono de la bolsa si lo estás segregando de forma correcta. Así recibirás 30 monedas extras por ese tipo.",
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 15, height: 1.4),
                        ),

                        const SizedBox(height: 15),

                        // Construye cada "tipo de residuo"
                        ...residuos.asMap().entries.map((entry) {
                          int i = entry.key;
                          var res = entry.value;
                          return _buildResiduoItem(
                            res,
                            i,
                            kgControllers,
                            isKgFieldEnabled,
                            unitValuesBase,
                            selectedIcons,
                            selectedButtons,
                            isKgFieldNotEmpty,
                            _calculateTotals,
                            _showBolsaDialog,
                            screenWidth,
                          );
                        }).toList(),

                        const Divider(thickness: 1.2),
                        _buildTotales(
                          totalKg,
                          totalMonedasBase,
                          totalBolsas,
                          segregadosCorrectamente,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                // Botón final
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Obx(() {
                    final canSubmit = totalKg.value > 0;
                    return Semantics(
                      button: true,
                      label: canSubmit
                          ? "Enviar solicitud de recolección"
                          : "Botón deshabilitado. Agrega al menos 1 Kg válido.",
                      child: ElevatedButton(
                        onPressed: canSubmit
                            ? () {
                                Navigator.of(ctx).pop();

                                final List<Map<String, dynamic>> resumen = [];
                                for (var i = 0; i < residuos.length; i++) {
                                  if (isKgFieldEnabled[i]) {
                                    final tipo = residuos[i]["tipo"];
                                    final int kgInt =
                                        int.tryParse(kgControllers[i].text) ??
                                            0;
                                    if (kgInt < 1) continue;
                                    final kg = kgInt.toDouble();
                                    final bolsa = selectedIcons[i];

                                    final selectedItems = <String>[];
                                    for (var j = 0;
                                        j < selectedButtons[i].length;
                                        j++) {
                                      if (selectedButtons[i][j]) {
                                        selectedItems.add((residuos[i]["items"]
                                            as List<String>)[j]);
                                      }
                                    }
                                    resumen.add({
                                      "tipo": tipo,
                                      "kg": kg,
                                      "bolsa": bolsa,
                                      "items": selectedItems,
                                    });
                                  }
                                }

                                _showConfirmationDialog(
                                  context,
                                  resumenResiduos: resumen,
                                  totalKg: totalKg.value,
                                  totalMonedasBase: totalMonedasBase.value,
                                  totalBolsas: totalBolsas.value,
                                  segregadosCorrectamente:
                                      segregadosCorrectamente.value,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF59D999),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 14),
                        ),
                        child: const Text(
                          "Enviar Solicitud",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //------------------------------------------------------------------
  // 5. Método build principal
  //------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final imageHeight = screenHeight * 0.3; // Imagen ~30% alto de pantalla
    final carouselHeight = screenHeight * 0.25; // Carrusel ~25% alto

    return SingleChildScrollView(
      child: Column(
        children: [
          // Imagen superior
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Image.asset(
              'lib/assets/home_rt.png',
              height: imageHeight,
              width: screenWidth * 0.75,
              fit: BoxFit.cover,
            ),
          ),

          // Botón "Solicitar Recolección"
          ElevatedButton(
            onPressed: () => _showFloatingDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 89, 217, 153),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.1,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Solicitar Recolección',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                color: Colors.white,
              ),
            ),
          ),

          // Texto "Participaciones de la Semana"
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Participaciones de la Semana',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Carrusel (se mantiene tu ListView, solo cambia la carga de imagen)
          SizedBox(
            height: carouselHeight,
            width: screenWidth,
            child: Obx(() {
              final images = [
                ...controller.carouselImages
              ]; // copia para no alterar original
              images.shuffle(); // 👈 aleatorio

              if (images.isEmpty) {
                return const Center(
                    child: Text('No hay imágenes para el carrusel'));
              }
              return ListView.builder(
                controller: controller.scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: images.length * 10, // carrusel "infinito"
                itemBuilder: (context, index) {
                  final imageModel = images[index % images.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Stack(
                      children: [
                        // Imagen con marco dorado si es premiación
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: imageModel.tipo == 'premio'
                                  ? const Color.fromARGB(255, 251, 255, 0)
                                  : const Color.fromARGB(0, 81, 255, 0),
                              width: 6,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                // 🔁 Reemplazo: CachedNetworkImage
                                CachedNetworkImage(
                                  imageUrl: imageModel.url,
                                  fit: BoxFit.cover,
                                  width: screenWidth * 0.3,
                                  height: double.infinity,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image,
                                          size: 50, color: Colors.grey),
                                ),

                                // Texto en la parte inferior
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 89, 217, 153),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 89, 217, 153),
                                        width:
                                            imageModel.tipo == 'premio' ? 3 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      imageModel.tipo == 'premio'
                                          ? 'INCENTIVO'
                                          : 'PARTICIPACIÓN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: imageModel.tipo == 'premio'
                                            ? FontWeight.w700
                                            : FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Emoji distintivo arriba a la izquierda
                        Positioned(
                          top: -6,
                          left: 86,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: imageModel.tipo == 'premio'
                                  ? const Color.fromARGB(255, 251, 255, 0)
                                  : const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: imageModel.tipo == 'premio'
                                    ? const Color.fromARGB(255, 251, 255, 0)
                                    : Colors.white,
                                width: imageModel.tipo == 'premio' ? 3 : 1,
                              ),
                            ),
                            child: Text(
                              imageModel.tipo == 'premio' ? '🏆' : '🤝',
                              style: const TextStyle(fontSize: 21),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
