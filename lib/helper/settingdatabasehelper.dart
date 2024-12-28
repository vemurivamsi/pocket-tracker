import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SettingsDatabaseHelper {
  static final SettingsDatabaseHelper _instance =
      SettingsDatabaseHelper._internal();
  factory SettingsDatabaseHelper() => _instance;

  static Database? _database;

  SettingsDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "settings.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            theme TEXT,
            salary_date TEXT
          )
        ''');
        await db.insert(
            'settings', {'name': '', 'theme': 'Light', 'salary_date': ''});
      },
    );
  }

  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    final settings =
        await db.query('settings', where: 'id = ?', whereArgs: [1]);
    return settings.isNotEmpty ? settings.first : {};
  }

  Future<int> updateSettings(Map<String, dynamic> updatedSettings) async {
    final db = await database;
    return await db.update(
      'settings',
      updatedSettings,
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
