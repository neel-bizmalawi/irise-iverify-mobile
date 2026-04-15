import 'package:sqflite/sqflite.dart';
import '../models/monitoring.dart';
import '../../core/database/database_helper.dart';
import 'dart:developer' as developer;

class MonitoringRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Monitoring monitoring) async {
    final db = await _dbHelper.database;
    try {
      // If monitoring has monitoring_id, check if it exists and update instead
      if (monitoring.monitoringId != null) {
        final existing = await db.query(
          'monitoring_data',
          where: 'monitoring_id = ?',
          whereArgs: [monitoring.monitoringId],
        );

        if (existing.isNotEmpty) {
          developer.log(
              'Updating existing monitoring with monitoring_id: ${monitoring.monitoringId}',
              name: 'MonitoringRepository');
          final updateMap = monitoring.toMap()..remove('offline_id');
          return await db.update(
            'monitoring_data',
            updateMap,
            where: 'monitoring_id = ?',
            whereArgs: [monitoring.monitoringId],
          );
        }
      }

      if (monitoring.offlineId != null) {
        final existing = await db.query(
          'monitoring_data',
          where: 'offline_id = ?',
          whereArgs: [monitoring.offlineId],
        );

        if (existing.isNotEmpty) {
          developer.log(
              'Updating existing monitoring with offline_id: ${monitoring.offlineId}',
              name: 'MonitoringRepository');
          final updateMap = monitoring.toMap()..remove('offline_id');
          return await db.update(
            'monitoring_data',
            updateMap,
            where: 'offline_id = ?',
            whereArgs: [monitoring.offlineId],
          );
        }
      }

      // Insert new record
      developer.log('Inserting new monitoring record',
          name: 'MonitoringRepository');
      return await db.insert(
        'monitoring_data',
        monitoring.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting monitoring: $e',
          name: 'MonitoringRepository');
      rethrow;
    }
  }

  Future<List<Monitoring>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('monitoring_data');
    return List.generate(maps.length, (i) => Monitoring.fromMap(maps[i]));
  }

  Future<Monitoring?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monitoring_data',
      where: 'monitoring_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Monitoring.fromMap(maps.first);
    }
    return null;
  }

  Future<Monitoring?> getByOfflineId(int offlineId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monitoring_data',
      where: 'offline_id = ?',
      whereArgs: [offlineId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Monitoring.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(Monitoring monitoring) async {
    final db = await _dbHelper.database;
    try {
      if (monitoring.monitoringId != null) {
        final updateMap = monitoring.toMap()..remove('offline_id');
        return await db.update(
          'monitoring_data',
          updateMap,
          where: 'monitoring_id = ?',
          whereArgs: [monitoring.monitoringId],
        );
      }
      if (monitoring.offlineId != null) {
        final updateMap = monitoring.toMap()..remove('offline_id');
        return await db.update(
          'monitoring_data',
          updateMap,
          where: 'offline_id = ?',
          whereArgs: [monitoring.offlineId],
        );
      }
      return 0;
    } catch (e) {
      developer.log('Error updating monitoring: $e',
          name: 'MonitoringRepository');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'monitoring_data',
      where: 'monitoring_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM monitoring_data');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUnsyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM monitoring_data WHERE s_is_sync = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM monitoring_data WHERE s_is_sync = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Monitoring>> getUnsynced() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monitoring_data',
      where: 's_is_sync = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Monitoring.fromMap(maps[i]));
  }

  Future<List<Monitoring>> getSynced() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monitoring_data',
      where: 's_is_sync = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Monitoring.fromMap(maps[i]));
  }

  Future<void> insertBulk(List<Monitoring> monitoringRecords) async {
    final db = await _dbHelper.database;

    try {
      int inserted = 0;
      int updated = 0;
      int failed = 0;

      for (var monitoring in monitoringRecords) {
        try {
          if (monitoring.monitoringId != null) {
            final existing = await db.query(
              'monitoring_data',
              where: 'monitoring_id = ?',
              whereArgs: [monitoring.monitoringId],
            );

            if (existing.isNotEmpty) {
              final updateMap = monitoring.toMap()..remove('offline_id');
              await db.update(
                'monitoring_data',
                updateMap,
                where: 'monitoring_id = ?',
                whereArgs: [monitoring.monitoringId],
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              updated++;
              continue;
            }
          }

          await db.insert(
            'monitoring_data',
            monitoring.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          inserted++;
        } catch (e) {
          developer.log(
              'Error in bulk operation for monitoring ${monitoring.monitoringId}: $e',
              name: 'MonitoringRepository');
          failed++;
        }
      }

      developer.log(
          'Bulk operation completed: Inserted: $inserted, Updated: $updated, Failed: $failed',
          name: 'MonitoringRepository');
    } catch (e) {
      developer.log('Critical error in bulk insert: $e',
          name: 'MonitoringRepository');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('monitoring_data');
  }

  /// Mark monitoring record as synced using either server monitoring_id or local offline_id
  Future<int> markAsSynced({
    int? monitoringId,
    int? offlineId,
    int? serverMonitoringId,
  }) async {
    final db = await _dbHelper.database;
    try {
      final updateData = <String, dynamic>{'s_is_sync': 1};
      if (serverMonitoringId != null) {
        updateData['monitoring_id'] = serverMonitoringId;
      }

      if (monitoringId != null) {
        return await db.update(
          'monitoring_data',
          updateData,
          where: 'monitoring_id = ?',
          whereArgs: [monitoringId],
        );
      }

      if (offlineId != null) {
        return await db.update(
          'monitoring_data',
          updateData,
          where: 'offline_id = ?',
          whereArgs: [offlineId],
        );
      }

      throw Exception('No monitoring_id or offline_id provided');
    } catch (e) {
      developer.log('Error marking monitoring as synced: $e',
          name: 'MonitoringRepository');
      rethrow;
    }
  }
}
