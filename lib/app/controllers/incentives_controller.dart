// lib/app/controllers/incentives_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Ajusta este import al path real de tu proyecto:
import '../data/models/incentive.dart';
// Si realmente lo tienes en data/models, usa:
// import '../data/models/incentive.dart';

import '../data/provider/incentives_provider.dart';

// ✅ Importa HomeController para el saldo reactivo + optimista
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

  /// Canjea un incentivo (1 unidad) con seguridad:
  /// - Verifica usuario
  /// - Verifica monedas (pre-chequeo)
  /// - Transacción Firestore: decrementa stock ATÓMICAMENTE y registra el canje
  /// - UI optimista: descuenta al instante y revierte si falla
  Future<void> redeemIncentive(Incentive incentive) async {
    if (_isRedeeming.value) return; // evita doble tap
    _isRedeeming.value = true;

    try {
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

      // Pre-chequeo de monedas (cálculo actual por sumatorias)
      final double currentCoins = await _getCurrentUserCoins(userId);
      final int cost = _safeToInt(incentive.price);
      if (currentCoins < cost) {
        Get.snackbar('Monedas Insuficientes',
            'No tienes suficientes monedas para canjear este incentivo.',
            snackPosition: SnackPosition.TOP);
        return;
      }

      // ✅ UI Optimista: descontar de inmediato en el header/modal
      final home = Get.find<HomeController>();
      final revert = home.optimisticDecrease(cost);

      // Transacción: asegurar stock y registrar canje
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
          // Stock insuficiente: abortar transacción
          throw FirebaseException(
              plugin: 'IncentivesController', code: 'out-of-stock');
        }

        // Decrementa stock
        t.update(incentivesRef, {
          'stock': FieldValue.increment(-1),
        });

        // Registra el canje (esto "descuenta" monedas en tu modelo por sumatoria)
        t.set(redeemedRef, {
          'incentiveId': incentive.id,
          'name': incentive.name,
          'description': incentive.description,
          'price': cost, // costo en monedas
          'image': incentive.image,
          'redeemedCoins': cost,
          'status': 'pendiente',
          'createdAt': FieldValue.serverTimestamp(),
          // extras útiles para auditoría
          'incentiveRef': incentivesRef,
          'userRef': userRef,
        });
      });

      // Éxito
      Get.snackbar('¡Felicidades!',
          'Has canjeado el incentivo correctamente. Se ha reservado tu unidad.',
          snackPosition: SnackPosition.TOP);

      // ✅ Reconciliar contra BD (por si hubo cambios en paralelo)
      await home.fetchTotalCoins();
    } on FirebaseException catch (e) {
      // Si falla la transacción, revertir el optimista
      _safeRevertOptimistic();

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
    } catch (e) {
      // Revertir ante errores inesperados
      _safeRevertOptimistic();
      Get.snackbar('Error', 'Ocurrió un error al canjear el incentivo.',
          snackPosition: SnackPosition.TOP);
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

  void _safeRevertOptimistic() {
    // Si el HomeController existe, intenta revertir al último optimista.
    // Nota: optimista devuelve un callback; aquí podemos guardar y llamar.
    // Para simplificar, dispararemos un refresh total (que también "repara" UI).
    try {
      final home = Get.find<HomeController>();
      home.fetchTotalCoins();
    } catch (_) {
      // HomeController no encontrado; no hacemos nada.
    }
  }
}
