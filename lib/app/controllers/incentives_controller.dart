// lib/app/controllers/incentives_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart'; // VoidCallback

// Ajusta estos imports si tu estructura cambia
import '../data/models/incentive.dart';
import '../data/provider/incentives_provider.dart';
import 'package:recicla_tarapoto_1/app/controllers/home_controller.dart';

class IncentivesController extends GetxController {
  final IncentivesProvider _provider = IncentivesProvider();

  // Acceso a GetStorage para leer el userId
  final GetStorage _box = GetStorage('GlobalStorage');

  /// Lista observable de incentivos
  RxList<Incentive> incentivesList = <Incentive>[].obs;

  /// Flag público para bloquear taps repetidos (observable para la UI)
  final RxBool isRedeeming = false.obs;

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

  /// Nueva API: canjear y devolver éxito/fracaso.
  /// - NO navega ni cierra diálogos (la vista lo hace).
  /// - Bloquea doble-tap con [isRedeeming].
  /// - UI optimista sobre el header de monedas, con revert si falla.
  Future<bool> confirmRedeem(Incentive incentive) async {
    if (isRedeeming.value) return false; // ⛔ ya en curso
    isRedeeming.value = true;

    VoidCallback? revert; // para revertir el optimista si falla
    final home = Get.find<HomeController>();

    try {
      // 1) Identidad de usuario
      final Map<String, dynamic>? userData = _box.read('userData');
      if (userData == null) {
        Get.snackbar('Error', 'No se encontró información del usuario',
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      final String? userId = userData['id'] ?? userData['uid'];
      if (userId == null) {
        Get.snackbar('Error', 'No se encontró el ID del usuario',
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      // 2) Pre-chequeo de monedas
      final double currentCoins = await _getCurrentUserCoins(userId);
      final int cost = _safeToInt(incentive.price);
      if (currentCoins < cost) {
        Get.snackbar(
          'Monedas insuficientes',
          'No tienes suficientes monedas para canjear este incentivo.',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      // 3) UI Optimista
      revert = home.optimisticDecrease(cost);

      // 4) Transacción Firestore (stock y registro de canje)
      final DocumentReference<Map<String, dynamic>> incentivesRef =
          FirebaseFirestore.instance.collection('incentives').doc(incentive.id);
      final DocumentReference<Map<String, dynamic>> userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final DocumentReference<Map<String, dynamic>> redeemedRef =
          userRef.collection('redeemedIncentives').doc(); // auto-id

      await FirebaseFirestore.instance.runTransaction((t) async {
        final DocumentSnapshot<Map<String, dynamic>> incSnap =
            await t.get(incentivesRef);
        if (!incSnap.exists) {
          throw FirebaseException(
              plugin: 'IncentivesController', code: 'incentive-not-found');
        }

        final Map<String, dynamic> data = incSnap.data() ?? {};
        final int currentStock = ((data['stock'] ?? 0) as num).toInt();
        if (currentStock <= 0) {
          throw FirebaseException(
              plugin: 'IncentivesController', code: 'out-of-stock');
        }

        // Decrementa stock
        t.update(incentivesRef, {'stock': FieldValue.increment(-1)});

        // Registra el canje (resto por sumatoria)
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

      // 6) Reconciliar saldo por si hubo cambios paralelos
      await home.fetchTotalCoins();

      return true;
    } on FirebaseException catch (e) {
      // Revertir optimista
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

      await home.fetchTotalCoins();
      return false;
    } catch (e) {
      // Revertir optimista ante errores inesperados
      revert?.call();
      Get.snackbar('Error', 'Ocurrió un error al canjear el incentivo.',
          snackPosition: SnackPosition.TOP);

      await home.fetchTotalCoins();
      return false;
    } finally {
      isRedeeming.value = false;
    }
  }

  /// Suma de coins (ingresos - canjes)
  Future<double> _getCurrentUserCoins(String userId) async {
    double sumWasteCollections = 0.0;
    double sumRedeemedIncentives = 0.0;

    final DocumentReference<Map<String, dynamic>> userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    // 1) totalCoins de wasteCollections (recolectas efectivas)
    final QuerySnapshot<Map<String, dynamic>> wasteCollectionsSnap =
        await FirebaseFirestore.instance
            .collection('wasteCollections')
            .where('userReference', isEqualTo: userRef)
            .where('isRecycled', isEqualTo: true)
            .get();

    for (final doc in wasteCollectionsSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      final num? totalCoins = data['totalCoins'];
      if (totalCoins != null) {
        sumWasteCollections += totalCoins.toDouble();
      }
    }

    // 2) redeemedCoins de redeemedIncentives
    final QuerySnapshot<Map<String, dynamic>> redeemedSnap =
        await userRef.collection('redeemedIncentives').get();
    for (final doc in redeemedSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      final num? redeemedCoins = data['redeemedCoins'];
      if (redeemedCoins != null) {
        sumRedeemedIncentives += redeemedCoins.toDouble();
      }
    }

    return sumWasteCollections - sumRedeemedIncentives;
  }

  // Métodos extra de tu Provider (sin cambios)
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
