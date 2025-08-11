// home_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart'; // <--- agrega este import

class HomeController extends GetxController {
  // Índice de la pestaña seleccionada
  RxInt selectedIndex = 0.obs;

  // Para saber si es recolector
  RxBool isCollector = false.obs;

  // Almacén local
  final GetStorage _box = GetStorage('GlobalStorage');

  // Aquí guardamos la info del usuario
  final Map<String, dynamic>? userMap = {};

  // Guarda el total de monedas que obtendremos desde Firestore
  RxDouble totalCoins = 0.0.obs;
  RxBool isLoadingCoins = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Lee el valor que indica si es collector
    isCollector.value = _box.read('iscollector') ?? false;

    // Lee el userData (asegúrate que en tu login lo guardas con la misma clave)
    final Map<String, dynamic>? storedUserMap = _box.read('userData');
    if (storedUserMap != null) {
      userMap?.addAll(storedUserMap);
    }

    // Carga inicial del saldo
    fetchTotalCoins();
  }

  // Método para cambiar de pestaña
  void onItemTapped(int index) {
    selectedIndex.value = index;
  }

  /// Consulta las colecciones 'wasteCollections' y 'redeemedIncentives' en Firestore
  /// para calcular el saldo de monedas del usuario.
  /// Saldo = (suma de wasteCollections.totalCoins donde isRecycled == true)
  ///         - (suma de redeemedIncentives.redeemedCoins)
  Future<void> fetchTotalCoins() async {
    isLoadingCoins.value = true;
    try {
      final String? userId = userMap?['id'] ?? userMap?['uid'];
      if (userId == null) {
        totalCoins.value = 0.0;
        return;
      }

      final DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      double sumWasteCollections = 0.0;
      double sumRedeemedIncentives = 0.0;

      // 1) Sumar totalCoins de wasteCollections donde userReference == userRef y isRecycled == true
      final wasteCollectionsSnap = await FirebaseFirestore.instance
          .collection('wasteCollections')
          .where('userReference', isEqualTo: userRef)
          .where('isRecycled', isEqualTo: true)
          .get();

      for (var doc in wasteCollectionsSnap.docs) {
        final data = doc.data();
        sumWasteCollections += _toDouble(data['totalCoins']);
      }

      // 2) Sumar redeemedCoins de redeemedIncentives donde userReference == userRef
      final redeemedIncentivesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('redeemedIncentives')
          .get();

      for (final doc in redeemedIncentivesSnap.docs) {
        sumRedeemedIncentives += _toDouble(doc.data()['redeemedCoins']);
      }

      // 3) Calcular el total y actualizar el estado
      totalCoins.value = sumWasteCollections - sumRedeemedIncentives;
    } catch (e) {
      print('Error fetching total coins: $e');
      totalCoins.value = 0.0;
    } finally {
      isLoadingCoins.value = false;
    }
  }

  /// Descuenta monedas al instante (UI optimista)
  /// Devuelve una función para revertir si falla la operación.
  VoidCallback optimisticDecrease(int amount) {
    final before = totalCoins.value;
    final next = (before - amount).clamp(0, double.infinity).toDouble();
    totalCoins.value = next;
    return () {
      totalCoins.value = before;
    };
  }

  /// Suma monedas al instante (útil si luego quieres UI optimista al acreditar).
  void increase(int amount) {
    totalCoins.value = (totalCoins.value + amount).clamp(0, double.infinity);
  }

  /// Opcional: refrescar si sospechas que el valor quedó desactualizado
  Future<void> refreshCoinsIfStale() async {
    // Puedes poner heurística aquí (tiempo desde último fetch, etc.)
    await fetchTotalCoins();
  }

  // Conversión genérica a double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
