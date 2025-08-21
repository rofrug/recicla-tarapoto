// lib/app/controllers/homecollector_controller.dart
import 'package:get/get.dart';

import 'package:recicla_tarapoto_1/app/data/models/waste_collection.dart';
import 'package:recicla_tarapoto_1/app/data/provider/wasteCollectionsProvider.dart';

class HomecollectorController extends GetxController {
  final WasteCollectionsProvider _provider = WasteCollectionsProvider();

  /// Recolecciones PENDIENTES (las que ya tienes en la home)
  late Stream<List<WasteCollectionModel>> wasteCollectionsStream;

  /// Recolecciones COMPLETADAS (historial para la home)
  late Stream<List<WasteCollectionModel>> completedCollectionsStream;

  // Flag para estados de actualización
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Solo recolecciones pendientes
    wasteCollectionsStream = _provider.getPendingWasteCollections();

    // Historial: solo recicladas, ordenadas desc por fecha
    // (si el provider ya devuelve ordenadas, este sort es redundante,
    // pero lo mantenemos por seguridad).
    completedCollectionsStream =
        _provider.getCompletedWasteCollections().map((list) {
      final copy = List<WasteCollectionModel>.from(list);
      copy.sort((a, b) {
        final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad); // más recientes primero
      });
      return copy;
    });
  }

  /// Marca como reciclado usando el modelo YA recalculado que viene desde la UI
  /// (con totales y residues actualizados con la fórmula 100/50/50 + 30).
  Future<void> markAsRecycled(WasteCollectionModel waste) async {
    try {
      isUpdating.value = true;

      // Aseguramos que el flag isRecycled quede en true, sin tocar totales/fields.
      final updated = waste.copyWith(isRecycled: true);
      await _provider.updateWasteCollection(waste.id, updated);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo marcar como reciclado');
      rethrow;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Si necesitas actualizar únicamente los residues sin cambiar el estado,
  /// puedes usar este método enviando el modelo completo con residues ya modificados.
  Future<void> updateResidues(WasteCollectionModel waste) async {
    try {
      isUpdating.value = true;
      await _provider.updateWasteCollection(waste.id, waste);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar los residuos');
      rethrow;
    } finally {
      isUpdating.value = false;
    }
  }
}
