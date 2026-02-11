import 'dart:convert';
import 'package:edi/constants/error_handling.dart';
import 'package:edi/constants/global_variables.dart';
import 'package:edi/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineSyncService {
  static Database? _database;
  static const String _dbName = 'offline_attendance.db';

  // Initialize local database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE pending_attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT NOT NULL,
            course_id INTEGER NOT NULL,
            token TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            timestamp TEXT NOT NULL,
            device_id TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Save attendance record locally (offline storage)
  static Future<void> savePendingAttendance({
    required String studentId,
    required int courseId,
    required String token,
    required double? latitude,
    required double? longitude,
    required DateTime timestamp,
    String? deviceId,
  }) async {
    final db = await database;
    await db.insert('pending_attendance', {
      'student_id': studentId,
      'course_id': courseId,
      'token': token,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'device_id': deviceId ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get all pending records
  static Future<List<Map<String, dynamic>>> getPendingRecords() async {
    final db = await database;
    final records = await db.query('pending_attendance', orderBy: 'created_at ASC');
    return records;
  }

  // Delete a pending record
  static Future<void> deletePendingRecord(int id) async {
    final db = await database;
    await db.delete('pending_attendance', where: 'id = ?', whereArgs: [id]);
  }

  // Clear all pending records
  static Future<void> clearPendingRecords() async {
    final db = await database;
    await db.delete('pending_attendance');
  }

  // Sync pending records to server
  static Future<bool> syncPendingRecords(BuildContext context) async {
    try {
      final records = await getPendingRecords();
      
      if (records.isEmpty) {
        return true; // Nothing to sync
      }

      // Prepare records for sync
      final recordsData = records.map((record) {
        return {
          'student_id': record['student_id'],
          'course_id': record['course_id'],
          'token': record['token'],
          'latitude': record['latitude'],
          'longitude': record['longitude'],
          'timestamp': record['timestamp'],
          'device_id': record['device_id'],
        };
      }).toList();

      // Get JWT token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        return false;
      }

      // Send to server
      http.Response res = await http.post(
        Uri.parse('$uri/api/sync/attendance/'),
        body: jsonEncode({'records': recordsData}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        // Clear synced records
        await clearPendingRecords();
        return true;
      } else {
        httpErrorHandle(
          response: res,
          context: context,
          onSuccess: () {},
        );
        return false;
      }
    } catch (e) {
      print('Sync error: $e');
      return false;
    }
  }

  // Check if there are pending records
  static Future<bool> hasPendingRecords() async {
    final records = await getPendingRecords();
    return records.isNotEmpty;
  }

  // Get pending records count
  static Future<int> getPendingCount() async {
    final records = await getPendingRecords();
    return records.length;
  }

  // Get local database size
  static Future<int> getLocalDatabaseSize() async {
    final path = join(await getDatabasesPath(), _dbName);
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}
