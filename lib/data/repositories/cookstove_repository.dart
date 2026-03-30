import 'package:sqflite/sqflite.dart';
import '../models/cookstove.dart';
import '../../core/database/database_helper.dart';
import 'dart:developer' as developer;

class CookstoveRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Cookstove cookstove) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert(
        'cookstoves',
        cookstove.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting cookstove: $e', name: 'CookstoveRepository');
      rethrow;
    }
  }

  Future<List<Cookstove>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('cookstoves');
    return List.generate(maps.length, (i) => Cookstove.fromMap(maps[i]));
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('cookstoves');
  }

  Future<void> insertBatch(List<Cookstove> cookstoves) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var cookstove in cookstoves) {
      batch.insert(
        'cookstoves',
        cookstove.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
