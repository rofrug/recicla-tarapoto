import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recicla_tarapoto_1/app/controllers/user_controller.dart';

class AppNotification {
  final String type;
  final String title;
  final DateTime date;
  final String description;
  final String? originalId;
  final bool isNew;

  AppNotification({
    required this.type,
    required this.title,
    required this.date,
    required this.description,
    this.originalId,
    this.isNew = false,
  });

  AppNotification copyWith({
    String? type,
    String? title,
    DateTime? date,
    String? description,
    String? originalId,
    bool? isNew,
  }) {
    return AppNotification(
      type: type ?? this.type,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      originalId: originalId ?? this.originalId,
      isNew: isNew ?? this.isNew,
    );
  }
}

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserController _userController = Get.find<UserController>();
  final GetStorage _box = GetStorage('GlobalStorage');

  // Estado
  RxBool isLoading = true.obs;
  RxList<AppNotification> notifications = <AppNotification>[].obs;

  // Badge y modal
  RxInt newNotificationsCount = 0.obs;
  RxBool isModalOpen = false.obs;

  // Paginación
  RxInt notificationsToShow = 12.obs;

  // Streams
  StreamSubscription? _wcSub;
  StreamSubscription? _riSub;
  StreamSubscription? _anSub;

  // ---- LastSeen por usuario ----
  String get _lastSeenKey {
    final uid = _userController.userModel.value?.uid ?? 'unknown';
    return 'lastNotificationsSeenAt_$uid';
  }

  DateTime _getLastSeen() {
    final ms = _box.read(_lastSeenKey);
    if (ms is int) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _setLastSeen(DateTime dt) {
    _box.write(_lastSeenKey, dt.millisecondsSinceEpoch);
  }

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    _attachRealtimeListeners();
    ever(_userController.userModel, (_) {
      fetchNotifications();
      _attachRealtimeListeners();
    });
  }

  void _attachRealtimeListeners() {
    _wcSub?.cancel();
    _riSub?.cancel();
    _anSub?.cancel();

    final uid = _userController.userModel.value?.uid;
    if (uid == null) return;

    _wcSub = _firestore
        .collection('wasteCollections')
        .where('userReference', isEqualTo: _firestore.doc('users/$uid'))
        .where('isRecycled', isEqualTo: true)
        .snapshots()
        .listen((_) => fetchNotifications());

    _riSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('redeemedIncentives')
        .where('status', isEqualTo: 'completado')
        .snapshots()
        .listen((_) => fetchNotifications());

    _anSub = _firestore
        .collection('announcements')
        .snapshots()
        .listen((_) => fetchNotifications());
  }

  @override
  void onClose() {
    _wcSub?.cancel();
    _riSub?.cancel();
    _anSub?.cancel();
    super.onClose();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      notificationsToShow.value = 12;

      final String? uid = _userController.userModel.value?.uid;
      if (uid == null) {
        isLoading.value = false;
        newNotificationsCount.value = 0;
        notifications.clear();
        return;
      }

      // ⬇️ Opción B: una sola lectura de lastSeen y reutilización
      final lastSeenRaw = _box.read(_lastSeenKey); // detectar primer arranque
      DateTime lastSeen = _getLastSeen(); // usar en comparaciones

      final List<AppNotification> fetched = [];

      // 1) Monedas
      try {
        final snap = await _firestore
            .collection('wasteCollections')
            .where('userReference', isEqualTo: _firestore.doc('users/$uid'))
            .where('isRecycled', isEqualTo: true)
            .get();
        for (var doc in snap.docs) {
          final data = doc.data();
          final dt = (data['date'] as Timestamp).toDate();
          fetched.add(AppNotification(
            type: 'monedas',
            title: 'Monedas Recibidas',
            date: dt,
            description:
                'Recibiste un total de ${data['totalCoins']} monedas por tu entrega de residuos.',
            originalId: doc.id,
          ));
        }
      } catch (_) {}

      // 2) Incentivo
      try {
        final snap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('redeemedIncentives')
            .where('status', isEqualTo: 'completado')
            .get();
        for (var doc in snap.docs) {
          final data = doc.data();
          final dt = (data['createdAt'] as Timestamp).toDate();
          fetched.add(AppNotification(
            type: 'incentivo',
            title: 'Incentivo Canjeado',
            date: dt,
            description:
                'Canjeaste el incentivo "${data['name']}" por ${data['redeemedCoins']} monedas.',
            originalId: doc.id,
          ));
        }
      } catch (_) {}

      // 3) Actualización
      try {
        final snap = await _firestore.collection('announcements').get();
        for (var doc in snap.docs) {
          final data = doc.data();
          final dt = (data['createdAt'] as Timestamp).toDate();
          fetched.add(AppNotification(
            type: 'actualizacion',
            title: data['title'] ?? 'Actualización Importante',
            date: dt,
            description: data['content'] ?? 'No hay contenido.',
            originalId: doc.id,
          ));
        }
      } catch (_) {}

      // Orden desc y baseline de primer arranque
      fetched.sort((a, b) => b.date.compareTo(a.date));
      final bool isFirstLaunchForUser = (lastSeenRaw == null);
      if (isFirstLaunchForUser && fetched.isNotEmpty) {
        final now = DateTime.now();
        _setLastSeen(now);
        lastSeen = now; // ✅ actualizamos la variable local para esta ejecución
      }

      // Flags isNew contra el 'lastSeen' ya consolidado
      final withFlags = fetched
          .map((n) => n.copyWith(isNew: n.date.isAfter(lastSeen)))
          .toList();

      notifications.assignAll(withFlags);

      // Si el modal está abierto, el badge queda en 0; si no, cuenta reales
      final count = withFlags.where((n) => n.isNew).length;
      newNotificationsCount.value = isModalOpen.value ? 0 : count;
    } catch (e) {
      notifications.clear();
      newNotificationsCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Formato de fecha
  String formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy hh:mm a').format(date);
    } catch (e) {
      return date.toIso8601String();
    }
  }

  // Paginación en memoria
  void loadMore() {
    final total = notifications.length;
    final current = notificationsToShow.value;
    if (current < total) {
      final next = current + 12;
      notificationsToShow.value = next > total ? total : next;
    }
  }

  // --- Control del modal ---
  void openModal() {
    isModalOpen.value = true;
    newNotificationsCount.value = 0; // oculta badge al toque
  }

  void closeModal() {
    isModalOpen.value = false;
    _setLastSeen(DateTime.now()); // marca todo visto "hasta ahora"
    if (notifications.isNotEmpty) {
      notifications.assignAll(
        notifications.map((n) => n.copyWith(isNew: false)).toList(),
      );
    }
    newNotificationsCount.value = 0;
  }
}
