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

class HomeScreen extends GetView<HomeScreenController> {
  const HomeScreen({Key? key}) : super(key: key);

  //------------------------------------------------------------------
  // 1. Diálogo de confirmación final (resumen):
  //------------------------------------------------------------------
  void _showConfirmationDialog(
    BuildContext context, {
    required List<Map<String, dynamic>> resumenResiduos,
    required double totalKg,
    required double totalMonedasBase,
    required int totalBolsas,
    required int segregadosCorrectamente,
  }) {
    // Barrera extra: si por algún motivo llega 0, no continuar.
    if (totalKg <= 0) {
      Get.snackbar(
        "Datos inválidos",
        "Debes ingresar al menos 1 Kg para enviar la solicitud.",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        // Bono por bolsas: +30 por cada tipo marcado
        final int bonusCoinsFromSegregados = segregadosCorrectamente * 30;
        // El total final es base + bono
        final double finalTotalMonedasARecibir =
            totalMonedasBase + bonusCoinsFromSegregados.toDouble();

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
              mainAxisSize: MainAxisSize.min, // Ajusta el tamaño
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                const Text(
                  "Resumen de Solicitud",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Listado de cada residuo seleccionado
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
                            color: const Color(0xFF59D999), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "• $tipo",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color.fromARGB(255, 31, 211, 157),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Items: $items"),
                          Text("Cantidad: $kg Kg"),
                          Text("Bolsa individual: $bolsa"),
                        ],
                      ),
                    );
                  }),

                const Divider(thickness: 1.2),
                // Totales (ahora scrollable y adaptable)
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total de Residuos: $totalKg", softWrap: true),
                        Text(" - Monedas (base): $totalMonedasBase",
                            softWrap: true),
                        Text(
                            "Segregados Correctamente: $segregadosCorrectamente",
                            softWrap: true),
                        Text(" - Bono por bolsas: $bonusCoinsFromSegregados",
                            softWrap: true),
                        Text(
                            "Total de Monedas a Recibir: $finalTotalMonedasARecibir",
                            softWrap: true),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Botones "Cancelar" y "Confirmar"
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Cancelar"),
                      onPressed: () {
                        Navigator.of(ctx).pop(); // cierra resumen sin confirmar
                      },
                    ),
                    ElevatedButton(
                      child: const Text("Confirmar"),
                      onPressed: () async {
                        Navigator.of(ctx).pop();

                        // (1) Obtenemos los datos del usuario (dirección, uid, etc.)
                        final userController = Get.find<UserController>();
                        final userData = userController.userModel.value;
                        if (userData == null) {
                          Get.snackbar(
                            "Error",
                            "No se encontró información de usuario.",
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        // (2) Mapeamos los residuos al modelo ResidueItem
                        final Map<String, int> ratesByType = {
                          'Papel y Cartón': 50,
                          'Plástico': 100,
                          'Metales': 50,
                        };

                        final List<ResidueItem> residueItems =
                            resumenResiduos.map((res) {
                          final int kgInt = (res["kg"] as double).toInt();
                          final String tipo = res["tipo"] as String;
                          final bool bolsa = res["bolsa"] as bool;
                          final int rate = ratesByType[tipo] ?? 0;

                          final int coinsBase = kgInt * rate;
                          final int coinsFinal =
                              coinsBase + (bolsa ? 30 : 0); // bono fijo

                          return ResidueItem(
                            approxKg: kgInt.toDouble(),
                            coinsPerType: coinsFinal
                                .toString(), // guardamos el final por tipo
                            individualBag: bolsa,
                            selectedItems:
                                (res["items"] as List).cast<String>(),
                            type: tipo,
                          );
                        }).toList();

                        // (3) Construimos nuestro WasteCollectionModel
                        final totalCoinsFinal =
                            totalMonedasBase + (segregadosCorrectamente * 30);

                        final wasteCollection = WasteCollectionModel(
                          id: '', // se asignará automáticamente
                          address: userData.address,
                          isRecycled: false,
                          totalBags: totalBolsas.toDouble(),
                          totalCoins: totalCoinsFinal,
                          totalKg: totalKg,
                          correctlySegregated: segregadosCorrectamente,
                          residues: residueItems,
                          userReference: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userData.uid),
                          date: DateTime.now(),
                        );

                        // (4) Llamamos al método en el controller para guardar en Firestore
                        await controller.createWasteCollection(wasteCollection);

                        // (5) Notificamos al usuario
                        Get.snackbar(
                          "Solicitud Enviada",
                          "Tu solicitud ha sido confirmada y guardada.",
                          backgroundColor: const Color(0xFF59D999),
                          colorText: Colors.white,
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  //------------------------------------------------------------------
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
              // Se ejecuta cada vez que cambia updateUI
              controller.updateUI.value;

              // Verificamos si hay texto en el campo y si algún botón está seleccionado
              final bool hasText = kgControllers[index].text.isNotEmpty;
              final bool anyButtonSelected =
                  selectedButtons[index].contains(true);
              final bool isEnabled = hasText && anyButtonSelected;

              // Si no hay botones seleccionados, asegurémonos de que el ícono esté gris
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
                            ? const Color(
                                0xFF59D999) // Verde cuando está seleccionado
                            : Colors.grey)
                        : Colors.grey.withOpacity(0.5), // Deshabilitado
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
                  // Cambiar el estado del botón actual
                  selectedButtons[index][itemIndex] =
                      !selectedButtons[index][itemIndex];

                  // Verificar si todos los tipos de residuos están desmarcados
                  final anySelected = selectedButtons[index].contains(true);

                  // Si ningún botón está seleccionado, reiniciar todo
                  if (!anySelected) {
                    // Deshabilitar el campo de kg
                    isKgFieldEnabled[index] = false;

                    // Limpiar el campo de kilos
                    kgControllers[index].clear();

                    // Reiniciar el ícono de segregación correcta
                    selectedIcons[index] = false;

                    // Actualizar los valores unitarios (base)
                    unitValuesBase[index].value = 0.0;

                    // Forzar un rebuild para actualizar la UI
                    controller.refreshUI();
                  } else {
                    // Si hay al menos un botón seleccionado, habilitar el campo
                    isKgFieldEnabled[index] = true;
                  }

                  // Recalcular los totales
                  calculateTotals();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedButtons[index][itemIndex]
                      ? const Color(0xFF59D999)
                      : Colors.grey.shade200,
                  foregroundColor: selectedButtons[index][itemIndex]
                      ? Colors.white
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
                    // Notificar al controlador que debe actualizar la UI
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
                      "${display.toStringAsFixed(0)}",
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

    // Definimos cada tipo de residuo y sus items
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

    // Tarifas por tipo (pts/kg)
    final Map<String, int> ratesByType = {
      'Papel y Cartón': 50,
      'Plástico': 100,
      'Metales': 50,
    };

    // Declaramos variables reactivas para controlar selección y totales
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

    // Creamos un controller y un valor unitValue para cada tipo de residuo
    for (var _ in residuos) {
      kgControllers.add(TextEditingController());
      unitValuesBase.add(0.0.obs);
    }

    // Recalcula totales cuando algo cambia
    void _calculateTotals() {
      totalKg.value = 0.0;
      totalMonedasBase.value = 0.0;
      totalBolsas.value = 0;
      segregadosCorrectamente.value = 0;

      for (var i = 0; i < residuos.length; i++) {
        if (isKgFieldEnabled[i]) {
          // Solo enteros, mínimo 1 para sumar
          final int kgInt = int.tryParse(kgControllers[i].text) ?? 0;
          final int kgValid = kgInt >= 1 ? kgInt : 0;

          final String tipo = residuos[i]["tipo"] as String;
          final int rate = ratesByType[tipo] ?? 0;

          // Base por tipo (sin el bono de bolsa)
          final int baseCoins = kgValid * rate;
          unitValuesBase[i].value = baseCoins.toDouble();

          totalKg.value += kgValid.toDouble();
          totalMonedasBase.value += unitValuesBase[i].value;

          if (selectedIcons[i] && kgValid > 0) {
            // solo cuenta como segregado si hay kg válidos
            segregadosCorrectamente.value += 1;
          }
        }
      }

      // Cada tipo de residuo activado con kg válidos cuenta como 1 bolsa
      totalBolsas.value = 0;
      for (var i = 0; i < residuos.length; i++) {
        if (isKgFieldEnabled[i]) {
          final int kgInt = int.tryParse(kgControllers[i].text) ?? 0;
          if (kgInt >= 1) totalBolsas.value += 1;
        }
      }
    }

    // Listeners para recalcular si se modifican Kg en cualquier TextField
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

                        // Lista en formato enumerado
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
                // Botón final: ahora reactivo y deshabilitado si totalKg <= 0
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
                                // 1) Cerramos este diálogo
                                Navigator.of(ctx).pop();

                                // 2) Generamos un listado de lo que se seleccionó para mostrarlo
                                final List<Map<String, dynamic>> resumen = [];
                                for (var i = 0; i < residuos.length; i++) {
                                  if (isKgFieldEnabled[i]) {
                                    final tipo = residuos[i]["tipo"];
                                    final int kgInt =
                                        int.tryParse(kgControllers[i].text) ??
                                            0;
                                    if (kgInt < 1)
                                      continue; // aseguramos mínimo 1
                                    final kg = kgInt.toDouble();
                                    final bolsa = selectedIcons[i];
                                    // Recolectamos también los items marcados
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

                                // 3) Mostramos el diálogo de confirmación/resumen
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
                            : null, // deshabilita el botón
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

          // Carrusel
          SizedBox(
            height: carouselHeight,
            width: screenWidth,
            child: Obx(() {
              final images = controller.carouselImages;
              if (images.isEmpty) {
                return const Center(
                  child: Text('No hay imágenes para el carrusel'),
                );
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
                                  ? const Color(0xFFFFD700)
                                  : const Color.fromARGB(0, 81, 255, 0),
                              width: 4.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                // Imagen principal
                                Image.network(
                                  imageModel.url,
                                  fit: BoxFit.cover,
                                  width: screenWidth * 0.3,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey);
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),

                                // Texto en la parte inferior directamente sobre la imagen
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    color: const Color.fromRGBO(89, 217, 153, 1)
                                        .withOpacity(0.9),
                                    alignment: Alignment.center,
                                    child: Text(
                                      imageModel.tipo == 'premio'
                                          ? 'premio'
                                          : 'Participación',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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
                              color: const Color.fromARGB(255, 255, 255, 255)
                                  .withOpacity(1),
                              borderRadius: BorderRadius.circular(30),
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
