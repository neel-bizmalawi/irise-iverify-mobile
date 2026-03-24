import 'package:sqflite/sqflite.dart';
import 'package:irise/core/database/database_helper.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'dart:developer' as developer;

class BeneficiaryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _tableName = 'beneficiaries';

  Future<int> insert(Beneficiary beneficiary) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        _tableName,
        beneficiary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      developer.log('Inserted beneficiary with id: $id', name: 'BeneficiaryRepo');
      return id;
    } catch (e) {
      developer.log('Error inserting beneficiary: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<void> insertBulk(List<Beneficiary> beneficiaries) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();
      
      for (var beneficiary in beneficiaries) {
        batch.insert(
          _tableName,
          beneficiary.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      developer.log('Bulk inserted ${beneficiaries.length} beneficiaries', name: 'BeneficiaryRepo');
    } catch (e) {
      developer.log('Error bulk inserting beneficiaries: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<List<Beneficiary>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'created_date DESC',
      );
      return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting all beneficiaries: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<Beneficiary?> getById(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'beneficiary_id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      return Beneficiary.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting beneficiary by id: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<List<Beneficiary>> getByTrainingSite(int trainingPointId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'training_point_id = ?',
        whereArgs: [trainingPointId],
        orderBy: 'created_date DESC',
      );
      return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting beneficiaries by training site: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<List<Beneficiary>> getUnsynced() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 's_is_sync = ?',
        whereArgs: [0],
      );
      return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting unsynced beneficiaries: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<List<Beneficiary>> search(String query) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '''
          first_name LIKE ? OR 
          last_name LIKE ? OR 
          phone_number LIKE ? OR
          national_id LIKE ?
        ''',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: 'created_date DESC',
      );
      return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error searching beneficiaries: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<int> update(Beneficiary beneficiary) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        _tableName,
        beneficiary.toMap(),
        where: 'beneficiary_id = ?',
        whereArgs: [beneficiary.beneficiaryId],
      );
      developer.log('Updated beneficiary: ${beneficiary.beneficiaryId}', name: 'BeneficiaryRepo');
      return count;
    } catch (e) {
      developer.log('Error updating beneficiary: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<int> markAsSynced(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        _tableName,
        {'s_is_sync': 1},
        where: 'beneficiary_id = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      developer.log('Error marking beneficiary as synced: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        _tableName,
        where: 'beneficiary_id = ?',
        whereArgs: [id],
      );
      developer.log('Deleted beneficiary: $id', name: 'BeneficiaryRepo');
      return count;
    } catch (e) {
      developer.log('Error deleting beneficiary: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<int> getCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting beneficiaries count: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<int> getUnsyncedCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE s_is_sync = 0');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting unsynced beneficiaries count: $e', name: 'BeneficiaryRepo');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(_tableName);
      developer.log('Cleared all beneficiaries', name: 'BeneficiaryRepo');
    } catch (e) {
      developer.log('Error clearing beneficiaries: $e', name: 'BeneficiaryRepo');
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
      developer.log('Error getting next offline ID: $e', name: 'BeneficiaryRepo');
      // Fallback to simple counter starting from 1
      return 1;
    }
  }
}
