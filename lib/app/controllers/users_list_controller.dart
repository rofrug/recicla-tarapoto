import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:recicla_tarapoto_1/app/controllers/user_controller.dart';
import 'package:recicla_tarapoto_1/app/data/models/usermodel.dart';

class UserQuickStats {
  final double totalKg;
  final int totalRecolecciones;
  final int totalIncentivos;
  final bool loading;
  final String? error;

  const UserQuickStats({
    this.totalKg = 0.0,
    this.totalRecolecciones = 0,
    this.totalIncentivos = 0,
    this.loading = false,
    this.error,
  });

  UserQuickStats copyWith({
    double? totalKg,
    int? totalRecolecciones,
    int? totalIncentivos,
    bool? loading,
    String? error,
  }) {
    return UserQuickStats(
      totalKg: totalKg ?? this.totalKg,
      totalRecolecciones: totalRecolecciones ?? this.totalRecolecciones,
      totalIncentivos: totalIncentivos ?? this.totalIncentivos,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class UsersListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserController _userController = Get.find<UserController>();

  /// Control de expansión única (solo un tile abierto)
  final RxString expandedUid = ''.obs;

  /// Stream de usuarios (generadores), filtrado en cliente.
  Stream<List<UserModel>> get usersStream {
    return _firestore.collection('users').snapshots().map((snap) {
      final currentUid = _userController.userModel.value?.uid ?? '';
      final list = snap.docs.map((doc) {
        final data = doc.data();
        final model = UserModel.fromFirestore(data);
        final uid = model.uid.isEmpty ? doc.id : model.uid;
        return UserModel(
          address: model.address,
          dni: model.dni,
          lastname: model.lastname,
          name: model.name,
          phoneNumber: model.phoneNumber,
          iscollector: model.iscollector,
          typeUser: model.typeUser,
          uid: uid,
        );
      }).toList();

      final filtered = list.where((u) {
        if (u.uid == currentUid) return false; // excluir actual
        if (u.iscollector == true) return false; // excluir recolectores
        final hasRecolectorType = u.typeUser
            .map((t) => t.toLowerCase())
            .any((t) => t.contains('recolector') || t.contains('collector'));
        if (hasRecolectorType) return false;
        return true; // generador
      }).toList();

      filtered.sort((a, b) {
        final aKey = ('${a.name} ${a.lastname}').trim().toLowerCase();
        final bKey = ('${b.name} ${b.lastname}').trim().toLowerCase();
        return aKey.compareTo(bKey);
      });

      return filtered;
    });
  }

  /// Mapa reactivo de KPIs por usuario.
  final RxMap<String, UserQuickStats> statsByUid =
      <String, UserQuickStats>{}.obs;

  UserQuickStats? getStats(String uid) => statsByUid[uid];

  /// Maneja la expansión única + carga perezosa de stats.
  void toggleExpanded(String uid, bool expanded) {
    if (expanded) {
      expandedUid.value = uid; // abrir este y cerrar otros
      loadStatsFor(uid); // cargar stats on-demand
    } else {
      if (expandedUid.value == uid) {
        expandedUid.value = ''; // cerrar si era el mismo
      }
    }
  }

  /// Carga perezosa (on-demand) las métricas del usuario y las cachea.
  Future<void> loadStatsFor(String uid) async {
    final current = statsByUid[uid];
    if (current != null &&
        (current.loading ||
            (current.error == null &&
                (current.totalRecolecciones > 0 ||
                    current.totalIncentivos > 0 ||
                    current.totalKg > 0)))) {
      // ya hay datos o está cargando
      return;
    }

    statsByUid[uid] = (current ?? const UserQuickStats())
        .copyWith(loading: true, error: null);

    try {
      final userRef = _firestore.doc('users/$uid');

      // 1) Recolecciones completadas
      final wcSnap = await _firestore
          .collection('wasteCollections')
          .where('userReference', isEqualTo: userRef)
          .where('isRecycled', isEqualTo: true)
          .get();

      double sumKg = 0.0;
      for (final d in wcSnap.docs) {
        final data = d.data();
        final kg = data['totalKg'];
        if (kg is num) sumKg += kg.toDouble();
      }
      final totalRecolecciones = wcSnap.docs.length;

      // 2) Incentivos completados
      final incSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('redeemedIncentives')
          .where('status', isEqualTo: 'completado')
          .get();
      final totalIncentivos = incSnap.docs.length;

      statsByUid[uid] = UserQuickStats(
        totalKg: sumKg,
        totalRecolecciones: totalRecolecciones,
        totalIncentivos: totalIncentivos,
        loading: false,
        error: null,
      );
    } catch (e) {
      statsByUid[uid] = (statsByUid[uid] ?? const UserQuickStats())
          .copyWith(loading: false, error: 'Error: $e');
    }
  }
}
