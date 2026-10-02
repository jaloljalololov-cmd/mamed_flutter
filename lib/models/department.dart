class Department {
  final String id;
  final String name;

  Department({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(id: map['id'] ?? '', name: map['name'] ?? 'Отделение');
  }
}
