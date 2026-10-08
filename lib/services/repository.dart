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
      final medsData = await _api.getRequest('getMedications/');
      final schedsData = await _api.getRequest('getSchedules/');

      if (patientsData is List) {
        final patients = patientsData.map((p) {
          final comments = p['Комментарии'] ?? [];
          final rawPatientId = p['Пациент'] ?? p['id'] ?? p['GUID'] ?? _uuid.v4();
          final rawPatientName = p['ПациентНаименование'] ?? p['ФИО'] ?? p['name'] ?? 'Без имени';
          final rawMedCardId = p['МедицинскаяКарта'] ?? p['id'] ?? p['GUID'] ?? '';
          final rawMedCardNum = p['МедицинскаяКартаНаименование'] ?? p['НомерМедицинскойКарты'] ?? p['НомерКарты'] ?? p['НомерИсторииБолезни'] ?? p['medCard'] ?? '—';
          final rawDeptId = p['Подразделение'] ?? '';
          final rawDeptName = p['ПодразделениеНаименование'] ?? p['Отделение'] ?? 'Отделение';
          final rawDoctorId = p['ЛечащийВрач'] ?? '';
          final rawDoctorName = p['ЛечащийВрачНаименование'] ?? p['Врач'] ?? 'Лечащий врач';

          return Patient(
            id: rawPatientId.toString().trim(),
            name: rawPatientName.toString().trim(),
            medCardId: rawMedCardId.toString().trim(),
            medCard: rawMedCardNum.toString().trim(),
            age: p['Возраст'] is num ? (p['Возраст'] as num).toInt() : int.tryParse(p['Возраст']?.toString() ?? '0') ?? 0,
            gender: (p['Пол'] ?? 'Мужской').toString().trim(),
            departmentId: rawDeptId.toString().trim(),
            department: rawDeptName.toString().trim(),
            doctorId: rawDoctorId.toString().trim(),
            doctor: rawDoctorName.toString().trim(),
            diet: (p['Диета'] ?? 'Стол №1').toString().trim(),
            transportability: (p['Транспортабельность'] ?? 'Ходячий').toString().trim(),
            status: (p['Статус'] ?? 'На лечении').toString().trim(),
            condition: (p['Состояние'] ?? 'Удовлетворительное').toString().trim(),
            commentsJson: jsonEncode(comments),
          );
        }).toList();

        await _db.savePatients(patients);

        final Map<String, String> deptMap = {};
        for (var p in patients) {
          if (p.departmentId.isNotEmpty && p.department.isNotEmpty) {
            deptMap[p.departmentId] = p.department;
          }
        }
        final departments = deptMap.entries
            .map((e) => Department(id: e.key, name: e.value))
            .toList();
        await _db.saveDepartments(departments);
      }

      try {
        final doctorData = await _api.getRequest('getDoctor/');
        if (doctorData is Map) {
          final deptsList = doctorData['МассивОтделений'];
          if (deptsList is List) {
            final depts = deptsList.map((d) {
              return Department(
                id: (d['Отделение'] ?? _uuid.v4()).toString().trim(),
                name: (d['НаименованиеОтделения'] ?? 'Отделение').toString().trim(),
              );
            }).where((d) => d.id.isNotEmpty && d.name.isNotEmpty).toList();

            if (depts.isNotEmpty) {
              await _db.saveDepartments(depts);
            }
          }
        }
      } catch (_) {}

      if (medsData is List) {
        final meds = medsData.map((m) {
          final rawId = m['Номенклатура'] ?? m['id'] ?? m['GUID'] ?? m['Код'] ?? _uuid.v4();
          final rawName = m['НоменклатураНаименование'] ?? m['МедикаментНаименование'] ?? m['ТоварНаименование'] ?? m['ПрепаратНаименование'] ?? m['НаименованиеНоменклатуры'] ?? m['name'] ?? m['Name'] ?? m['Наименование'] ?? m['Медикамент'] ?? m['Название'] ?? m['Представление'] ?? m['Препарат'] ?? m['Товар'] ?? 'Медикамент';
          final rawStock = m['Доступно'] ?? m['ВНаличии'] ?? m['Остаток'] ?? m['КоличествоОстаток'] ?? m['Количество'] ?? m['stock'] ?? 0.0;
          final rawUnitId = m['unitId'] ?? m['ЕдиницаИзмерения'] ?? m['ЕдИзм'] ?? '';
          final rawUnitName = m['ЕдиницаИзмеренияНаименование'] ?? m['ЕдИзмНаименование'] ?? m['unitName'] ?? 'шт';

          return Medication(
            id: rawId.toString().trim(),
            name: rawName.toString().trim(),
            stock: (rawStock is num) ? rawStock.toDouble() : double.tryParse(rawStock?.toString() ?? '0') ?? 0.0,
            unitId: rawUnitId.toString().trim(),
            unitName: rawUnitName.toString().trim(),
          );
        }).toList();

        await _db.saveMedications(meds);
      }

      if (schedsData is List) {
        final scheds = schedsData.map((s) {
          final rawId = s['id'] ?? s['GUID'] ?? s['Код'] ?? _uuid.v4();
          final rawName = s['Наименование'] ?? s['name'] ?? s['Name'] ?? s['Период'] ?? s['Расписание'] ?? s['Режим'] ?? 'Ежедневно';
          final rawPeriod = s['Интервал'] ?? s['period'] ?? 'Ежедневно';

          return Schedule(
            id: rawId.toString().trim(),
            name: rawName.toString().trim(),
            period: rawPeriod.toString().trim(),
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
        quantity: (i['quantity'] as num).toDouble(),
        scheduleId: i['scheduleId'],
        scheduleName: i['scheduleName'],
        startDate: i['startDate'] ?? '',
        endDate: i['endDate'] ?? '',
      );
    }).toList();

    // 1. Always save prescription locally in DB first (1-to-1 with Android)
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
        'unitId': i['unitId'] ?? '',
        'unitName': i['unitName'] ?? 'шт',
        'scheduleId': i['scheduleId'],
        'startDate': i['startDate'] ?? '',
        'endDate': i['endDate'] ?? '',
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
      final cleanErr = e.toString().replaceAll('Exception: ', '');
      return 'Сохранено локально (1С: $cleanErr)';
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
