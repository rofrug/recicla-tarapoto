// lib/app/controllers/incentives_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart'; // ← para VoidCallback

// Ajusta este import al path real de tu proyecto:
import '../data/models/incentive.dart';
import '../data/provider/incentives_provider.dart';
import 'package:recicla_tarapoto_1/app/controllers/home_controller.dart';

class IncentivesController extends GetxController {
  final IncentivesProvider _provider = IncentivesProvider();

  // Acceso a GetStorage para leer el userId
  final GetStorage _box = GetStorage('GlobalStorage');

  /// Lista observable de incentivos
  RxList<Incentive> incentivesList = <Incentive>[].obs;

  /// Flag para bloquear taps repetidos
  final RxBool _isRedeeming = false.obs;

  bool get isRedeeming => _isRedeeming.value;

  @override
  void onInit() {
    super.onInit();
    _initIncentivesListener();
  }

  /// Suscribirse a la colección incentives.
  void _initIncentivesListener() {
    _provider.getIncentives().listen((incentives) {
      incentivesList.value = incentives;
    });
  }

  /// Canjea un incentivo (1 unidad) con seguridad + UI optimista:
  /// - Verifica usuario
  /// - Verifica monedas (pre-chequeo)
  /// - Descuenta al instante en UI (optimista) y revierte si falla
  /// - Transacción Firestore (stock y registro de canje)
  /// - Reconciliar saldo al final
  Future<void> redeemIncentive(Incentive incentive) async {
    if (_isRedeeming.value) return; // evita doble tap
    _isRedeeming.value = true;

    VoidCallback? revert; // para revertir el optimista si falla
    final home = Get.find<HomeController>();

    try {
      // 1) Identidad de usuario
      final Map<String, dynamic>? userData = _box.read('userData');
      if (userData == null) {
        Get.snackbar('Error', 'No se encontró información del usuario',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final String? userId = userData['id'] ?? userData['uid'];
      if (userId == null) {
        Get.snackbar('Error', 'No se encontró el ID del usuario',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // 2) Pre‑chequeo de monedas (cálculo actual por sumatorias)
      final double currentCoins = await _getCurrentUserCoins(userId);
      final int cost = _safeToInt(incentive.price);
      if (currentCoins < cost) {
        Get.snackbar(
          'Monedas Insuficientes',
          'No tienes suficientes monedas para canjear este incentivo.',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // 3) UI Optimista: descontar al instante en header/modal
      revert = home.optimisticDecrease(cost);

      // 4) Transacción: asegurar stock y registrar canje
      final incentivesRef =
          FirebaseFirestore.instance.collection('incentives').doc(incentive.id);
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final redeemedRef =
          userRef.collection('redeemedIncentives').doc(); // auto-id

      await FirebaseFirestore.instance.runTransaction((t) async {
        // Lee incentivo
        final incSnap = await t.get(incentivesRef);
        if (!incSnap.exists) {
          throw FirebaseException(
              plugin: 'IncentivesController', code: 'incentive-not-found');
        }

        final data = incSnap.data() as Map<String, dynamic>? ?? {};
        final int currentStock = ((data['stock'] ?? 0) as num).toInt();
        if (currentStock <= 0) {
          throw FirebaseException(
              plugin: 'IncentivesController', code: 'out-of-stock');
        }

        // Decrementa stock
        t.update(incentivesRef, {'stock': FieldValue.increment(-1)});

        // Registra el canje (esto "descuenta" monedas por sumatoria)
        t.set(redeemedRef, {
          'incentiveId': incentive.id,
          'name': incentive.name,
          'description': incentive.description,
          'price': cost,
          'image': incentive.image,
          'redeemedCoins': cost,
          'status': 'pendiente',
          'createdAt': FieldValue.serverTimestamp(),
          'incentiveRef': incentivesRef,
          'userRef': userRef,
        });
      });

      // 5) Éxito
      Get.snackbar(
        '¡Felicidades!',
        'Has canjeado el incentivo correctamente. Se ha reservado tu unidad.',
        snackPosition: SnackPosition.TOP,
      );

      // 6) Reconciliar contra BD (por si hubo cambios en paralelo)
      await home.fetchTotalCoins();
    } on FirebaseException catch (e) {
      // 7) Revertir optimista si la transacción falló
      revert?.call();

      if (e.code == 'out-of-stock') {
        Get.snackbar('Sin stock', 'Este incentivo ya no está disponible.',
            snackPosition: SnackPosition.BOTTOM);
      } else if (e.code == 'incentive-not-found') {
        Get.snackbar('Error', 'El incentivo no existe o fue eliminado.',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', 'No se pudo completar el canje (${e.code}).',
            snackPosition: SnackPosition.BOTTOM);
      }

      // Refrescar para quedar consistentes
      await home.fetchTotalCoins();
    } catch (e) {
      // 7) Revertir optimista ante errores inesperados
      revert?.call();
      Get.snackbar('Error', 'Ocurrió un error al canjear el incentivo.',
          snackPosition: SnackPosition.TOP);

      await home.fetchTotalCoins();
    } finally {
      _isRedeeming.value = false;
    }
  }

  /// Suma de coins (ingresos - canjes)
  Future<double> _getCurrentUserCoins(String userId) async {
    double sumWasteCollections = 0.0;
    double sumRedeemedIncentives = 0.0;

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // 1) totalCoins de wasteCollections (recolectas efectivas)
    final wasteCollectionsSnap = await FirebaseFirestore.instance
        .collection('wasteCollections')
        .where('userReference', isEqualTo: userRef)
        .where('isRecycled', isEqualTo: true)
        .get();

    for (var doc in wasteCollectionsSnap.docs) {
      final data = doc.data();
      final num? totalCoins = data['totalCoins'];
      if (totalCoins != null) {
        sumWasteCollections += totalCoins.toDouble();
      }
    }

    // 2) redeemedCoins de redeemedIncentives
    final redeemedSnap = await userRef.collection('redeemedIncentives').get();
    for (var doc in redeemedSnap.docs) {
      final data = doc.data();
      final num? redeemedCoins = data['redeemedCoins'];
      if (redeemedCoins != null) {
        sumRedeemedIncentives += redeemedCoins.toDouble();
      }
    }

    return sumWasteCollections - sumRedeemedIncentives;
  }

  // Métodos extra de tu Provider:
  Future<void> addIncentive(Incentive incentive) async {
    await _provider.addIncentive(incentive);
  }

  Future<void> updateIncentive(String id, Incentive incentive) async {
    await _provider.updateIncentive(id, incentive);
  }

  Future<void> deleteIncentive(String id) async {
    await _provider.deleteIncentive(id);
  }

  // ----------------- Helpers privados -----------------

  int _safeToInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
