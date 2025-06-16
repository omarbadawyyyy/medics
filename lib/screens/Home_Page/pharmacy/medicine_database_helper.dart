import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MedicineDatabaseHelper {
  static final MedicineDatabaseHelper _instance = MedicineDatabaseHelper._internal();
  static Database? _database;

  // تعريف أسماء الجدول والأعمدة
  static const String tableNameMedicines = 'medicines';
  static const String columnMedicineId = 'id';
  static const String columnMedicineName = 'name';
  static const String columnCategory = 'category';
  static const String columnPrice = 'price';
  static const String columnImagePath = 'imagePath';

  // Singleton
  factory MedicineDatabaseHelper() => _instance;

  MedicineDatabaseHelper._internal();

  // الحصول على قاعدة البيانات
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // تهيئة قاعدة البيانات
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'medicines_database.db');
    // ملاحظة: حذف قاعدة البيانات كل مرة قد يكون مفيدًا للاختبار، لكن يمكن تعطيله في الإنتاج
    // await deleteDatabase(path); // قم بتعليق هذا السطر بعد الاختبار الأولي
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // إنشاء جدول الأدوية
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNameMedicines (
        $columnMedicineId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnMedicineName TEXT NOT NULL UNIQUE, -- إضافة UNIQUE لمنع التكرار
        $columnCategory TEXT NOT NULL,
        $columnPrice REAL NOT NULL,
        $columnImagePath TEXT
      )
    ''');
  }

  // إدراج دواء جديد
  Future<int> insertMedicine(Map<String, dynamic> medicine) async {
    Database db = await database;
    try {
      return await db.insert(
        tableNameMedicines,
        medicine,
        conflictAlgorithm: ConflictAlgorithm.replace, // استبدال إذا كان هناك تكرار
      );
    } catch (e) {
      print('Error inserting medicine: $e');
      return -1;
    }
  }

  // استرجاع جميع الأدوية
  Future<List<Map<String, dynamic>>> getAllMedicines() async {
    Database db = await database;
    return await db.query(tableNameMedicines);
  }

  // استرجاع دواء بواسطة الاسم
  Future<Map<String, dynamic>?> getMedicineByName(String name) async {
    Database db = await database;
    final result = await db.query(
      tableNameMedicines,
      where: '$columnMedicineName = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // البحث عن الأدوية بناءً على النص المدخل
  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    Database db = await database;
    final result = await db.query(
      tableNameMedicines,
      where: '$columnMedicineName LIKE ?',
      whereArgs: ['%$query%'],
    );
    return result;
  }

  // تحديث دواء
  Future<int> updateMedicine(Map<String, dynamic> medicine) async {
    Database db = await database;
    int id = medicine[columnMedicineId];
    return await db.update(
      tableNameMedicines,
      medicine,
      where: '$columnMedicineId = ?',
      whereArgs: [id],
    );
  }

  // حذف دواء
  Future<int> deleteMedicine(int id) async {
    Database db = await database;
    return await db.delete(
      tableNameMedicines,
      where: '$columnMedicineId = ?',
      whereArgs: [id],
    );
  }

  // إضافة الأدوية إلى قاعدة البيانات (التعديل الجديد)
  Future<void> addMedicines() async {
    Database db = await database;
    final existingMedicines = await getAllMedicines();
    final existingNames = existingMedicines.map((m) => m['name'] as String).toSet();

    final List<Map<String, dynamic>> medicines = [
      {'name': 'Erastapex', 'category': 'Olmesartan', 'price': 90.0, 'imagePath': 'assets/medicine/Erastapex.png'},
      {'name': 'Nevilob', 'category': 'Nebivolol', 'price': 70.0, 'imagePath': 'assets/medicine/Nevilob.png'},
      {'name': 'Zisrocin', 'category': 'Antibiotic', 'price': 40.0, 'imagePath': 'assets/medicine/Zisrocin.png'},
      {'name': 'Doliprane', 'category': 'Painkiller', 'price': 10.0, 'imagePath': 'assets/medicine/Doliprane.png'},
      {'name': 'Brufen', 'category': 'Painkiller', 'price': 12.0, 'imagePath': 'assets/medicine/Brufen.png'},
      {'name': 'Aspirin', 'category': 'Painkiller', 'price': 10.5, 'imagePath': 'assets/medicine/Aspirin.png'},
      {'name': 'Panadol', 'category': 'Painkiller', 'price': 8.0, 'imagePath': 'assets/medicine/Panadol.png'},
      {'name': 'Voltaren', 'category': 'Painkiller', 'price': 15.0, 'imagePath': 'assets/medicine/Voltaren.png'},
      {'name': 'Esmolol', 'category': 'Cardiovascular', 'price': 30.0, 'imagePath': 'assets/medicine/Esmolol.png'},
      {'name': 'Claritin', 'category': 'Antihistamine', 'price': 18.0, 'imagePath': 'assets/medicine/Claritin.png'},
      {'name': 'Amoxil', 'category': 'Antibiotic', 'price': 25.0, 'imagePath': 'assets/medicine/Amoxil.png'},
      {'name': 'Sinupret', 'category': 'Respiratory', 'price': 50.0, 'imagePath': 'assets/medicine/Sinupret.png'},
      {'name': 'Serevent', 'category': 'Asthma', 'price': 35.0, 'imagePath': 'assets/medicine/Serevent.png'},
      {'name': 'Clexane', 'category': 'Blood Thinner', 'price': 60.0, 'imagePath': 'assets/medicine/Clexane.png'},
      {'name': 'Diovan', 'category': 'Cardiovascular', 'price': 45.0, 'imagePath': 'assets/medicine/Diovan.png'},
      {'name': 'Cardizem', 'category': 'Cardiovascular', 'price': 30.0, 'imagePath': 'assets/medicine/Cardizem.png'},
      {'name': 'Nexium', 'category': 'Antacid', 'price': 40.0, 'imagePath': 'assets/medicine/Nexium.png'},
      {'name': 'Flixotide', 'category': 'Corticosteroid', 'price': 50.0, 'imagePath': 'assets/medicine/Flixotide.png'},
      {'name': 'Allegra', 'category': 'Antihistamine', 'price': 20.0, 'imagePath': 'assets/medicine/Allegra.png'},
      {'name': 'Creon', 'category': 'Digestive Enzyme', 'price': 100.0, 'imagePath': 'assets/medicine/Creon.png'},
      {'name': 'Zyvox', 'category': 'Antibiotic', 'price': 90.0, 'imagePath': 'assets/medicine/Zyvox.png'},
      {'name': 'Tavanic', 'category': 'Antibiotic', 'price': 80.0, 'imagePath': 'assets/medicine/Tavanic.png'},
      {'name': 'Prednisone', 'category': 'Corticosteroid', 'price': 40.0, 'imagePath': 'assets/medicine/Prednisone.png'},
      {'name': 'Fucidin', 'category': 'Antibiotic', 'price': 45.0, 'imagePath': 'assets/medicine/Fucidin.png'},
      {'name': 'Tylenol', 'category': 'Painkiller', 'price': 10.0, 'imagePath': 'assets/medicine/Tylenol.png'},
      {'name': 'Plavix', 'category': 'Blood Thinner', 'price': 100.0, 'imagePath': 'assets/medicine/Plavix.png'},
      {'name': 'Augmentin', 'category': 'Antibiotic', 'price': 55.0, 'imagePath': 'assets/medicine/Augmentin.png'},
      {'name': 'Xanax', 'category': 'Anxiolytic', 'price': 25.0, 'imagePath': 'assets/medicine/Xanax.png'},
      {'name': 'Lyrica', 'category': 'Anticonvulsant', 'price': 120.0, 'imagePath': 'assets/medicine/Lyrica.png'},
      {'name': 'Zoloft', 'category': 'Antidepressant', 'price': 40.0, 'imagePath': 'assets/medicine/Zoloft.png'},
      {'name': 'Ventolin', 'category': 'Asthma', 'price': 30.0, 'imagePath': 'assets/medicine/Ventolin.png'},
      {'name': 'Bactrim', 'category': 'Antibiotic', 'price': 50.0, 'imagePath': 'assets/medicine/Bactrim.png'},
      {'name': 'Bactroban', 'category': 'Antibiotic', 'price': 30.0, 'imagePath': 'assets/medicine/Bactroban.png'},
      {'name': 'Omeprazole', 'category': 'Antacid', 'price': 20.0, 'imagePath': 'assets/medicine/Omeprazole.png'},
      {'name': 'Glucophage', 'category': 'Diabetes', 'price': 30.0, 'imagePath': 'assets/medicine/Glucophage.png'},
      {'name': 'Cipro', 'category': 'Antibiotic', 'price': 50.0, 'imagePath': 'assets/medicine/Cipro.png'},
      {'name': 'Nexavar', 'category': 'Cancer', 'price': 120.0, 'imagePath': 'assets/medicine/Nexavar.png'},
      {'name': 'Risperdal', 'category': 'Antipsychotic', 'price': 80.0, 'imagePath': 'assets/medicine/Risperdal.png'},
      {'name': 'Imuran', 'category': 'Immunosuppressant', 'price': 50.0, 'imagePath': 'assets/medicine/Imuran.png'},
      {'name': 'Stemetil', 'category': 'Antiemetic', 'price': 35.0, 'imagePath': 'assets/medicine/Stemetil.png'},
      {'name': 'Mobic', 'category': 'Painkiller', 'price': 40.0, 'imagePath': 'assets/medicine/Mobic.png'},
      {'name': 'Lantus', 'category': 'Diabetes', 'price': 150.0, 'imagePath': 'assets/medicine/Lantus.png'},
      {'name': 'Humulin', 'category': 'Diabetes', 'price': 100.0, 'imagePath': 'assets/medicine/Humulin.png'},
      {'name': 'Zantac', 'category': 'Antacid', 'price': 20.0, 'imagePath': 'assets/medicine/Zantac.png'},
      {'name': 'Furosemide', 'category': 'Diuretic', 'price': 15.0, 'imagePath': 'assets/medicine/Furosemide.png'},
      {'name': 'Alprazolam', 'category': 'Anxiolytic', 'price': 25.0, 'imagePath': 'assets/medicine/Alprazolam.png'},
      {'name': 'Xarelto', 'category': 'Blood Thinner', 'price': 130.0, 'imagePath': 'assets/medicine/Xarelto.png'},
      {'name': 'Abilify', 'category': 'Antipsychotic', 'price': 150.0, 'imagePath': 'assets/medicine/Abilify.png'},
      {'name': 'Ativan', 'category': 'Anxiolytic', 'price': 35.0, 'imagePath': 'assets/medicine/Ativan.png'},
      {'name': 'Actos', 'category': 'Diabetes', 'price': 90.0, 'imagePath': 'assets/medicine/Actos.png'},
      {'name': 'Symbicort', 'category': 'Asthma', 'price': 85.0, 'imagePath': 'assets/medicine/Symbicort.png'},
      {'name': 'Dilatrend', 'category': 'Cardiovascular', 'price': 70.0, 'imagePath': 'assets/medicine/Dilatrend.png'},
      {'name': 'Fentanyl', 'category': 'Painkiller', 'price': 400.0, 'imagePath': 'assets/medicine/Fentanyl.png'},
      {'name': 'Benzac', 'category': 'Skincare', 'price': 65.0, 'imagePath': 'assets/medicine/Benzac.png'},
      {'name': 'Doxycycline', 'category': 'Antibiotic', 'price': 50.0, 'imagePath': 'assets/medicine/Doxycycline.png'},
      {'name': 'Neoral', 'category': 'Immunosuppressant', 'price': 200.0, 'imagePath': 'assets/medicine/Neoral.png'},
      {'name': 'Cataflam', 'category': 'Painkiller', 'price': 50.0, 'imagePath': 'assets/medicine/Cataflam.png'},
      {'name': 'Sinemet', 'category': 'Neurology', 'price': 180.0, 'imagePath': 'assets/medicine/Sinemet.png'},
      {'name': 'Gravol', 'category': 'Anti-nausea', 'price': 25.0, 'imagePath': 'assets/medicine/Gravol.png'},
      {'name': 'Effexor', 'category': 'Antidepressant', 'price': 150.0, 'imagePath': 'assets/medicine/Effexor.png'},
      {'name': 'Haldol', 'category': 'Antipsychotic', 'price': 100.0, 'imagePath': 'assets/medicine/Haldol.png'},
      {'name': 'Metoprolol', 'category': 'Cardiovascular', 'price': 40.0, 'imagePath': 'assets/medicine/Metoprolol.png'},
      {'name': 'Lopressor', 'category': 'Cardiovascular', 'price': 45.0, 'imagePath': 'assets/medicine/Lopressor.png'},
      {'name': 'Vermox', 'category': 'Anthelmintic', 'price': 35.0, 'imagePath': 'assets/medicine/Vermox.png'},
      {'name': 'Prozac', 'category': 'Antidepressant', 'price': 80.0, 'imagePath': 'assets/medicine/Prozac.png'},
      {'name': 'Coraspin', 'category': 'Blood Thinner', 'price': 60.0, 'imagePath': 'assets/medicine/Coraspin.png'},
      {'name': 'Euthyrox', 'category': 'Thyroid', 'price': 55.0, 'imagePath': 'assets/medicine/Euthyrox.png'},
      {'name': 'Amiodarone', 'category': 'Cardiovascular', 'price': 150.0, 'imagePath': 'assets/medicine/Amiodarone.png'},
      {'name': 'Ketorolac', 'category': 'Painkiller', 'price': 40.0, 'imagePath': 'assets/medicine/Ketorolac.png'},
      {'name': 'Oxycontin', 'category': 'Painkiller', 'price': 300.0, 'imagePath': 'assets/medicine/Oxycontin.png'},
      {'name': 'Tramadol', 'category': 'Painkiller', 'price': 60.0, 'imagePath': 'assets/medicine/Tramadol.png'},
      {'name': 'Dexamethasone', 'category': 'Corticosteroid', 'price': 80.0, 'imagePath': 'assets/medicine/Dexamethasone.png'},
      {'name': 'Prednisolone', 'category': 'Corticosteroid', 'price': 50.0, 'imagePath': 'assets/medicine/Prednisolone.png'},
      {'name': 'Amlodipine', 'category': 'Cardiovascular', 'price': 25.0, 'imagePath': 'assets/medicine/Amlodipine.png'},
      {'name': 'Norvasc', 'category': 'Cardiovascular', 'price': 30.0, 'imagePath': 'assets/medicine/Norvasc.png'},
      {'name': 'Medrol', 'category': 'Corticosteroid', 'price': 70.0, 'imagePath': 'assets/medicine/Medrol.png'},
      {'name': 'Lactulose', 'category': 'Laxative', 'price': 40.0, 'imagePath': 'assets/medicine/Lactulose.png'},
      {'name': 'Spiriva', 'category': 'Asthma', 'price': 150.0, 'imagePath': 'assets/medicine/Spiriva.png'},
      {'name': 'Tensoplast', 'category': 'Bandage', 'price': 15.0, 'imagePath': 'assets/medicine/Tensoplast.png'},
      {'name': 'Otrivin', 'category': 'Cold and Flu', 'price': 30.0, 'imagePath': 'assets/medicine/Otrivin.png'},
      {'name': 'Daktarin', 'category': 'Antifungal', 'price': 50.0, 'imagePath': 'assets/medicine/Daktarin.png'},
      {'name': 'Gaviscon', 'category': 'Antacid', 'price': 40.0, 'imagePath': 'assets/medicine/Gaviscon.png'},
      {'name': 'Lexapro', 'category': 'Antidepressant', 'price': 120.0, 'imagePath': 'assets/medicine/Lexapro.png'},
      {'name': 'Rivotril', 'category': 'Anxiolytic', 'price': 100.0, 'imagePath': 'assets/medicine/Rivotril.png'},
      {'name': 'Dulcolax', 'category': 'Laxative', 'price': 25.0, 'imagePath': 'assets/medicine/Dulcolax.png'},
      {'name': 'Eliquis', 'category': 'Blood Thinner', 'price': 180.0, 'imagePath': 'assets/medicine/Eliquis.png'},
      {'name': 'Crestor', 'category': 'Cardiovascular', 'price': 250.0, 'imagePath': 'assets/medicine/Crestor.png'},
      {'name': 'Lipitor', 'category': 'Cardiovascular', 'price': 220.0, 'imagePath': 'assets/medicine/Lipitor.png'},
      {'name': 'Zetia', 'category': 'Cardiovascular', 'price': 180.0, 'imagePath': 'assets/medicine/Zetia.png'},
      {'name': 'Tricor', 'category': 'Cardiovascular', 'price': 150.0, 'imagePath': 'assets/medicine/Tricor.png'},
      {'name': 'Zyrtec', 'category': 'Antihistamine', 'price': 45.0, 'imagePath': 'assets/medicine/Zyrtec.png'},
      {'name': 'Clarins', 'category': 'Skincare', 'price': 150.0, 'imagePath': 'assets/medicine/Clarins.png'},
      {'name': 'Simvastatin', 'category': 'Cardiovascular', 'price': 80.0, 'imagePath': 'assets/medicine/Simvastatin.png'},
      {'name': 'Ranitidine', 'category': 'Antacid', 'price': 20.0, 'imagePath': 'assets/medicine/Ranitidine.png'},
      {'name': 'Vitamin C', 'category': 'Vitamins', 'price': 15.0, 'imagePath': 'assets/medicine/Vitamin_C.png'},
      {'name': 'Bupropion', 'category': 'Antidepressant', 'price': 120.0, 'imagePath': 'assets/medicine/Bupropion.png'},
      {'name': 'Losartan', 'category': 'Cardiovascular', 'price': 50.0, 'imagePath': 'assets/medicine/Losartan.png'},
      {'name': 'Doxepin', 'category': 'Antidepressant', 'price': 90.0, 'imagePath': 'assets/medicine/Doxepin.png'},
      {'name': 'Zofran', 'category': 'Antiemetic', 'price': 100.0, 'imagePath': 'assets/medicine/Zofran.png'},
      {'name': 'Dexa', 'category': 'Corticosteroid', 'price': 25.0, 'imagePath': 'assets/medicine/Dexa.png'},
      {'name': 'Zosyn', 'category': 'Antibiotic', 'price': 150.0, 'imagePath': 'assets/medicine/Zosyn.png'},
      {'name': 'Methotrexate', 'category': 'Chemotherapy', 'price': 150.0, 'imagePath': 'assets/medicine/Methotrexate.png'},
      {'name': 'Cefazolin', 'category': 'Antibiotic', 'price': 80.0, 'imagePath': 'assets/medicine/Cefazolin.png'},
      {'name': 'Azithromycin', 'category': 'Antibiotic', 'price': 45.0, 'imagePath': 'assets/medicine/Azithromycin.png'},
      {'name': 'Hydroxychloroquine', 'category': 'Antiviral', 'price': 120.0, 'imagePath': 'assets/medicine/Hydroxychloroquine.png'},
      {'name': 'Valacyclovir', 'category': 'Antiviral', 'price': 90.0, 'imagePath': 'assets/medicine/Valacyclovir.png'},
      {'name': 'Acyclovir', 'category': 'Antiviral', 'price': 50.0, 'imagePath': 'assets/medicine/Acyclovir.png'},
      {'name': 'Rosuvastatin', 'category': 'Cardiovascular', 'price': 220.0, 'imagePath': 'assets/medicine/Rosuvastatin.png'},
      {'name': 'Acetaminophen', 'category': 'Painkiller', 'price': 10.0, 'imagePath': 'assets/medicine/Acetaminophen.png'},
      {'name': 'Lisinopril', 'category': 'Cardiovascular', 'price': 40.0, 'imagePath': 'assets/medicine/Lisinopril.png'},
      {'name': 'Captopril', 'category': 'Cardiovascular', 'price': 30.0, 'imagePath': 'assets/medicine/Captopril.png'},
      {'name': 'Enalapril', 'category': 'Cardiovascular', 'price': 40.0, 'imagePath': 'assets/medicine/Enalapril.png'},
      {'name': 'Tamsulosin', 'category': 'Urology', 'price': 55.0, 'imagePath': 'assets/medicine/Tamsulosin.png'},
      {'name': 'Hydrochlorothiazide', 'category': 'Diuretic', 'price': 15.0, 'imagePath': 'assets/medicine/Hydrochlorothiazide.png'},
      {'name': 'Simethicone', 'category': 'Digestive', 'price': 15.0, 'imagePath': 'assets/medicine/Simethicone.png'},
      {'name': 'Ibuprofen', 'category': 'Painkiller', 'price': 10.0, 'imagePath': 'assets/medicine/Ibuprofen.png'},
      {'name': 'Loratadine', 'category': 'Antihistamine', 'price': 12.0, 'imagePath': 'assets/medicine/Loratadine.png'},
      {'name': 'Amoxicillin', 'category': 'Antibiotic', 'price': 20.0, 'imagePath': 'assets/medicine/Amoxicillin.png'},
      {'name': 'Loperamide', 'category': 'Antidiarrheal', 'price': 10.0, 'imagePath': 'assets/medicine/Loperamide.png'},
      {'name': 'Folic Acid', 'category': 'Vitamins', 'price': 8.0, 'imagePath': 'assets/medicine/Folic_Acid.png'},
      {'name': 'Magnesium', 'category': 'Vitamins', 'price': 15.0, 'imagePath': 'assets/medicine/Magnesium.png'},
      {'name': 'Magnesium Sulfate', 'category': 'Electrolyte', 'price': 20.0, 'imagePath': 'assets/medicine/Magnesium_Sulfate.png'},
      {'name': 'Metoclopramide', 'category': 'Anti-nausea', 'price': 30.0, 'imagePath': 'assets/medicine/Metoclopramide.png'},
      {'name': 'Pantoprazole', 'category': 'Antacid', 'price': 50.0, 'imagePath': 'assets/medicine/Pantoprazole.png'},
      {'name': 'Risperidone', 'category': 'Antipsychotic', 'price': 90.0, 'imagePath': 'assets/medicine/Risperidone.png'},
      {'name': 'Aripiprazole', 'category': 'Antipsychotic', 'price': 150.0, 'imagePath': 'assets/medicine/Aripiprazole.png'},
      {'name': 'Venlafaxine', 'category': 'Antidepressant', 'price': 120.0, 'imagePath': 'assets/medicine/Venlafaxine.png'},
      {'name': 'Clonazepam', 'category': 'Anxiolytic', 'price': 85.0, 'imagePath': 'assets/medicine/Clonazepam.png'},
    ];

    for (var medicine in medicines) {
      if (!existingNames.contains(medicine['name'])) {
        print('Inserting new medicine: ${medicine['name']}');
        await insertMedicine(medicine);
      } else {
        print('Medicine already exists: ${medicine['name']}');
      }
    }

    print('Finished updating medicines. Total in database: ${(await getAllMedicines()).length}');
  }

  // إغلاق قاعدة البيانات (اختياري)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // إعادة تعيين المرجع
  }
}
