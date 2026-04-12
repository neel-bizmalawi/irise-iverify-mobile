import 'package:sqflite/sqflite.dart';
import 'package:irise/core/database/database_helper.dart';
import 'package:irise/data/models/training_site.dart';
import 'dart:developer' as developer;

class TrainingSiteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _tableName = 'training_sites';

  // Insert training site (with duplicate check)
  Future<int> insert(TrainingSite trainingSite) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if record already exists
      final existing = await _findExisting(db, trainingSite);
      
      if (existing != null) {
        // Check if existing record is unsynced (local changes)
        final existingSIsSync = existing['s_is_sync'] as int? ?? 0;
        
        if (existingSIsSync == 0 && trainingSite.sIsSync == 1) {
          // Existing record has local unsynced changes and incoming is from server
          // DO NOT overwrite local changes
          developer.log('Skipping insert - existing record has local unsynced changes: ${trainingSite.trainingSite}', name: 'TrainingSiteRepo');
          return existing['offline_id'] as int;
        }
        
        // Record exists - update it instead
        developer.log('Training site already exists, updating instead: ${trainingSite.trainingSite}', name: 'TrainingSiteRepo');
        await db.update(
          _tableName,
          trainingSite.toMap(),
          where: 'offline_id = ?',
          whereArgs: [existing['offline_id']],
        );
        return existing['offline_id'] as int;
      } else {
        // Record doesn't exist - insert it
        final id = await db.insert(
          _tableName,
          trainingSite.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        developer.log('Inserted training site with id: $id', name: 'TrainingSiteRepo');
        return id;
      }
    } catch (e) {
      developer.log('Error inserting training site: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Insert multiple training sites (bulk insert with duplicate check)
  Future<void> insertBulk(List<TrainingSite> trainingSites) async {
    try {
      final db = await _dbHelper.database;
      
      int inserted = 0;
      int updated = 0;
      int skipped = 0;
      
      developer.log('========================================', name: 'TrainingSiteRepo');
      developer.log('BULK INSERT: Processing ${trainingSites.length} training sites', name: 'TrainingSiteRepo');
      developer.log('========================================', name: 'TrainingSiteRepo');
      
      // Get current count before bulk insert
      final countBefore = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final recordsBefore = Sqflite.firstIntValue(countBefore) ?? 0;
      developer.log('Records in DB BEFORE bulk insert: $recordsBefore', name: 'TrainingSiteRepo');
      
      // Get count of unsynced records BEFORE bulk insert
      final unsyncedBefore = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE s_is_sync = 0');
      final unsyncedCountBefore = Sqflite.firstIntValue(unsyncedBefore) ?? 0;
      developer.log('Unsynced records BEFORE bulk insert: $unsyncedCountBefore', name: 'TrainingSiteRepo');
      
      // Check if our test records exist before bulk insert
      final testRecordsBefore = await db.rawQuery(
        'SELECT offline_id, training_point_id, training_site, s_is_sync FROM $_tableName WHERE training_site IN (?, ?, ?)',
        ['t', 'tt', 'ttt']
      );
      developer.log('>>> Test records BEFORE bulk insert:', name: 'TrainingSiteRepo');
      for (var record in testRecordsBefore) {
        developer.log('>>>   ${record['training_site']}: offline_id=${record['offline_id']}, training_point_id=${record['training_point_id']}, s_is_sync=${record['s_is_sync']}', name: 'TrainingSiteRepo');
      }
      
      // CRITICAL FIX: Separate incoming records into synced (from server) and unsynced (local)
      final syncedIncoming = trainingSites.where((site) => site.sIsSync == 1).toList();
      final unsyncedIncoming = trainingSites.where((site) => site.sIsSync == 0).toList();
      
      developer.log('Incoming: ${syncedIncoming.length} synced (from server), ${unsyncedIncoming.length} unsynced (local)', name: 'TrainingSiteRepo');
      
      // Process each record individually (not in batch) for better error tracking
      for (var site in trainingSites) {
        try {
          // Check if this is one of our test records
          final isTestRecord = site.trainingSite == 't' || site.trainingSite == 'tt' || site.trainingSite == 'ttt';
          
          if (isTestRecord) {
            developer.log('>>> PROCESSING TEST RECORD: ${site.trainingSite} (training_point_id: ${site.trainingPointId}, offline_id: ${site.offlineId}, s_is_sync: ${site.sIsSync})', name: 'TrainingSiteRepo');
          }
          
          // Check if record already exists by training_point_id or offline_id
          final existing = await _findExisting(db, site);
          
          if (existing != null) {
            // Check if existing record is unsynced (local changes)
            final existingSIsSync = existing['s_is_sync'] as int? ?? 0;
            final existingTrainingPointId = existing['training_point_id'] as int?;
            final existingOfflineId = existing['offline_id'] as int?;
            final incomingTrainingPointId = site.trainingPointId;
            
            if (isTestRecord) {
              developer.log('>>> Found existing: offline_id=${existing['offline_id']}, training_point_id=$existingTrainingPointId, s_is_sync=$existingSIsSync', name: 'TrainingSiteRepo');
            }
            
            // CRITICAL: Preserve offline_id if incoming record doesn't have it
            // Server often returns offline_id as null, but we want to keep the local offline_id
            final siteToUpdate = (site.offlineId == null && existingOfflineId != null)
                ? site.copyWith(offlineId: existingOfflineId)
                : site;
            
            // CRITICAL FIX: If existing record is unsynced (local) and incoming is synced (from server)
            // DO NOT overwrite - skip this record to preserve local changes
            if (existingSIsSync == 0 && site.sIsSync == 1) {
              // Existing record has local unsynced changes and incoming is from server
              // DO NOT overwrite local changes
              skipped++;
              if (isTestRecord) {
                developer.log('>>> ACTION: SKIP (protecting local unsynced changes)', name: 'TrainingSiteRepo');
              }
              continue; // Skip to next record
            }
            
            // If incoming data has a training_point_id and existing record doesn't, 
            // this means the record was synced to server and we're now fetching it back
            // We should update it with the server data
            if (existingSIsSync == 0 && incomingTrainingPointId != null && existingTrainingPointId == null) {
              // This is a local record that was synced to server - update it with server data
              await db.update(
                _tableName,
                siteToUpdate.toMap(),
                where: 'offline_id = ?',
                whereArgs: [existing['offline_id']],
              );
              updated++;
              if (isTestRecord) {
                developer.log('>>> ACTION: UPDATE (local record synced to server, preserved offline_id: $existingOfflineId)', name: 'TrainingSiteRepo');
              }
            } else if (existingSIsSync == 1 && site.sIsSync == 1) {
              // Both are synced - update with server data
              await db.update(
                _tableName,
                siteToUpdate.toMap(),
                where: 'offline_id = ?',
                whereArgs: [existing['offline_id']],
              );
              updated++;
              if (isTestRecord) {
                developer.log('>>> ACTION: UPDATE (both synced, preserved offline_id: $existingOfflineId)', name: 'TrainingSiteRepo');
              }
            } else {
              // Skip if incoming is a local record or other edge cases
              skipped++;
              if (isTestRecord) {
                developer.log('>>> ACTION: SKIP (other edge case: existingSIsSync=$existingSIsSync, incomingSIsSync=${site.sIsSync})', name: 'TrainingSiteRepo');
              }
            }
          } else {
            // Record doesn't exist - insert it
            // Use IGNORE to prevent overwriting if there's any conflict
            final insertResult = await db.insert(
              _tableName,
              site.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            
            if (insertResult > 0) {
              inserted++;
              if (isTestRecord) {
                developer.log('>>> ACTION: INSERT (new record, id=$insertResult)', name: 'TrainingSiteRepo');
              }
            } else {
              skipped++;
              if (isTestRecord) {
                developer.log('>>> ACTION: SKIP (insert conflict, record already exists)', name: 'TrainingSiteRepo');
              }
            }
          }
        } catch (e) {
          developer.log('ERROR processing site ${site.trainingSite}: $e', name: 'TrainingSiteRepo');
        }
      }
      
      // Get current count after bulk insert
      final countAfter = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final recordsAfter = Sqflite.firstIntValue(countAfter) ?? 0;
      developer.log('Records in DB AFTER bulk insert: $recordsAfter', name: 'TrainingSiteRepo');
      developer.log('Change: ${recordsAfter - recordsBefore} (inserted: $inserted, updated: $updated, skipped: $skipped)', name: 'TrainingSiteRepo');
      
      // Get count of unsynced records AFTER bulk insert
      final unsyncedAfter = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE s_is_sync = 0');
      final unsyncedCountAfter = Sqflite.firstIntValue(unsyncedAfter) ?? 0;
      developer.log('Unsynced records AFTER bulk insert: $unsyncedCountAfter', name: 'TrainingSiteRepo');
      
      // CRITICAL CHECK: Verify no local unsynced records were lost
      if (unsyncedCountAfter < unsyncedCountBefore) {
        developer.log('⚠️ WARNING: Lost ${unsyncedCountBefore - unsyncedCountAfter} unsynced local records!', name: 'TrainingSiteRepo');
      } else {
        developer.log('✅ All local unsynced records preserved', name: 'TrainingSiteRepo');
      }
      
      // Check if our test records exist after bulk insert
      final testRecordsAfter = await db.rawQuery(
        'SELECT offline_id, training_point_id, training_site, s_is_sync FROM $_tableName WHERE training_site IN (?, ?, ?)',
        ['t', 'tt', 'ttt']
      );
      developer.log('>>> Test records AFTER bulk insert:', name: 'TrainingSiteRepo');
      for (var record in testRecordsAfter) {
        developer.log('>>>   ${record['training_site']}: offline_id=${record['offline_id']}, training_point_id=${record['training_point_id']}, s_is_sync=${record['s_is_sync']}', name: 'TrainingSiteRepo');
      }
      
      developer.log('========================================', name: 'TrainingSiteRepo');
      developer.log('BULK INSERT COMPLETED', name: 'TrainingSiteRepo');
      developer.log('Inserted: $inserted, Updated: $updated, Skipped: $skipped', name: 'TrainingSiteRepo');
      developer.log('========================================', name: 'TrainingSiteRepo');
    } catch (e) {
      developer.log('Error bulk inserting training sites: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Find existing record by training_point_id or offline_id ONLY
  // Do NOT use field-based matching to avoid false duplicates
  Future<Map<String, dynamic>?> _findExisting(Database db, TrainingSite site) async {
    try {
      List<Map<String, dynamic>> results = [];
      
      // Check if this is a test record
      final isTestRecord = site.trainingSite == 't' || site.trainingSite == 'tt' || site.trainingSite == 'ttt';
      
      // ONLY try to find by training_point_id (server ID)
      // This is the ONLY reliable unique identifier from the server
      if (site.trainingPointId != null) {
        results = await db.query(
          _tableName,
          where: 'training_point_id = ?',
          whereArgs: [site.trainingPointId],
          limit: 1,
        );
        if (results.isNotEmpty) {
          if (isTestRecord) {
            developer.log('>>> _findExisting: Found ${site.trainingSite} by training_point_id: ${site.trainingPointId}', name: 'TrainingSiteRepo');
          }
          return results.first;
        } else if (isTestRecord) {
          developer.log('>>> _findExisting: NOT found ${site.trainingSite} by training_point_id: ${site.trainingPointId}', name: 'TrainingSiteRepo');
        }
      }
      
      // ONLY try to find by offline_id for local records (not from server)
      if (site.offlineId != null) {
        results = await db.query(
          _tableName,
          where: 'offline_id = ?',
          whereArgs: [site.offlineId],
          limit: 1,
        );
        if (results.isNotEmpty) {
          if (isTestRecord) {
            developer.log('>>> _findExisting: Found ${site.trainingSite} by offline_id: ${site.offlineId}', name: 'TrainingSiteRepo');
          }
          return results.first;
        } else if (isTestRecord) {
          developer.log('>>> _findExisting: NOT found ${site.trainingSite} by offline_id: ${site.offlineId}', name: 'TrainingSiteRepo');
        }
      }
      
      // DO NOT use field-based matching (training_site name, village, etc.)
      // This causes false duplicates when fields are empty/null
      // Server records MUST have training_point_id, so if we reach here, it's a new record
      
      if (isTestRecord) {
        developer.log('>>> _findExisting: NO MATCH found for ${site.trainingSite} (training_point_id: ${site.trainingPointId}, offline_id: ${site.offlineId})', name: 'TrainingSiteRepo');
      }
      return null;
    } catch (e) {
      developer.log('Error finding existing record: $e', name: 'TrainingSiteRepo');
      return null;
    }
  }

  // Get all training sites
  Future<List<TrainingSite>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'created_date DESC',
      );
      
      developer.log('========================================', name: 'TrainingSiteRepo');
      developer.log('GET ALL: Retrieved ${maps.length} training sites from local DB', name: 'TrainingSiteRepo');
      
      // Log first 5 records for debugging
      final sampleCount = maps.length > 5 ? 5 : maps.length;
      for (int i = 0; i < sampleCount; i++) {
        final record = maps[i];
        developer.log('  Record ${i + 1}: ${record['training_site']} (offline_id=${record['offline_id']}, training_point_id=${record['training_point_id']}, s_is_sync=${record['s_is_sync']})', name: 'TrainingSiteRepo');
      }
      developer.log('========================================', name: 'TrainingSiteRepo');
      
      return List.generate(maps.length, (i) => TrainingSite.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting all training sites: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Get training site by id (checks both training_point_id and offline_id)
  Future<TrainingSite?> getById(int id) async {
    try {
      final db = await _dbHelper.database;
      
      // First try to find by training_point_id (for synced records)
      List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'training_point_id = ?',
        whereArgs: [id],
      );
      
      // If not found by training_point_id, try offline_id (for local unsynced records)
      if (maps.isEmpty) {
        maps = await db.query(
          _tableName,
          where: 'offline_id = ?',
          whereArgs: [id],
        );
      }
      
      if (maps.isEmpty) {
        developer.log('Training site not found with id: $id', name: 'TrainingSiteRepo');
        return null;
      }
      
      developer.log('Found training site: ${maps.first['training_site']} (training_point_id: ${maps.first['training_point_id']}, offline_id: ${maps.first['offline_id']})', name: 'TrainingSiteRepo');
      return TrainingSite.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting training site by id: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  /// Get training site by training_point_id (server-assigned ID)
  Future<TrainingSite?> getByTrainingPointId(int trainingPointId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'training_point_id = ?',
        whereArgs: [trainingPointId],
      );
      
      if (maps.isNotEmpty) {
        return TrainingSite.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      developer.log('Error getting training site by training_point_id: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  /// Get training site by offline_id (locally-assigned ID)
  Future<TrainingSite?> getByOfflineId(int offlineId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'offline_id = ?',
        whereArgs: [offlineId],
      );
      
      if (maps.isNotEmpty) {
        return TrainingSite.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      developer.log('Error getting training site by offline_id: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Get active training sites
  Future<List<TrainingSite>> getActive() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'created_date DESC',
      );
      return List.generate(maps.length, (i) => TrainingSite.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting active training sites: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Get unsynced training sites
  Future<List<TrainingSite>> getUnsynced() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 's_is_sync = ?',
        whereArgs: [0],
      );
      return List.generate(maps.length, (i) => TrainingSite.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error getting unsynced training sites: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Search training sites
  Future<List<TrainingSite>> search(String query) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '''
          training_site LIKE ? OR 
          district LIKE ? OR 
          traditional_authority LIKE ? OR
          gvh_name LIKE ?
        ''',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: 'created_date DESC',
      );
      return List.generate(maps.length, (i) => TrainingSite.fromMap(maps[i]));
    } catch (e) {
      developer.log('Error searching training sites: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Update training site
  Future<int> update(TrainingSite trainingSite) async {
    try {
      final db = await _dbHelper.database;
      
      // Try to update by training_point_id first (for synced records)
      if (trainingSite.trainingPointId != null) {
        final count = await db.update(
          _tableName,
          trainingSite.toMap(),
          where: 'training_point_id = ?',
          whereArgs: [trainingSite.trainingPointId],
        );
        if (count > 0) {
          developer.log('Updated training site by training_point_id: ${trainingSite.trainingPointId}', name: 'TrainingSiteRepo');
          return count;
        }
      }
      
      // If training_point_id is null or not found, try offline_id (for local records)
      if (trainingSite.offlineId != null) {
        final count = await db.update(
          _tableName,
          trainingSite.toMap(),
          where: 'offline_id = ?',
          whereArgs: [trainingSite.offlineId],
        );
        if (count > 0) {
          developer.log('Updated training site by offline_id: ${trainingSite.offlineId}', name: 'TrainingSiteRepo');
          return count;
        }
      }
      
      // If neither ID works, try to find by unique fields and update
      final existing = await _findExisting(db, trainingSite);
      if (existing != null) {
        final count = await db.update(
          _tableName,
          trainingSite.toMap(),
          where: 'offline_id = ?',
          whereArgs: [existing['offline_id']],
        );
        developer.log('Updated training site by offline_id: ${existing['offline_id']}', name: 'TrainingSiteRepo');
        return count;
      }
      
      developer.log('No training site found to update', name: 'TrainingSiteRepo');
      return 0;
    } catch (e) {
      developer.log('Error updating training site: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Mark as synced
  Future<int> markAsSynced(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        _tableName,
        {'s_is_sync': 1},
        where: 'training_point_id = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      developer.log('Error marking training site as synced: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Delete training site
  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        _tableName,
        where: 'training_point_id = ?',
        whereArgs: [id],
      );
      developer.log('Deleted training site: $id', name: 'TrainingSiteRepo');
      return count;
    } catch (e) {
      developer.log('Error deleting training site: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Soft delete (mark as inactive)
  Future<int> softDelete(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        _tableName,
        {'status': 'inactive'},
        where: 'training_point_id = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      developer.log('Error soft deleting training site: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Get count
  Future<int> getCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting training sites count: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Get unsynced count
  Future<int> getUnsyncedCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE s_is_sync = 0');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting unsynced training sites count: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Get synced count
  Future<int> getSyncedCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE s_is_sync = 1');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting synced training sites count: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Check if all training sites are synced
  Future<bool> areAllTrainingSitesSynced() async {
    try {
      final db = await _dbHelper.database;
      
      // Get total count
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final totalCount = Sqflite.firstIntValue(totalResult) ?? 0;
      
      // If no training sites exist, return false (need to sync from server first)
      if (totalCount == 0) {
        developer.log('No training sites found in database', name: 'TrainingSiteRepo');
        return false;
      }
      
      // Get unsynced count
      final unsyncedResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE s_is_sync = 0');
      final unsyncedCount = Sqflite.firstIntValue(unsyncedResult) ?? 0;
      
      final allSynced = unsyncedCount == 0;
      developer.log('Training sites sync status: $unsyncedCount unsynced out of $totalCount total', name: 'TrainingSiteRepo');
      
      return allSynced;
    } catch (e) {
      developer.log('Error checking if all training sites are synced: $e', name: 'TrainingSiteRepo');
      rethrow;
    }
  }

  // Clear all
  Future<void> clearAll() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(_tableName);
      developer.log('Cleared all training sites', name: 'TrainingSiteRepo');
    } catch (e) {
      developer.log('Error clearing training sites: $e', name: 'TrainingSiteRepo');
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
      developer.log('Error getting next offline ID: $e', name: 'TrainingSiteRepo');
      // Fallback to simple counter starting from 1
      return 1;
    }
  }
}
