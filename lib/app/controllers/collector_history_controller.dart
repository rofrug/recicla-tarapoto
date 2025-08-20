import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:recicla_tarapoto_1/app/data/models/waste_collection.dart';
import 'package:recicla_tarapoto_1/app/data/provider/wasteCollectionsProvider.dart';

class CollectorHistoryVm {
  final String id;
  final String userName; // resuelto desde userReference
  final double kg;
  final DateTime? date;
  final String address;

  const CollectorHistoryVm({
    required this.id,
    required this.userName,
    required this.kg,
    required this.date,
    required this.address,
  });
}

class CollectorHistoryController extends GetxController {
  final WasteCollectionsProvider _provider = WasteCollectionsProvider();

  final RxBool isLoading = true.obs;
  final RxList<CollectorHistoryVm> items = <CollectorHistoryVm>[].obs;

  StreamSubscription<List<WasteCollectionModel>>? _sub;
  final Map<String, String> _userCache = {}; // uid -> name cache

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void _listen() {
    isLoading.value = true;
    _sub = _provider.getCompletedWasteCollections(limit: 100).listen(
      (list) async {
        final result = <CollectorHistoryVm>[];

        for (final wc in list) {
          final userName = await _resolveUserName(wc.userReference);
          result.add(
            CollectorHistoryVm(
              id: wc.id,
              userName: userName,
              kg: wc.totalKg,
              date: wc.date,
              address: wc.address,
            ),
          );
        }

        items.assignAll(result);
        isLoading.value = false;
      },
      onError: (e) {
        // ignore: avoid_print
        print('❗ CollectorHistoryController stream error: $e');
        items.clear();
        isLoading.value = false;
      },
    );
  }

  Future<String> _resolveUserName(DocumentReference? ref) async {
    try {
      if (ref == null) return 'Usuario';
      final uid = ref.id;
      if (_userCache.containsKey(uid)) return _userCache[uid]!;
      final doc = await ref.get();
      if (!doc.exists) return 'Usuario';
      final data = doc.data() as Map<String, dynamic>;
      // Según tu UserModel: name + lastname
      final name = (data['name'] ?? '').toString();
      final lastname = (data['lastname'] ?? '').toString();
      final fullname = [name, lastname].where((s) => s.isNotEmpty).join(' ');
      final display =
          fullname.isNotEmpty ? fullname : (name.isNotEmpty ? name : 'Usuario');
      _userCache[uid] = display;
      return display;
    } catch (_) {
      return 'Usuario';
    }
  }

  String formatDate(DateTime? d) {
    if (d == null) return '—';
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
