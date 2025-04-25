import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // اسم الجدول والأعمدة
  final String tableName = 'users';
  final String columnId = 'id';
  final String columnName = 'name';
  final String columnEmail = 'email';
  final String columnPassword = 'password';
  final String columnPhone = 'phone';
  final String columnPhoneCode = 'phone_code';

  // إنشاء نسخة واحدة فقط من DatabaseHelper (Singleton)
  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // الحصول على قاعدة البيانات (إنشاءها إذا لم تكن موجودة)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // تهيئة قاعدة البيانات
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'test_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // إنشاء الجدول عند إنشاء قاعدة البيانات
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnEmail TEXT NOT NULL UNIQUE,
        $columnPassword TEXT NOT NULL,
        $columnPhone TEXT NOT NULL,
        $columnPhoneCode TEXT NOT NULL
      )
    ''');
  }

  // إدراج مستخدم جديد
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert(tableName, user);
  }

  // استرجاع جميع المستخدمين
  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query(tableName);
  }

  // استرجاع مستخدم بواسطة البريد الإلكتروني
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await database;
    final result = await db.query(
      tableName,
      where: '$columnEmail = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // تحديث مستخدم
  Future<int> updateUser(Map<String, dynamic> user) async {
    Database db = await database;
    int id = user[columnId];
    return await db.update(tableName, user, where: '$columnId = ?', whereArgs: [id]);
  }

  // حذف مستخدم
  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }

  // استدعاء: إدراج مستخدم جديد
  Future<void> exampleInsertUser() async {
    var user = {
      'name': 'Test User',
      'email': 'test@example.com',
      'password': 'password123',
      'phone': '123456789',
      'phone_code': '001'
    };
    await insertUser(user);
    print("User inserted successfully");
  }

  // استدعاء: جلب جميع المستخدمين
  Future<void> exampleGetUsers() async {
    var users = await getUsers();
    print("All Users: $users");
  }

  // استدعاء: جلب مستخدم بواسطة الإيميل
  Future<void> exampleGetUserByEmail() async {
    var email = 'test@example.com';
    var user = await getUserByEmail(email);
    if (user != null) {
      print("User found: $user");
    } else {
      print("User not found");
    }
  }

  // استدعاء: تحديث مستخدم
  Future<void> exampleUpdateUser() async {
    var userToUpdate = {
      'id': 1,
      'name': 'Updated User',
      'email': 'updated@example.com',
      'password': 'newpassword',
      'phone': '987654321',
      'phone_code': '002'
    };
    await updateUser(userToUpdate);
    print("User updated successfully");
  }

  // استدعاء: حذف مستخدم
  Future<void> exampleDeleteUser() async {
    var userId = 1;
    await deleteUser(userId);
    print("User deleted successfully");
  }
}
