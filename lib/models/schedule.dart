class Schedule {
  final String id;
  final String name;
  final String period;

  Schedule({required this.id, required this.name, this.period = 'Ежедневно'});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'period': period};

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Ежедневно',
      period: map['period'] ?? 'Ежедневно',
    );
  }
}
