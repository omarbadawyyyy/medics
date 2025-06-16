import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class EgyptianPharmacyDatabaseHelper {
  static final EgyptianPharmacyDatabaseHelper _instance = EgyptianPharmacyDatabaseHelper._internal();
  static Database? _database;

  // Table and column names
  static const String tableMedicines = 'medicines';
  static const String tablePharmacies = 'pharmacies';
  static const String tableMedicinePharmacy = 'medicine_pharmacy';
  static const String columnMedicineId = 'id';
  static const String columnMedicineName = 'name';
  static const String columnCategory = 'category';
  static const String columnPrice = 'price';
  static const String columnMedicineImagePath = 'imagePath';
  static const String columnPharmacyId = 'id';
  static const String columnPharmacyName = 'name';
  static const String columnPharmacyLogoPath = 'logoPath';
  static const String columnPharmacyAddress = 'address';
  static const String columnMedicinePharmacyMedicineId = 'medicine_id';
  static const String columnMedicinePharmacyPharmacyId = 'pharmacy_id';

  // Singleton
  factory EgyptianPharmacyDatabaseHelper() => _instance;

  EgyptianPharmacyDatabaseHelper._internal();

  // Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'egyptian_pharmacy_database.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Medicines table
    await db.execute('''
      CREATE TABLE $tableMedicines (
        $columnMedicineId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnMedicineName TEXT NOT NULL UNIQUE,
        $columnCategory TEXT NOT NULL,
        $columnPrice REAL NOT NULL,
        $columnMedicineImagePath TEXT
      )
    ''');

    // Pharmacies table with address and phone
    await db.execute('''
      CREATE TABLE $tablePharmacies (
        $columnPharmacyId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnPharmacyName TEXT NOT NULL UNIQUE,
        $columnPharmacyLogoPath TEXT,
        $columnPharmacyAddress TEXT,
        phone TEXT
      )
    ''');

    // Junction table for medicine-pharmacy relationship
    await db.execute('''
      CREATE TABLE $tableMedicinePharmacy (
        $columnMedicinePharmacyMedicineId INTEGER,
        $columnMedicinePharmacyPharmacyId INTEGER,
        PRIMARY KEY ($columnMedicinePharmacyMedicineId, $columnMedicinePharmacyPharmacyId),
        FOREIGN KEY ($columnMedicinePharmacyMedicineId) REFERENCES $tableMedicines($columnMedicineId),
        FOREIGN KEY ($columnMedicinePharmacyPharmacyId) REFERENCES $tablePharmacies($columnPharmacyId)
      )
    ''');
  }

  // Upgrade database schema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE $tablePharmacies ADD COLUMN $columnPharmacyAddress TEXT
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE $tablePharmacies ADD COLUMN phone TEXT
      ''');
      await db.execute('''
        CREATE TABLE $tableMedicinePharmacy (
          $columnMedicinePharmacyMedicineId INTEGER,
          $columnMedicinePharmacyPharmacyId INTEGER,
          PRIMARY KEY ($columnMedicinePharmacyMedicineId, $columnMedicinePharmacyPharmacyId),
          FOREIGN KEY ($columnMedicinePharmacyMedicineId) REFERENCES $tableMedicines($columnMedicineId),
          FOREIGN KEY ($columnMedicinePharmacyPharmacyId) REFERENCES $tablePharmacies($columnPharmacyId)
        )
      ''');
    }
  }

  // Insert medicine
  Future<int> insertMedicine(Map<String, dynamic> medicine) async {
    Database db = await database;
    try {
      return await db.insert(
        tableMedicines,
        medicine,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting medicine: $e');
      return -1;
    }
  }

  // Insert pharmacy
  Future<int> insertPharmacy(Map<String, dynamic> pharmacy) async {
    Database db = await database;
    try {
      return await db.insert(
        tablePharmacies,
        pharmacy,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting pharmacy: $e');
      return -1;
    }
  }

  // Get all medicines
  Future<List<Map<String, dynamic>>> getAllMedicines() async {
    Database db = await database;
    return await db.query(tableMedicines);
  }

  // Get medicine by name
  Future<Map<String, dynamic>?> getMedicineByName(String name) async {
    Database db = await database;
    final result = await db.query(
      tableMedicines,
      where: '$columnMedicineName = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Search medicines
  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    Database db = await database;
    final result = await db.query(
      tableMedicines,
      where: '$columnMedicineName LIKE ?',
      whereArgs: ['%$query%'],
    );
    return result;
  }

  // Search medicines and include pharmacy information
  Future<List<Map<String, dynamic>>> searchMedicinesAndPharmacies(String query) async {
    Database db = await database;
    final results = await db.rawQuery('''
      SELECT 
        m.$columnMedicineId,
        m.$columnMedicineName,
        m.$columnCategory,
        m.$columnPrice,
        m.$columnMedicineImagePath,
        p.$columnPharmacyName as pharmacy_name,
        p.$columnPharmacyAddress as address,
        p.$columnPharmacyLogoPath as imagePath,
        p.phone
      FROM $tableMedicines m
      INNER JOIN $tableMedicinePharmacy mp ON m.$columnMedicineId = mp.$columnMedicinePharmacyMedicineId
      INNER JOIN $tablePharmacies p ON mp.$columnMedicinePharmacyPharmacyId = p.$columnPharmacyId
      WHERE m.$columnMedicineName LIKE ?
    ''', ['%$query%']);

    return results;
  }

  // Search pharmacies by medicine name
  Future<List<Map<String, dynamic>>> searchPharmaciesByMedicine(String medicineName) async {
    Database db = await database;
    final results = await db.rawQuery('''
      SELECT 
        p.$columnPharmacyName as pharmacy_name,
        p.$columnPharmacyAddress as address,
        p.phone,
        p.$columnPharmacyLogoPath as imagePath
      FROM $tablePharmacies p
      INNER JOIN $tableMedicinePharmacy mp ON p.$columnPharmacyId = mp.$columnMedicinePharmacyPharmacyId
      INNER JOIN $tableMedicines m ON mp.$columnMedicinePharmacyMedicineId = m.$columnMedicineId
      WHERE m.$columnMedicineName LIKE ?
    ''', ['%$medicineName%']);

    return results;
  }

  // Update medicine
  Future<int> updateMedicine(Map<String, dynamic> medicine) async {
    Database db = await database;
    int id = medicine[columnMedicineId];
    return await db.update(
      tableMedicines,
      medicine,
      where: '$columnMedicineId = ?',
      whereArgs: [id],
    );
  }

  // Delete medicine
  Future<int> deleteMedicine(int id) async {
    Database db = await database;
    return await db.delete(
      tableMedicines,
      where: '$columnMedicineId = ?',
      whereArgs: [id],
    );
  }

  // Get all pharmacies
  Future<List<Map<String, dynamic>>> getAllPharmacies() async {
    Database db = await database;
    return await db.query(tablePharmacies);
  }

  // Get pharmacy by name
  Future<Map<String, dynamic>?> getPharmacyByName(String name) async {
    Database db = await database;
    final result = await db.query(
      tablePharmacies,
      where: '$columnPharmacyName = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Add medicines and pharmacies
  Future<void> addMedicinesAndPharmacies() async {
    Database db = await database;

    // Check existing medicines
    final existingMedicines = await getAllMedicines();
    final existingMedicineNames = existingMedicines.map((m) => m['name'] as String).toSet();

    // List of 20 medicines with categories and placeholder prices (in EGP)
    final List<Map<String, dynamic>> medicines = [
      {'name': 'Gabimash', 'category': 'Anticonvulsant', 'price': 150.0, 'imagePath': 'assets/egyptian_medicines/Gabimash.png'},
      {'name': 'Controloc', 'category': 'Antacid', 'price': 80.0, 'imagePath': 'assets/egyptian_medicines/Controloc.png'},
      {'name': 'Panadol', 'category': 'Painkiller', 'price': 20.0, 'imagePath': 'assets/egyptian_medicines/Panadol.png'},
      {'name': 'Plavix', 'category': 'Blood Thinner', 'price': 200.0, 'imagePath': 'assets/egyptian_medicines/Plavix.png'},
      {'name': 'Nexium', 'category': 'Antacid', 'price': 90.0, 'imagePath': 'assets/egyptian_medicines/Nexium.png'},
      {'name': 'Ambezim', 'category': 'Anti-inflammatory', 'price': 60.0, 'imagePath': 'assets/egyptian_medicines/Ambezim.png'},
      {'name': 'Milga Advance', 'category': 'Vitamin Supplement', 'price': 70.0, 'imagePath': 'assets/egyptian_medicines/Milga Advance.png'},
      {'name': 'Omeprazole', 'category': 'Antacid', 'price': 50.0, 'imagePath': 'assets/egyptian_medicines/Omeprazole.png'},
      {'name': 'Ins Mixtard', 'category': 'Diabetes', 'price': 120.0, 'imagePath': 'assets/egyptian_medicines/Ins Mixtard.png'},
      {'name': 'Concor', 'category': 'Cardiovascular', 'price': 100.0, 'imagePath': 'assets/egyptian_medicines/Concor.png'},
      {'name': 'Congestal', 'category': 'Cold and Flu', 'price': 30.0, 'imagePath': 'assets/egyptian_medicines/Congestal.png'},
      {'name': 'Voltaren', 'category': 'Painkiller', 'price': 40.0, 'imagePath': 'assets/egyptian_medicines/Voltaren.png'},
      {'name': 'Antinal', 'category': 'Antidiarrheal', 'price': 25.0, 'imagePath': 'assets/egyptian_medicines/Antinal.png'},
      {'name': 'Telfast', 'category': 'Antihistamine', 'price': 50.0, 'imagePath': 'assets/egyptian_medicines/Telfast.png'},
      {'name': 'Centrum', 'category': 'Vitamin Supplement', 'price': 80.0, 'imagePath': 'assets/egyptian_medicines/Centrum.png'},
      {'name': 'Cystone', 'category': 'Urology', 'price': 60.0, 'imagePath': 'assets/egyptian_medicines/Cystone.png'},
      {'name': 'Flagyl', 'category': 'Antibiotic', 'price': 30.0, 'imagePath': 'assets/egyptian_medicines/Flagyl.png'},
      {'name': 'Lisinopril', 'category': 'Cardiovascular', 'price': 40.0, 'imagePath': 'assets/egyptian_medicines/Lisinopril.png'},
      {'name': 'Salbutamol', 'category': 'Asthma', 'price': 35.0, 'imagePath': 'assets/egyptian_medicines/Salbutamol.png'},
      {'name': 'Ketoprofen', 'category': 'Painkiller', 'price': 45.0, 'imagePath': 'assets/egyptian_medicines/Ketoprofen.png'},
    ];

    // Insert new medicines and get their IDs
    final medicineIds = <String, int>{};
    for (var medicine in medicines) {
      if (!existingMedicineNames.contains(medicine['name'])) {
        print('Inserting new medicine: ${medicine['name']}');
        int id = await insertMedicine(medicine);
        medicineIds[medicine['name']] = id;
      } else {
        final existing = existingMedicines.firstWhere((m) => m['name'] == medicine['name']);
        medicineIds[medicine['name']] = existing['id'];
      }
    }

    // Check existing pharmacies
    final existingPharmacies = await getAllPharmacies();
    final existingPharmacyNames = existingPharmacies.map((p) => p['name'] as String).toSet();

    // List of 4 pharmacies with logo paths, addresses, and phone numbers
    final List<Map<String, dynamic>> pharmacies = [
      {
        'name': 'Helmy',
        'logoPath': 'assets/pharmacy/helmy.png',
        'address': '123 El-Haram St, Giza, Egypt',
        'phone': '+201234567890',
      },
      {
        'name': 'Elokaby',
        'logoPath': 'assets/pharmacy/elokaby.png',
        'address': '45 Nasr City Rd, Cairo, Egypt',
        'phone': '+201987654321',
      },
      {
        'name': 'Elezaby',
        'logoPath': 'assets/pharmacy/elezaby.png',
        'address': '78 Maadi St, Cairo, Egypt',
        'phone': '+201112233445',
      },
      {
        'name': 'Elbendary',
        'logoPath': 'assets/pharmacy/elbendary.png',
        'address': '56 Dokki St, Giza, Egypt',
        'phone': '+201556677889',
      },
    ];

    // Insert new pharmacies and get their IDs
    final pharmacyIds = <String, int>{};
    for (var pharmacy in pharmacies) {
      if (!existingPharmacyNames.contains(pharmacy['name'])) {
        print('Inserting new pharmacy: ${pharmacy['name']}');
        int id = await insertPharmacy(pharmacy);
        pharmacyIds[pharmacy['name']] = id;
      } else {
        final existing = existingPharmacies.firstWhere((p) => p['name'] == pharmacy['name']);
        pharmacyIds[pharmacy['name']] = existing['id'];
      }
    }

    // Populate medicine_pharmacy table
    final List<Map<String, dynamic>> medicinePharmacyLinks = [];
    for (var medicine in medicines) {
      final medicineId = medicineIds[medicine['name']]!;
      medicinePharmacyLinks.add({
        'medicine_id': medicineId,
        'pharmacy_id': pharmacyIds['Helmy'],
      });
      medicinePharmacyLinks.add({
        'medicine_id': medicineId,
        'pharmacy_id': pharmacyIds['Elokaby'],
      });
    }

    // Insert medicine-pharmacy relationships
    for (var link in medicinePharmacyLinks) {
      await db.insert(
        tableMedicinePharmacy,
        link,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    print('Finished updating database. Total medicines: ${(await getAllMedicines()).length}, Total pharmacies: ${(await getAllPharmacies()).length}');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}