class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String medCard;
  final String medCardGuid;
  final String date;
  final bool isSynced;

  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.medCard,
    this.medCardGuid = '',
    required this.date,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'medCard': medCard,
      'medCardGuid': medCardGuid,
      'date': date,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      medCard: map['medCard'] ?? '',
      medCardGuid: map['medCardGuid'] ?? '',
      date: map['date'] ?? '',
      isSynced: (map['isSynced'] ?? 0) == 1,
    );
  }
}

class PrescriptionItem {
  final int? id;
  final String prescriptionId;
  final String medicationId;
  final String medicationName;
  final double quantity;
  final String scheduleId;
  final String scheduleName;
  final String startDate;
  final String endDate;
  final bool isCanceled;

  PrescriptionItem({
    this.id,
    required this.prescriptionId,
    required this.medicationId,
    required this.medicationName,
    required this.quantity,
    required this.scheduleId,
    required this.scheduleName,
    this.startDate = '',
    this.endDate = '',
    this.isCanceled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'prescriptionId': prescriptionId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'quantity': quantity,
      'scheduleId': scheduleId,
      'scheduleName': scheduleName,
      'startDate': startDate,
      'endDate': endDate,
      'isCanceled': isCanceled ? 1 : 0,
    };
  }

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      id: map['id'],
      prescriptionId: map['prescriptionId'] ?? '',
      medicationId: map['medicationId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      scheduleId: map['scheduleId'] ?? '',
      scheduleName: map['scheduleName'] ?? 'Ежедневно',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      isCanceled: (map['isCanceled'] ?? 0) == 1,
    );
  }
}
