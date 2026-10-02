class Cancellation {
  final String id;
  final String originalPrescriptionId;
  final String patientId;
  final String patientName;
  final String medCard;
  final String medCardGuid;
  final String date;
  final String comment;
  final bool isSynced;

  Cancellation({
    required this.id,
    required this.originalPrescriptionId,
    required this.patientId,
    required this.patientName,
    required this.medCard,
    this.medCardGuid = '',
    required this.date,
    this.comment = '',
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalPrescriptionId': originalPrescriptionId,
      'patientId': patientId,
      'patientName': patientName,
      'medCard': medCard,
      'medCardGuid': medCardGuid,
      'date': date,
      'comment': comment,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Cancellation.fromMap(Map<String, dynamic> map) {
    return Cancellation(
      id: map['id'] ?? '',
      originalPrescriptionId: map['originalPrescriptionId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      medCard: map['medCard'] ?? '',
      medCardGuid: map['medCardGuid'] ?? '',
      date: map['date'] ?? '',
      comment: map['comment'] ?? '',
      isSynced: (map['isSynced'] ?? 0) == 1,
    );
  }
}

class CancellationItem {
  final int? id;
  final String cancellationId;
  final String medicationId;
  final String medicationName;
  final double quantity;
  final String scheduleId;
  final String scheduleName;
  final String startDate;
  final String endDate;

  CancellationItem({
    this.id,
    required this.cancellationId,
    required this.medicationId,
    required this.medicationName,
    required this.quantity,
    required this.scheduleId,
    required this.scheduleName,
    this.startDate = '',
    this.endDate = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cancellationId': cancellationId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'quantity': quantity,
      'scheduleId': scheduleId,
      'scheduleName': scheduleName,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  factory CancellationItem.fromMap(Map<String, dynamic> map) {
    return CancellationItem(
      id: map['id'],
      cancellationId: map['cancellationId'] ?? '',
      medicationId: map['medicationId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      scheduleId: map['scheduleId'] ?? '',
      scheduleName: map['scheduleName'] ?? 'Ежедневно',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
    );
  }
}
