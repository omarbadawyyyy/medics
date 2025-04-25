import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_test.dart';

class ApiService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // تسجيل مستخدم جديد
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String phoneCode,
  }) async {
    try {
      // التحقق مما إذا كان البريد الإلكتروني موجودًا بالفعل
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        return {'error': true, 'message': 'Email already registered'};
      }

      // إدخال المستخدم الجديد في قاعدة البيانات
      final userId = await _dbHelper.insertUser({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'phone_code': phoneCode,
      });

      if (userId > 0) {
        return {'success': true, 'message': 'User registered successfully', 'userId': userId};
      } else {
        return {'error': true, 'message': 'Failed to register user'};
      }
    } catch (e) {
      return {'error': true, 'message': 'Unexpected error occurred: $e'};
    }
  }

  // تسجيل الدخول
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dbHelper.getUserByEmail(email);

      if (user == null) {
        return {'error': true, 'message': 'Invalid email or password'};
      }

      // التحقق من صحة كلمة المرور
      if (user['password'] != password) {
        return {'error': true, 'message': 'Invalid email or password'};
      }

      return {
        'success': true,
        'message': 'Login successful',
        'user': {'id': user['id'], 'name': user['name'], 'email': user['email']},
      };
    } catch (e) {
      return {'error': true, 'message': 'Unexpected error occurred: $e'};
    }
  }

  // استرجاع جميع المستخدمين
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      return await _dbHelper.getUsers();
    } catch (e) {
      return [];
    }
  }

  // تحديث بيانات المستخدم
  static Future<Map<String, dynamic>> updateUser({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String phoneCode,
  }) async {
    try {
      final updatedRows = await _dbHelper.updateUser({
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'phone_code': phoneCode,
      });

      if (updatedRows > 0) {
        return {'success': true, 'message': 'User updated successfully'};
      } else {
        return {'error': true, 'message': 'Failed to update user'};
      }
    } catch (e) {
      return {'error': true, 'message': 'Unexpected error occurred: $e'};
    }
  }

  // حذف مستخدم
  static Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final deletedRows = await _dbHelper.deleteUser(id);

      if (deletedRows > 0) {
        return {'success': true, 'message': 'User deleted successfully'};
      } else {
        return {'error': true, 'message': 'Failed to delete user'};
      }
    } catch (e) {
      return {'error': true, 'message': 'Unexpected error occurred: $e'};
    }
  }
}
