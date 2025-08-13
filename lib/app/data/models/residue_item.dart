// lib/app/data/models/residue_item.dart
class ResidueItem {
  /// Nombre del tipo (e.g., 'Plástico', 'Papel y Cartón', 'Metales')
  final String type;

  /// Kilogramos aproximados (entero recibido como double)
  final double approxKg;

  /// Monedas totales por este tipo (como String) = (kg * rateTipo) + (bolsa ? 30 : 0)
  final String coinsPerType;

  /// ¿Marcó bolsa individual?
  final bool individualBag;

  /// Subítems seleccionados (p.ej., 'Botellas', 'Cartón')
  final List<String> selectedItems;

  ResidueItem({
    required this.type,
    required this.approxKg,
    required this.coinsPerType,
    required this.individualBag,
    required this.selectedItems,
  });

  factory ResidueItem.fromMap(Map<String, dynamic> data) {
    return ResidueItem(
      type: data['type'] ?? '',
      approxKg: _toDouble(data['approxKg']),
      coinsPerType: data['coinsPerType']?.toString() ?? '0',
      individualBag: data['individualBag'] ?? false,
      // Asegurar que siempre sea List<String>
      selectedItems: (data['selectedItems'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'approxKg': approxKg,
      'coinsPerType': coinsPerType, // total por tipo (base + bono)
      'individualBag': individualBag,
      'selectedItems': selectedItems,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
