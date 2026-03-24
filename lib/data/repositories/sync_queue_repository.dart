import 'package:sqflite/sqflite.dart';
import 'package:irise/core/database/database_helper.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class SyncQueueRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _tableName = 'sync_queue';

  Future<int> addToQueue({
    required String tableName,
    required String operation,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        _tableName,
        {
          'table_name': tableName,
          'operation': operation,
          'record_id': recordId,
          'data': jsonEncode(data),
          'created_date': DateTime.now().toIso8601String(),
          'retry_count': 0,
        },
      );
      developer.log('Added to sync queue: $tableName/$operation/$recordId', name: 'SyncQueueRepo');
      return id;
    } catch (e) {
      developer.log('Error adding to sync queue: $e', name: 'SyncQueueRepo');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingItems() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'created_date ASC',
      );
      return maps;
    } catch (e) {
      developer.log('Error getting pending sync items: $e', name: 'SyncQueueRepo');
      rethrow;
    }
  }

  Future<int> updateRetryCount(int id, int retryCount, String? error) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        _tableName,
        {
          'retry_count': retryCount,
          'last_error': error,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      developer.log('Error updating retry count: $e', name: 'SyncQueueRepo');
      rethrow;
    }
  }

  Future<int> removeFromQueue(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      developer.log('Removed from sync queue: $id', name: 'SyncQueueRepo');
      return count;
    } catch (e) {
      developer.log('Error removing from sync queue: $e', name: 'SyncQueueRepo');
      rethrow;
    }
  }

  Future<int> getQueueCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting queue count: $e', name: 'SyncQueueRepo');
      rethrow;
    }
  }

  Future<void> clearQueue() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(_tableName);
      developer.log('Cleared sync queue', name: 'SyncQueueRepo');
    } catch (e) {
      developer.log('Error clearing sync queue: $e', name: 'SyncQueueRepo');
      rethrow;
    }
  }
}
