import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 👇 Importamos el modelo para parsear los residuos con seguridad
import 'package:recicla_tarapoto_1/app/data/models/residue_item.dart';

class CollectorStatsController extends GetxController {
  // Estado
  final RxBool isLoading = true.obs;
  final Rxn<DateTime> lastUpdated = Rxn<DateTime>();

  // Identidad del recolector
  String? collectorId;

  // Resumen
  final RxDouble totalKgRecolectado = 0.0.obs;
  final RxInt totalRecolecciones = 0.obs;
  final RxInt totalIncentivosEntregados = 0.obs;

  // Totales por tipo y porcentajes
  final RxMap<String, double> kgByType = <String, double>{}.obs;
  final RxMap<String, double> pctByType = <String, double>{}.obs;

  // Tipos conocidos (ajusta si tus strings cambian)
  static const List<String> knownTypes = [
    'Papel y Cartón',
    'Plástico',
    'Metales',
  ];

  // Meta semanal
  final RxDouble weeklyGoalKg = 50.0.obs; // puedes ajustar
  final RxDouble weekKg = 0.0.obs; // calculado
  double get weekProgress => weeklyGoalKg.value == 0
      ? 0
      : (weekKg.value / weeklyGoalKg.value).clamp(0, 1);

  // Entregas pendientes (lista simple)
  // Estructura: {userId, userName, redeemId, premio}
  final RxList<Map<String, dynamic>> pending = <Map<String, dynamic>>[].obs;

  // Próxima recolección (placeholder / opcional)
  final RxString nextRouteLabel = '—'.obs;

  // ==== Ajusta nombres de colecciones/campos si difieren en tu Firestore ====
  static const String kUsersCol = 'users';
  static const String kWasteCollectionsCol = 'wasteCollections';
  static const String kRedeemedIncentivesSub = 'redeemedIncentives';
  static const String kAlertsCol = 'alerts';

  static const String kFieldCollectorId = 'collectorId';
  static const String kFieldTotalKg1 = 'totalKg'; // o 'total_kg'
  static const String kFieldTotalKg2 = 'total_kg';
  static const String kFieldIsRecycled = 'isRecycled';
  static const String kFieldStatus =
      'status'; // 'completado' / 'completed' / 'finalizado'
  static const String kFieldCreatedAt = 'createdAt';

  static const String kFieldDeliveredBy = 'deliveredBy';
  static const String kFieldDeliveredAt = 'deliveredAt';

  @override
  void onInit() {
    super.onInit();
    final box = GetStorage('GlobalStorage');
    final userData = box.read('userData');
    if (userData is Map && userData['uid'] is String) {
      collectorId = userData['uid'] as String;
    }
    _loadAll();
  }

  Future<void> reload() async {
    await _loadAll();
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadWasteCollectionsTotals(),
        _loadWeekKg(),
        _loadDeliveredIncentives(),
        _loadPendingIncentives(),
        _loadKgByType(), // 👈 NUEVO: totales por tipo + %
        _loadNextRouteLabel(), // opcional
      ]);
      lastUpdated.value = DateTime.now();
    } catch (e, st) {
      // ignore: avoid_print
      print('❗ CollectorStats _loadAll error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  // -------- Residuos Totales & Recolecciones --------
  Future<void> _loadWasteCollectionsTotals() async {
    double kg = 0.0;
    int count = 0;

    try {
      final col = FirebaseFirestore.instance.collection(kWasteCollectionsCol);
      final snap = await col.get();

      for (final d in snap.docs) {
        final data = d.data();

        // Filtra por recolector si existe el campo en el doc
        final docCollector = data[kFieldCollectorId];
        if (collectorId != null && docCollector is String) {
          if (docCollector != collectorId) continue;
        }

        // Solo recolecciones completadas
        final status = (data[kFieldStatus] as String?)?.toLowerCase();
        final isRecycled = data[kFieldIsRecycled] == true;
        final completado = isRecycled == true ||
            status == 'completado' ||
            status == 'completed' ||
            status == 'finalizado';
        if (!completado) continue;

        num? tk = data[kFieldTotalKg1] as num?;
        tk ??= data[kFieldTotalKg2] as num?;
        if (tk != null) kg += tk.toDouble();
        count++;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('❗ _loadWasteCollectionsTotals error: $e\n$st');
    }

    totalKgRecolectado.value = kg;
    totalRecolecciones.value = count;
  }

  // -------- Kg de la semana (últimos 7 días) --------
  Future<void> _loadWeekKg() async {
    double sum = 0.0;
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final col = FirebaseFirestore.instance.collection(kWasteCollectionsCol);
      final snap = await col.get();

      for (final d in snap.docs) {
        final data = d.data();

        // Filtra por recolector si existe el campo
        final docCollector = data[kFieldCollectorId];
        if (collectorId != null && docCollector is String) {
          if (docCollector != collectorId) continue;
        }

        // completado?
        final status = (data[kFieldStatus] as String?)?.toLowerCase();
        final isRecycled = data[kFieldIsRecycled] == true;
        final completado = isRecycled == true ||
            status == 'completado' ||
            status == 'completed' ||
            status == 'finalizado';
        if (!completado) continue;

        // rango de fecha
        final ts = data[kFieldCreatedAt];
        DateTime? dt;
        if (ts is Timestamp) dt = ts.toDate();
        if (ts is DateTime) dt = ts;
        if (dt == null) continue;

        if (dt.isAfter(weekAgo) &&
            dt.isBefore(now.add(const Duration(minutes: 1)))) {
          num? tk = data[kFieldTotalKg1] as num?;
          tk ??= data[kFieldTotalKg2] as num?;
          if (tk != null) sum += tk.toDouble();
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('❗ _loadWeekKg error: $e\n$st');
    }
    weekKg.value = sum;
  }

  // -------- Incentivos ENTREGADOS --------
  Future<void> _loadDeliveredIncentives() async {
    int total = 0;
    try {
      final usersCol = FirebaseFirestore.instance.collection(kUsersCol);
      final usersSnap = await usersCol.get();

      for (final u in usersSnap.docs) {
        final redCol = usersCol.doc(u.id).collection(kRedeemedIncentivesSub);
        final redSnap = await redCol.get();

        for (final d in redSnap.docs) {
          final data = d.data();

          final st = (data[kFieldStatus] as String?)?.toLowerCase();
          final completado =
              st == 'completado' || st == 'completed' || st == 'finalizado';
          if (!completado) continue;

          // Si ya guardas deliveredBy, filtra. Si no, cuenta igual
          final deliveredBy = data[kFieldDeliveredBy];
          if (collectorId != null && deliveredBy is String) {
            if (deliveredBy != collectorId) continue;
          }

          total++;
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('❗ _loadDeliveredIncentives error: $e\n$st');
    }
    totalIncentivosEntregados.value = total;
  }

  // -------- Entregas pendientes --------
  Future<void> _loadPendingIncentives() async {
    final List<Map<String, dynamic>> list = [];
    try {
      final usersCol = FirebaseFirestore.instance.collection(kUsersCol);
      final usersSnap = await usersCol.get();

      for (final u in usersSnap.docs) {
        final userData = u.data();
        final userName =
            (userData['name'] ?? userData['fullname'] ?? u.id).toString();

        final redCol = usersCol.doc(u.id).collection(kRedeemedIncentivesSub);
        final redSnap = await redCol.get();

        for (final d in redSnap.docs) {
          final data = d.data();

          final st = (data[kFieldStatus] as String?)?.toLowerCase();
          final completado =
              st == 'completado' || st == 'completed' || st == 'finalizado';
          if (completado) continue;

          list.add({
            'userId': u.id,
            'userName': userName,
            'redeemId': d.id,
            'premio': (data['incentiveName'] ?? data['name'] ?? 'Incentivo')
                .toString(),
          });
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('❗ _loadPendingIncentives error: $e\n$st');
    }
    pending.assignAll(list);
  }

  Future<void> markDelivered(String userId, String redeemId) async {
    try {
      final doc = FirebaseFirestore.instance
          .collection(kUsersCol)
          .doc(userId)
          .collection(kRedeemedIncentivesSub)
          .doc(redeemId);

      await doc.update({
        kFieldStatus: 'completado',
        kFieldDeliveredBy: collectorId,
        kFieldDeliveredAt: FieldValue.serverTimestamp(),
      });

      // Actualiza UI local
      pending.removeWhere(
          (e) => e['userId'] == userId && e['redeemId'] == redeemId);
      totalIncentivosEntregados.value++;
      lastUpdated.value = DateTime.now();
      Get.snackbar('Incentivo', 'Marcado como entregado',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e, st) {
      // ignore: avoid_print
      print('❗ markDelivered error: $e\n$st');
      Get.snackbar('Error', 'No se pudo marcar como entregado',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // -------- Próxima recolección (placeholder) --------
  Future<void> _loadNextRouteLabel() async {
    nextRouteLabel.value = 'Miércoles 7:00–15:30 (Zona A)';
  }

  // -------- Totales por tipo + porcentajes --------
  Future<void> _loadKgByType() async {
    // Inicializar con 0 para asegurar claves presentes
    final Map<String, double> acc = {
      for (final t in knownTypes) t: 0.0,
    };

    try {
      final col = FirebaseFirestore.instance.collection(kWasteCollectionsCol);
      final snap = await col.get();

      for (final d in snap.docs) {
        final data = d.data();

        // Filtra por recolector si existe el campo
        final docCollector = data[kFieldCollectorId];
        if (collectorId != null && docCollector is String) {
          if (docCollector != collectorId) continue;
        }

        // Solo registros completados
        final status = (data[kFieldStatus] as String?)?.toLowerCase();
        final isRecycled = data[kFieldIsRecycled] == true;
        final completado = isRecycled == true ||
            status == 'completado' ||
            status == 'completed' ||
            status == 'finalizado';
        if (!completado) continue;

        // Leer residuos (array)
        final rawResidues = data['residues'];
        if (rawResidues is List) {
          for (final r in rawResidues) {
            if (r is Map<String, dynamic>) {
              final item = ResidueItem.fromMap(r);
              final normalized = _normalizeType(item.type);
              if (normalized == null) continue;
              acc[normalized] = (acc[normalized] ?? 0.0) + item.approxKg;
            }
          }
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('❗ _loadKgByType error: $e\n$st');
    }

    // Actualizar kg por tipo
    kgByType
      ..clear()
      ..addAll(acc);

    // Calcular porcentajes
    final total = acc.values.fold<double>(0.0, (a, b) => a + b);
    final Map<String, double> pct = {};
    if (total > 0) {
      acc.forEach((k, v) {
        pct[k] = double.parse(((v / total) * 100).toStringAsFixed(1));
      });
    } else {
      for (final t in knownTypes) {
        pct[t] = 0.0;
      }
    }

    pctByType
      ..clear()
      ..addAll(pct);
  }

  // Normaliza nombres de tipo del dato crudo a los "knownTypes"
  String? _normalizeType(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return null;

    if (t.contains('papel') || t.contains('cartón') || t.contains('carton')) {
      return 'Papel y Cartón';
    }
    if (t.contains('plast')) {
      return 'Plástico';
    }
    if (t.contains('metal') || t.contains('chatarra') || t.contains('lata')) {
      return 'Metales';
    }
    // Si no coincide, puedes retornarlo tal cual o ignorarlo.
    // return raw; // <- si quieres conservar otros tipos
    return null; // <- ignorar tipos desconocidos
  }

  // Helpers para leer desde la UI
  double kgFor(String type) => kgByType[type] ?? 0.0;
  double pctFor(String type) => pctByType[type] ?? 0.0;

  /// Estructura útil para pie charts u otros widgets:
  /// [{label: 'Plástico', value: 60.0}, ...] en %
  List<Map<String, dynamic>> get pieData {
    return knownTypes
        .map((t) => {
              'label': t,
              'value': pctFor(t),
            })
        .toList();
  }

  Future<void> createDelayAlert({String? message}) async {
    try {
      await FirebaseFirestore.instance.collection(kAlertsCol).add({
        'type': 'retraso',
        'collectorId': collectorId,
        'message': message ?? 'Retraso en la ruta',
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Aviso enviado', 'Se notificará a los usuarios de tu zona',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e, st) {
      // ignore: avoid_print
      print('❗ createDelayAlert error: $e\n$st');
      Get.snackbar('Error', 'No se pudo enviar el aviso',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
