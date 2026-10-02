class Patient {
  final String id;
  final String name;
  final String medCardId;
  final String medCard;
  final int age;
  final String gender;
  final String departmentId;
  final String department;
  final String doctorId;
  final String doctor;
  final String diet;
  final String transportability;
  final String status;
  final String condition;
  final String commentsJson;

  Patient({
    required this.id,
    required this.name,
    this.medCardId = '',
    required this.medCard,
    required this.age,
    this.gender = 'Мужской',
    this.departmentId = '',
    this.department = 'Терапия',
    this.doctorId = '',
    this.doctor = 'Врач',
    this.diet = 'Стол №1',
    this.transportability = 'Ходячий',
    this.status = 'На лечении',
    this.condition = 'Удовлетворительное',
    this.commentsJson = '[]',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'medCardId': medCardId,
      'medCard': medCard,
      'age': age,
      'gender': gender,
      'departmentId': departmentId,
      'department': department,
      'doctorId': doctorId,
      'doctor': doctor,
      'diet': diet,
      'transportability': transportability,
      'status': status,
      'condition': condition,
      'commentsJson': commentsJson,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      medCardId: map['medCardId'] ?? '',
      medCard: map['medCard'] ?? '—',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'Мужской',
      departmentId: map['departmentId'] ?? '',
      department: map['department'] ?? 'Отделение',
      doctorId: map['doctorId'] ?? '',
      doctor: map['doctor'] ?? 'Врач',
      diet: map['diet'] ?? 'Стол №1',
      transportability: map['transportability'] ?? 'Ходячий',
      status: map['status'] ?? 'На лечении',
      condition: map['condition'] ?? 'Удовлетворительное',
      commentsJson: map['commentsJson'] ?? '[]',
    );
  }
}
