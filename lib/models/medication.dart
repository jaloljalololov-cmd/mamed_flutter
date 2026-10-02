class Medication {
  final String id;
  final String name;
  final String description;
  final double stock;
  final String unitId;
  final String unitName;

  Medication({
    required this.id,
    required this.name,
    this.description = '',
    this.stock = 0.0,
    this.unitId = '',
    this.unitName = 'шт',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'stock': stock,
      'unitId': unitId,
      'unitName': unitName,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Медикамент',
      description: map['description'] ?? '',
      stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
      unitId: map['unitId'] ?? '',
      unitName: map['unitName'] ?? 'шт',
    );
  }
}
