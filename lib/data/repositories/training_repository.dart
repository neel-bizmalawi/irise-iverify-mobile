import 'package:sqflite/sqflite.dart';
import 'package:irise/core/database/database_helper.dart';
import 'package:irise/data/models/training.dart';
import 'dart:developer' as developer;

class TrainingRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _tableName = 'trainings';

  Future<int> insert(Training training) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        _tableName,
        training.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      developer.log('Inserted training with id: $id', name: 'TrainingRepo');
      return id;
    } catch (e) {
      developer.log('Error inserting training: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<void> insertBulk(List<Training> trainings) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();
      
      for (var training in trainings) {
        batch.insert(
          _tableName,
          training.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      developer.log('Bulk inserted ${trainings.length} trainings', name: 'TrainingRepo');
    } catch (e) {
      developer.log('Error bulk inserting trainings: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<List<Training>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'training_date DESC',
      );
      return List.generate(maps.length, (i) => Training.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting all trainings: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<Training?> getById(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'training_id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      return Training.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting training by id: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<List<Training>> getByTrainingSite(int trainingPointId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'training_point_id = ?',
        whereArgs: [trainingPointId],
        orderBy: 'training_date DESC',
      );
      return List.generate(maps.length, (i) => Training.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting trainings by site: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<List<Training>> getUnsynced() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 's_is_sync = ?',
        whereArgs: [0],
      );
      return List.generate(maps.length, (i) => Training.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting unsynced trainings: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<int> update(Training training) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        _tableName,
        training.toMap(),
        where: 'training_id = ?',
        whereArgs: [training.trainingId],
      );
      developer.log('Updated training: ${training.trainingId}', name: 'TrainingRepo');
      return count;
    } catch (e) {
      developer.log('Error updating training: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<int> markAsSynced(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        _tableName,
        {'s_is_sync': 1},
        where: 'training_id = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      developer.log('Error marking training as synced: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        _tableName,
        where: 'training_id = ?',
        whereArgs: [id],
      );
      developer.log('Deleted training: $id', name: 'TrainingRepo');
      return count;
    } catch (e) {
      developer.log('Error deleting training: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<int> getCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting trainings count: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<int> getUnsyncedCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE s_is_sync = 0');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting unsynced trainings count: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(_tableName);
      developer.log('Cleared all trainings', name: 'TrainingRepo');
    } catch (e) {
      developer.log('Error clearing trainings: $e', name: 'TrainingRepo');
      rethrow;
    }
  }

  // Get next simple offline ID
  Future<int> getNextOfflineId() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT MAX(offline_id) as max_id FROM $_tableName WHERE offline_id IS NOT NULL');
      final maxId = Sqflite.firstIntValue(result) ?? 0;
      return maxId + 1;
    } catch (e) {
      developer.log('Error getting next offline ID: $e', name: 'TrainingRepo');
      // Fallback to simple counter starting from 1
      return 1;
    }
  }
}
