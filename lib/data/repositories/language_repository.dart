import 'package:sqflite/sqflite.dart';
import '../models/language.dart';
import '../../core/database/database_helper.dart';
import 'dart:developer' as developer;

class LanguageRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Language language) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert(
        'languages',
        language.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting language: $e', name: 'LanguageRepository');
      rethrow;
    }
  }

  Future<List<Language>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('languages');
    return List.generate(maps.length, (i) => Language.fromMap(maps[i]));
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('languages');
  }

  Future<void> insertBatch(List<Language> languages) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var language in languages) {
      batch.insert(
        'languages',
        language.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
