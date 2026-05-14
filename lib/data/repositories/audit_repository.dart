import 'package:sqflite/sqflite.dart';
import '../models/audit.dart';
import '../../core/database/database_helper.dart';
import 'dart:developer' as developer;

class AuditRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Audit audit) async {
    final db = await _dbHelper.database;
    try {
      // If audit has audit_id, check if it exists and update instead
      if (audit.auditId != null) {
        final existing = await db.query(
          'audit',
          where: 'audit_id = ?',
          whereArgs: [audit.auditId],
        );

        if (existing.isNotEmpty) {
          developer.log(
              'Updating existing audit with audit_id: ${audit.auditId}',
              name: 'AuditRepository');
          final updateMap = audit.toMap()..remove('offline_id');
          return await db.update(
            'audit',
            updateMap,
            where: 'audit_id = ?',
            whereArgs: [audit.auditId],
          );
        }
      }

      if (audit.offlineId != null) {
        final existing = await db.query(
          'audit',
          where: 'offline_id = ?',
          whereArgs: [audit.offlineId],
        );

        if (existing.isNotEmpty) {
          developer.log(
              'Updating existing audit with offline_id: ${audit.offlineId}',
              name: 'AuditRepository');
          final updateMap = audit.toMap()..remove('offline_id');
          return await db.update(
            'audit',
            updateMap,
            where: 'offline_id = ?',
            whereArgs: [audit.offlineId],
          );
        }
      }

      // Insert new record
      developer.log('Inserting new audit record', name: 'AuditRepository');
      return await db.insert(
        'audit',
        audit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting audit: $e', name: 'AuditRepository');
      rethrow;
    }
  }

  Future<List<Audit>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('audit');
    return List.generate(maps.length, (i) => Audit.fromMap(maps[i]));
  }

  Future<Audit?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audit',
      where: 'audit_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Audit.fromMap(maps.first);
    }
    return null;
  }

  Future<Audit?> getByOfflineId(int offlineId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audit',
      where: 'offline_id = ?',
      whereArgs: [offlineId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Audit.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(Audit audit) async {
    final db = await _dbHelper.database;
    try {
      if (audit.auditId != null) {
        final updateMap = audit.toMap()..remove('offline_id');
        return await db.update(
          'audit',
          updateMap,
          where: 'audit_id = ?',
          whereArgs: [audit.auditId],
        );
      }
      if (audit.offlineId != null) {
        final updateMap = audit.toMap()..remove('offline_id');
        return await db.update(
          'audit',
          updateMap,
          where: 'offline_id = ?',
          whereArgs: [audit.offlineId],
        );
      }
      return 0;
    } catch (e) {
      developer.log('Error updating audit: $e', name: 'AuditRepository');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'audit',
      where: 'audit_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM audit');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUnsyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM audit WHERE s_is_sync = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM audit WHERE s_is_sync = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Audit>> getUnsynced() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audit',
      where: 's_is_sync = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Audit.fromMap(maps[i]));
  }

  Future<List<Audit>> getSynced() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audit',
      where: 's_is_sync = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Audit.fromMap(maps[i]));
  }

  Future<void> insertBulk(List<Audit> audits) async {
    final db = await _dbHelper.database;

    try {
      int inserted = 0;
      int updated = 0;
      int failed = 0;

      for (var audit in audits) {
        try {
          if (audit.auditId != null) {
            final existing = await db.query(
              'audit',
              where: 'audit_id = ?',
              whereArgs: [audit.auditId],
            );

            if (existing.isNotEmpty) {
              await db.update(
                'audit',
                audit.toMap(),
                where: 'audit_id = ?',
                whereArgs: [audit.auditId],
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              updated++;
              continue;
            }
          }

          await db.insert(
            'audit',
            audit.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          inserted++;
        } catch (e) {
          developer.log(
              'Error in bulk operation for audit ${audit.auditId}: $e',
              name: 'AuditRepository');
          failed++;
        }
      }

      developer.log(
          'Bulk operation completed: Inserted: $inserted, Updated: $updated, Failed: $failed',
          name: 'AuditRepository');
    } catch (e) {
      developer.log('Critical error in bulk insert: $e',
          name: 'AuditRepository');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('audit');
  }

  /// Mark audit record as synced
  Future<int> markAsSynced({
    int? auditId,
    int? offlineId,
    int? serverAuditId,
  }) async {
    final db = await _dbHelper.database;
    try {
      final updateData = <String, dynamic>{'s_is_sync': 1};
      if (serverAuditId != null) {
        updateData['audit_id'] = serverAuditId;
      }

      if (auditId != null) {
        return await db.update(
          'audit',
          updateData,
          where: 'audit_id = ?',
          whereArgs: [auditId],
        );
      }

      if (offlineId != null) {
        return await db.update(
          'audit',
          updateData,
          where: 'offline_id = ?',
          whereArgs: [offlineId],
        );
      }

      throw Exception('No audit_id or offline_id provided');
    } catch (e) {
      developer.log('Error marking audit as synced: $e',
          name: 'AuditRepository');
      rethrow;
    }
  }
}
