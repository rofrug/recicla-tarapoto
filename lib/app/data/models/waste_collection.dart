// lib/app/data/models/waste_collection.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'residue_item.dart';

class WasteCollectionModel {
  final String id;
  final String address;
  final bool isRecycled;
  final double totalBags;

  /// totalCoins incluye el bono por bolsas (+30 por cada tipo marcado)
  final double totalCoins;
  final double totalKg;

  /// Cantidad de tipos correctamente segregados (bolsa individual marcada)
  final int correctlySegregated;

  final List<ResidueItem> residues;
  final DocumentReference? userReference;

  /// Legacy (compat) – antes se usaba 'date' para la creación
  final DateTime? date;

  /// NUEVO: cuándo el generador creó la solicitud (si falta, usar 'date')
  final DateTime? requestedAt;

  /// NUEVO: cuándo el recolector marcó como reciclado
  final DateTime? recycledAt;

  WasteCollectionModel({
    required this.id,
    required this.address,
    required this.isRecycled,
    required this.totalBags,
    required this.totalCoins,
    required this.totalKg,
    required this.correctlySegregated,
    required this.residues,
    required this.userReference,
    required this.date,
    this.requestedAt,
    this.recycledAt,
  });

  factory WasteCollectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime? _ts(dynamic v) =>
        v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

    final legacyDate = _ts(data['date']);
    final reqAt = _ts(data['requestedAt']) ?? legacyDate; // compat

    return WasteCollectionModel(
      id: doc.id,
      address: (data['address'] ?? '').toString(),
      isRecycled: (data['isRecycled'] ?? false) == true,
      totalBags: _toDouble(data['totalBags']),
      totalCoins: _toDouble(data['totalCoins']),
      totalKg: _toDouble(data['totalKg']),
      correctlySegregated: (data['correctlySegregated'] ?? 0) is int
          ? data['correctlySegregated'] as int
          : int.tryParse('${data['correctlySegregated']}') ?? 0,
      userReference: data['userReference'] is DocumentReference
          ? data['userReference'] as DocumentReference
          : null,
      date: legacyDate,
      requestedAt: reqAt,
      recycledAt: _ts(data['recycledAt']),
      residues: (data['residues'] as List<dynamic>? ?? [])
          .map((item) => ResidueItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

    final map = <String, dynamic>{
      'address': address,
      'isRecycled': isRecycled,
      'totalBags': totalBags,
      'totalCoins': totalCoins,
      'totalKg': totalKg,
      'correctlySegregated': correctlySegregated,
      'userReference': userReference,
      'requestedAt': _ts(requestedAt),
      'recycledAt': _ts(recycledAt),
      // Compat: mantener 'date' como la fecha de solicitud si existe
      'date': _ts(requestedAt ?? date),
      'residues': residues.map((r) => r.toMap()).toList(),
    };

    // Opcional: elimina claves con null si prefieres no escribir nulls
    map.removeWhere((_, v) => v == null);
    return map;
  }

  /// copyWith amplio para poder setear fechas y totales desde la UI/Controller
  WasteCollectionModel copyWith({
    String? address,
    bool? isRecycled,
    double? totalBags,
    double? totalCoins,
    double? totalKg,
    int? correctlySegregated,
    List<ResidueItem>? residues,
    DocumentReference? userReference,
    DateTime? date,
    DateTime? requestedAt,
    DateTime? recycledAt,
  }) {
    return WasteCollectionModel(
      id: id,
      address: address ?? this.address,
      isRecycled: isRecycled ?? this.isRecycled,
      totalBags: totalBags ?? this.totalBags,
      totalCoins: totalCoins ?? this.totalCoins,
      totalKg: totalKg ?? this.totalKg,
      correctlySegregated: correctlySegregated ?? this.correctlySegregated,
      residues: residues ?? this.residues,
      userReference: userReference ?? this.userReference,
      date: date ?? this.date,
      requestedAt: requestedAt ?? this.requestedAt,
      recycledAt: recycledAt ?? this.recycledAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
