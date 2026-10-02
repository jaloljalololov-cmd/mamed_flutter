import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/patient.dart';
import '../models/medication.dart';
import '../models/department.dart';
import '../models/schedule.dart';
import '../models/prescription.dart';
import '../models/cancellation.dart';
import 'api_service.dart';

class Repository {
  final DBHelper _db = DBHelper();
  final ApiService _api = ApiService();
  final Uuid _uuid = const Uuid();

  Future<List<Patient>> getPatients() => _db.getPatients();
  Future<List<Medication>> getMedications() => _db.getMedications();
  Future<List<Department>> getDepartments() => _db.getDepartments();
  Future<List<Schedule>> getSchedules() => _db.getSchedules();

  Future<List<Prescription>> getPrescriptionsForPatient(String patientId) => _db.getPrescriptionsForPatient(patientId);
  Future<List<Cancellation>> getCancellationsForPatient(String patientId) => _db.getCancellationsForPatient(patientId);
  Future<List<PrescriptionItem>> getAllPrescriptionItemsForPatient(String patientId) => _db.getAllPrescriptionItemsForPatient(patientId);

  Future<List<Prescription>> getAllPrescriptions() => _db.getAllPrescriptions();
  Future<List<Cancellation>> getAllCancellations() => _db.getAllCancellations();

  Future<List<PrescriptionItem>> getPrescriptionItems(String id) => _db.getPrescriptionItems(id);
  Future<List<CancellationItem>> getCancellationItems(String id) => _db.getCancellationItems(id);

  Future<String> syncDirectories() async {
    try {
      final patientsData = await _api.getRequest('getPatients/');
      await _api.getRequest('getDoctor/');
      final medsData = await _api.getRequest('getMedications/');
      final schedsData = await _api.getRequest('getSchedules/');

      if (patientsData is List) {
        final patients = patientsData.map((p) {
          final comments = p['Комментарии'] ?? [];
          return Patient(
            id: p['Пациент'] ?? p['id'] ?? _uuid.v4(),
            name: p['ПациентНаименование'] ?? p['ФИО'] ?? 'Без имени',
            medCardId: p['МедицинскаяКарта'] ?? p['id'] ?? '',
            medCard: p['МедицинскаяКартаНаименование'] ?? p['НомерМедицинскойКарты'] ?? '—',
            age: p['Возраст'] ?? 0,
            gender: p['Пол'] ?? 'Мужской',
            departmentId: p['Подразделение'] ?? '',
            department: p['ПодразделениеНаименование'] ?? 'Отделение',
            doctorId: p['ЛечащийВрач'] ?? '',
            doctor: p['ЛечащийВрачНаименование'] ?? 'Лечащий врач',
            diet: p['Диета'] ?? 'Стол №1',
            transportability: p['Транспортабельность'] ?? 'Ходячий',
            status: p['Статус'] ?? 'На лечении',
            condition: p['Состояние'] ?? 'Удовлетворительное',
            commentsJson: jsonEncode(comments),
          );
        }).toList();

        await _db.savePatients(patients);
      }

      if (medsData is List) {
        final meds = medsData.map((m) {
          return Medication(
            id: m['Номенклатура'] ?? m['id'] ?? _uuid.v4(),
            name: m['НоменклатураНаименование'] ?? m['Наименование'] ?? 'Медикамент',
            stock: (m['Доступно'] ?? m['ВНаличии'] ?? m['stock'] as num?)?.toDouble() ?? 0.0,
            unitId: m['ЕдиницаИзмерения'] ?? '',
            unitName: m['ЕдиницаИзмеренияНаименование'] ?? 'шт',
          );
        }).toList();

        await _db.saveMedications(meds);
      }

      if (schedsData is List) {
        final scheds = schedsData.map((s) {
          return Schedule(
            id: s['id'] ?? _uuid.v4(),
            name: s['Наименование'] ?? s['name'] ?? 'Ежедневно',
            period: s['Интервал'] ?? 'Ежедневно',
          );
        }).toList();

        await _db.saveSchedules(scheds);
      }

      return 'Справочники успешно загружены';
    } catch (e) {
      return 'Ошибка синхронизации: $e';
    }
  }

  Future<String> createPrescription({
    required String patientId,
    required String patientName,
    required String medCard,
    required String medCardGuid,
    required String comment,
    required List<Map<String, dynamic>> items,
  }) async {
    final docId = _uuid.v4();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    final targetMedCardGuid = medCardGuid.isNotEmpty ? medCardGuid : medCard;

    final p = Prescription(
      id: docId,
      patientId: patientId,
      patientName: patientName,
      medCard: medCard,
      medCardGuid: targetMedCardGuid,
      date: dateStr,
      isSynced: false,
    );

    final itemEntities = items.map((i) {
      return PrescriptionItem(
        prescriptionId: docId,
        medicationId: i['medicationId'],
        medicationName: i['medicationName'],
        quantity: i['quantity'],
        scheduleId: i['scheduleId'],
        scheduleName: i['scheduleName'],
        startDate: i['startDate'] ?? '',
        endDate: i['endDate'] ?? '',
      );
    }).toList();

    await _db.insertPrescription(p, itemEntities);

    final jsonPayload = {
      'patientId': patientId,
      'medCardId': targetMedCardGuid,
      'documentId': docId,
      'originalPrescriptionId': docId,
      'prescriptionId': docId,
      'comment': comment,
      'items': items.map((i) => {
        'medicationId': i['medicationId'],
        'medicationName': i['medicationName'],
        'quantity': i['quantity'],
        'unitId': i['unitId'],
        'unitName': i['unitName'],
        'scheduleId': i['scheduleId'],
        'startDate': i['startDate'],
        'endDate': i['endDate'],
      }).toList(),
    };

    try {
      final success = await _api.postPrescriptionOrCancellation('postPrescription/', jsonPayload);
      if (success) {
        await _db.insertPrescription(
          Prescription(
            id: docId,
            patientId: patientId,
            patientName: patientName,
            medCard: medCard,
            medCardGuid: targetMedCardGuid,
            date: dateStr,
            isSynced: true,
          ),
          itemEntities,
        );
        return 'Назначение выписано и отправлено в 1С';
      }
    } catch (e) {
      return 'Сохранено локально ($e)';
    }

    return 'Сохранено локально';
  }

  Future<String> createCancellation({
    required String originalPrescriptionId,
    required String patientId,
    required String patientName,
    required String medCard,
    required String medCardGuid,
    required String comment,
    required List<Map<String, dynamic>> items,
  }) async {
    final cancellationId = _uuid.v4();
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    final targetMedCardGuid = medCardGuid.isNotEmpty ? medCardGuid : medCard;

    final c = Cancellation(
      id: cancellationId,
      originalPrescriptionId: originalPrescriptionId,
      patientId: patientId,
      patientName: patientName,
      medCard: medCard,
      medCardGuid: targetMedCardGuid,
      date: dateStr,
      comment: comment,
      isSynced: false,
    );

    final itemEntities = items.map((i) {
      return CancellationItem(
        cancellationId: cancellationId,
        medicationId: i['medicationId'],
        medicationName: i['medicationName'],
        quantity: i['quantity'],
        scheduleId: i['scheduleId'],
        scheduleName: i['scheduleName'],
        startDate: i['startDate'] ?? '',
        endDate: i['endDate'] ?? '',
      );
    }).toList();

    await _db.insertCancellation(c, itemEntities);

    final jsonPayload = {
      'patientId': patientId,
      'medCardId': targetMedCardGuid,
      'documentId': cancellationId,
      'cancellationId': cancellationId,
      'originalPrescriptionId': originalPrescriptionId,
      'prescriptionId': originalPrescriptionId,
      'comment': comment,
      'items': items.map((i) => {
        'medicationId': i['medicationId'],
        'medicationName': i['medicationName'],
        'quantity': i['quantity'],
        'unitId': i['unitId'],
        'unitName': i['unitName'],
        'scheduleId': i['scheduleId'],
        'startDate': i['startDate'],
        'endDate': i['endDate'],
      }).toList(),
    };

    try {
      final success = await _api.postPrescriptionOrCancellation('postCancellation/', jsonPayload);
      if (success) {
        await _db.insertCancellation(
          Cancellation(
            id: cancellationId,
            originalPrescriptionId: originalPrescriptionId,
            patientId: patientId,
            patientName: patientName,
            medCard: medCard,
            medCardGuid: targetMedCardGuid,
            date: dateStr,
            comment: comment,
            isSynced: true,
          ),
          itemEntities,
        );

        final medIds = items.map((i) => i['medicationId'] as String).toList();
        await _db.markPrescriptionItemsCanceled(originalPrescriptionId, medIds);

        return 'Отмена документа создана и отправлена в 1С';
      }
    } catch (e) {
      return 'Отмена сохранена локально ($e)';
    }

    return 'Отмена сохранена локально';
  }
}
