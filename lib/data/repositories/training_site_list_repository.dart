import 'package:sqflite/sqflite.dart';
import '../models/training_site_list.dart';
import '../../core/database/database_helper.dart';
import 'dart:developer' as developer;

class TrainingSiteListRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(TrainingSiteList trainingSite) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert(
        'training_sites_list',
        trainingSite.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting training site: $e', name: 'TrainingSiteListRepository');
      rethrow;
    }
  }

  Future<List<TrainingSiteList>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('training_sites_list');
    return List.generate(maps.length, (i) => TrainingSiteList.fromMap(maps[i]));
  }

  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete('training_sites_list');
  }

  Future<void> insertBatch(List<TrainingSiteList> trainingSites) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var trainingSite in trainingSites) {
      batch.insert(
        'training_sites_list',
        trainingSite.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
