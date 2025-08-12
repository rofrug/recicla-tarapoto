// lib/modules/home/controllers/home_screen_controller.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/waste_collection.dart';
import '../data/models/carousel_image.dart';
import '../data/provider/home_provider.dart';

class HomeScreenController extends GetxController {
  // Variable reactiva para actualizar la interfaz cuando cambia el texto de los campos
  final updateUI = 0.obs;

  // (Opcional) Flag para indicar envío en progreso
  final RxBool isSubmitting = false.obs;

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

  // Lista observable de URLs para el carrusel, proveniente de Firebase
  RxList<CarouselImage> carouselImages = <CarouselImage>[].obs;

  // Provider
  final HomeProvider _homeProvider = HomeProvider();

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();

    // Iniciamos la escucha de la colección "carousel_image"
    _initCarouselImagesListener();

    // Una vez que el widget esté montado, iniciamos el desplazamiento automático
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll());
  }

  /// Suscribirse a la colección "carousel_image" y actualizar la lista observable
  void _initCarouselImagesListener() {
    _homeProvider.getCarouselImages().listen((imageList) {
      carouselImages.value = imageList;
    });
  }

  /// Desplazamiento automático (scroll infinito simulado) para el carrusel
  void _autoScroll() {
    // Cada 100ms avanza 1 pixel
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (scrollController.hasClients) {
        final double maxScroll = scrollController.position.maxScrollExtent;
        final double currentScroll = scrollController.position.pixels;
        final double newScroll = currentScroll + 1;

        if (newScroll >= maxScroll) {
          scrollController.jumpTo(0); // Reinicia el scroll
        } else {
          scrollController.jumpTo(newScroll);
        }
      }
    });
  }

  /// Crea una nueva solicitud de recolección en la colección "wasteCollections"
  /// Bloquea el envío si totalKg <= 0 (validación dura en capa de presentación).
  Future<void> createWasteCollection(WasteCollectionModel wasteData) async {
    // 🔒 Validación dura: no permitir solicitudes sin peso
    if (wasteData.totalKg <= 0) {
      Get.snackbar(
        "Datos inválidos",
        "Debes ingresar al menos 0.1 Kg para enviar la solicitud.",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // (Opcional) podrías validar que existan residuos seleccionados:
    // if (wasteData.residues.isEmpty) { ... return; }

    isSubmitting.value = true;
    try {
      await FirebaseFirestore.instance
          .collection('wasteCollections')
          .add(wasteData.toFirestore());

      // Podrías limpiar estados aquí si manejas algo en memoria
      // ...
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
