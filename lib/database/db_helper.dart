import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/medication.dart';
import '../models/department.dart';
import '../models/schedule.dart';
import '../models/prescription.dart';
import '../models/cancellation.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _db;

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'mamed_flutter.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            name TEXT,
            medCardId TEXT,
            medCard TEXT,
            age INTEGER,
            gender TEXT,
            departmentId TEXT,
            department TEXT,
            doctorId TEXT,
            doctor TEXT,
            diet TEXT,
            transportability TEXT,
            status TEXT,
            condition TEXT,
            commentsJson TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE medications (
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            stock REAL,
            unitId TEXT,
            unitName TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE departments (
            id TEXT PRIMARY KEY,
            name TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE schedules (
            id TEXT PRIMARY KEY,
            name TEXT,
            period TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE prescriptions (
            id TEXT PRIMARY KEY,
            patientId TEXT,
            patientName TEXT,
            medCard TEXT,
            medCardGuid TEXT,
            date TEXT,
            isSynced INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE prescription_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            prescriptionId TEXT,
            medicationId TEXT,
            medicationName TEXT,
            quantity REAL,
            scheduleId TEXT,
            scheduleName TEXT,
            startDate TEXT,
            endDate TEXT,
            isCanceled INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE cancellations (
            id TEXT PRIMARY KEY,
            originalPrescriptionId TEXT,
            patientId TEXT,
            patientName TEXT,
            medCard TEXT,
            medCardGuid TEXT,
            date TEXT,
            comment TEXT,
            isSynced INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE cancellation_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cancellationId TEXT,
            medicationId TEXT,
            medicationName TEXT,
            quantity REAL,
            scheduleId TEXT,
            scheduleName TEXT,
            startDate TEXT,
            endDate TEXT
          )
        ''');
      },
    );
  }

  // Patients
  Future<void> savePatients(List<Patient> list) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('patients');
      for (var p in list) {
        await txn.insert('patients', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Patient>> getPatients() async {
    final database = await db;
    final maps = await database.query('patients');
    return maps.map((m) => Patient.fromMap(m)).toList();
  }

  // Medications
  Future<void> saveMedications(List<Medication> list) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('medications');
      for (var m in list) {
        await txn.insert('medications', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Medication>> getMedications() async {
    final database = await db;
    final maps = await database.query('medications');
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  // Departments
  Future<void> saveDepartments(List<Department> list) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('departments');
      for (var d in list) {
        await txn.insert('departments', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Department>> getDepartments() async {
    final database = await db;
    final maps = await database.query('departments');
    return maps.map((m) => Department.fromMap(m)).toList();
  }

  // Schedules
  Future<void> saveSchedules(List<Schedule> list) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('schedules');
      for (var s in list) {
        await txn.insert('schedules', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Schedule>> getSchedules() async {
    final database = await db;
    final maps = await database.query('schedules');
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  // Prescriptions
  Future<void> insertPrescription(Prescription p, List<PrescriptionItem> items) async {
    final database = await db;
    await database.insert('prescriptions', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (var item in items) {
      await database.insert('prescription_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Prescription>> getPrescriptionsForPatient(String patientId) async {
    final database = await db;
    final maps = await database.query('prescriptions', where: 'patientId = ?', whereArgs: [patientId], orderBy: 'date DESC');
    return maps.map((m) => Prescription.fromMap(m)).toList();
  }

  Future<List<Prescription>> getAllPrescriptions() async {
    final database = await db;
    final maps = await database.query('prescriptions', orderBy: 'date DESC');
    return maps.map((m) => Prescription.fromMap(m)).toList();
  }

  Future<List<PrescriptionItem>> getPrescriptionItems(String prescriptionId) async {
    final database = await db;
    final maps = await database.query('prescription_items', where: 'prescriptionId = ?', whereArgs: [prescriptionId]);
    return maps.map((m) => PrescriptionItem.fromMap(m)).toList();
  }

  Future<List<PrescriptionItem>> getAllPrescriptionItemsForPatient(String patientId) async {
    final database = await db;
    final maps = await database.rawQuery('''
      SELECT pi.* FROM prescription_items pi 
      INNER JOIN prescriptions p ON pi.prescriptionId = p.id 
      WHERE p.patientId = ? 
      ORDER BY pi.id DESC
    ''', [patientId]);
    return maps.map((m) => PrescriptionItem.fromMap(m)).toList();
  }

  Future<void> markPrescriptionItemsCanceled(String prescriptionId, List<String> medicationIds) async {
    final database = await db;
    for (var medId in medicationIds) {
      await database.rawUpdate('''
        UPDATE prescription_items SET isCanceled = 1 WHERE prescriptionId = ? AND medicationId = ?
      ''', [prescriptionId, medId]);
    }
  }

  // Cancellations
  Future<void> insertCancellation(Cancellation c, List<CancellationItem> items) async {
    final database = await db;
    await database.insert('cancellations', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (var item in items) {
      await database.insert('cancellation_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Cancellation>> getCancellationsForPatient(String patientId) async {
    final database = await db;
    final maps = await database.query('cancellations', where: 'patientId = ?', whereArgs: [patientId], orderBy: 'date DESC');
    return maps.map((m) => Cancellation.fromMap(m)).toList();
  }

  Future<List<Cancellation>> getAllCancellations() async {
    final database = await db;
    final maps = await database.query('cancellations', orderBy: 'date DESC');
    return maps.map((m) => Cancellation.fromMap(m)).toList();
  }

  Future<List<CancellationItem>> getCancellationItems(String cancellationId) async {
    final database = await db;
    final maps = await database.query('cancellation_items', where: 'cancellationId = ?', whereArgs: [cancellationId]);
    return maps.map((m) => CancellationItem.fromMap(m)).toList();
  }
}
