// lib/modules/home/controllers/home_screen_controller.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/waste_collection.dart';
import '../data/models/carousel_image.dart';
import '../data/provider/home_provider.dart';

class HomeScreenController extends GetxController {
  // Disparador para forzar rebuilds ligeros en la UI
  final updateUI = 0.obs;

  // Flag de envío
  final RxBool isSubmitting = false.obs;

  // Tarifas por tipo (pts/kg) centralizadas
  // Nota: si luego las traemos de backend, solo actualizamos aquí.
  final Map<String, int> ratesByType = const {
    'Papel y Cartón': 50,
    'Plástico': 100,
    'Metales': 50,
  };

  // Bono fijo por "bolsa individual" (por tipo)
  final int bonusPerBag = 30;

  // Determina si el icono de bolsa debe estar habilitado para un controlador de texto dado
  bool isShoppingBagEnabled(TextEditingController controller) {
    return controller.text.isNotEmpty;
  }

  // Forzar actualización de la UI cuando cambia un campo de texto
  void refreshUI() {
    updateUI.value++;
  }

  // Controlador de scroll
  late ScrollController scrollController;

  // Lista observable para el carrusel
  RxList<CarouselImage> carouselImages = <CarouselImage>[].obs;

  // Provider
  final HomeProvider _homeProvider = HomeProvider();

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();

    // Escucha de la colección "carousel_image"
    _initCarouselImagesListener();

    // Auto-scroll una vez montado
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll());
  }

  /// Suscribirse a la colección "carousel_image" y actualizar la lista observable
  void _initCarouselImagesListener() {
    _homeProvider.getCarouselImages().listen((imageList) {
      carouselImages.value = imageList;
    });
  }

  /// Desplazamiento automático para el carrusel (scroll infinito simulado)
  void _autoScroll() {
    // Cada 100ms avanza 1 pixel
    Timer.periodic(const Duration(milliseconds: 5), (timer) {
      if (scrollController.hasClients) {
        final double maxScroll = scrollController.position.maxScrollExtent;
        final double currentScroll = scrollController.position.pixels;
        final double newScroll = currentScroll + 0.1;

        if (newScroll >= maxScroll) {
          scrollController.jumpTo(0); // Reinicia el scroll
        } else {
          scrollController.jumpTo(newScroll);
        }
      }
    });
  }

  /// Helpers opcionales para centralizar el cálculo (si luego quieres mover la lógica aquí)
  int calcBaseCoinsForType({
    required String type,
    required int kg,
  }) {
    if (kg < 1) return 0;
    final rate = ratesByType[type] ?? 0;
    return kg * rate;
  }

  int calcBonusForType({
    required bool individualBag,
    required int kg,
  }) {
    // Solo otorgar bono si hay kg válidos
    if (!individualBag || kg < 1) return 0;
    return bonusPerBag;
  }

  int calcTotalForType({
    required String type,
    required int kg,
    required bool individualBag,
  }) {
    return calcBaseCoinsForType(type: type, kg: kg) +
        calcBonusForType(individualBag: individualBag, kg: kg);
  }

  int calcTotalWithBonus({
    required int totalBaseCoins,
    required int segregatedTypesCount,
  }) {
    return totalBaseCoins + (segregatedTypesCount * bonusPerBag);
  }

  /// Crea una nueva solicitud de recolección en "wasteCollections"
  /// Bloquea el envío si totalKg <= 0 (mínimo 1 Kg).
  Future<void> createWasteCollection(WasteCollectionModel wasteData) async {
    if (wasteData.totalKg <= 0) {
      Get.snackbar(
        "Datos inválidos",
        "Debes ingresar al menos 1 Kg para enviar la solicitud.",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      await FirebaseFirestore.instance
          .collection('wasteCollections')
          .add(wasteData.toFirestore());
      // Si necesitas limpiar estados locales, hazlo aquí.
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo guardar la solicitud. Intenta nuevamente.",
        snackPosition: SnackPosition.TOP,
      );
      rethrow;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
