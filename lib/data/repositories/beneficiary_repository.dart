import 'package:sqflite/sqflite.dart';
import '../models/beneficiary.dart';
import '../../core/database/database_helper.dart';
import 'dart:developer' as developer;

class BeneficiaryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Beneficiary beneficiary) async {
    final db = await _dbHelper.database;
    try {
      // If beneficiary has beneficiary_id, check if it exists and update instead
      if (beneficiary.beneficiaryId != null) {
        final existing = await db.query(
          'beneficiaries',
          where: 'beneficiary_id = ?',
          whereArgs: [beneficiary.beneficiaryId],
        );
        
        if (existing.isNotEmpty) {
          // Update existing record - preserve the local id
          final existingId = existing.first['id'] as int;
          developer.log('Updating existing beneficiary with beneficiary_id: ${beneficiary.beneficiaryId} (local id: $existingId)', name: 'BeneficiaryRepository');
          
          // Create updated beneficiary with preserved local id
          final beneficiaryWithId = beneficiary.copyWith(id: existingId);
          
          return await db.update(
            'beneficiaries',
            beneficiaryWithId.toMap(),
            where: 'beneficiary_id = ?',
            whereArgs: [beneficiary.beneficiaryId],
          );
        }
      }
      
      // Insert new record (don't include id, let SQLite auto-generate it)
      developer.log('Inserting new beneficiary (beneficiary_id: ${beneficiary.beneficiaryId}, offline_id: ${beneficiary.offlineId})', name: 'BeneficiaryRepository');
      return await db.insert(
        'beneficiaries',
        beneficiary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting beneficiary: $e', name: 'BeneficiaryRepository');
      rethrow;
    }
  }

  Future<List<Beneficiary>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('beneficiaries');
    return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
  }

  Future<Beneficiary?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'beneficiaries',
      where: 'beneficiary_id = ? OR offline_id = ?',
      whereArgs: [id, id],
    );
    
    if (maps.isNotEmpty) {
      return Beneficiary.fromMap(maps.first);
    }
    return null;
  }

  /// Get beneficiary by beneficiary_id (server-assigned ID)
  Future<Beneficiary?> getByBeneficiaryId(int beneficiaryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'beneficiaries',
      where: 'beneficiary_id = ?',
      whereArgs: [beneficiaryId],
    );
    
    if (maps.isNotEmpty) {
      return Beneficiary.fromMap(maps.first);
    }
    return null;
  }

  /// Get beneficiary by offline_id (locally-assigned ID)
  Future<Beneficiary?> getByOfflineId(int offlineId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'beneficiaries',
      where: 'offline_id = ?',
      whereArgs: [offlineId],
    );
    
    if (maps.isNotEmpty) {
      return Beneficiary.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(Beneficiary beneficiary) async {
    final db = await _dbHelper.database;
    try {
      // Update by beneficiary_id if it exists, otherwise by offline_id
      if (beneficiary.beneficiaryId != null) {
        // Get existing record to preserve local id
        final existing = await db.query(
          'beneficiaries',
          where: 'beneficiary_id = ?',
          whereArgs: [beneficiary.beneficiaryId],
        );
        
        if (existing.isNotEmpty) {
          final existingId = existing.first['id'] as int;
          final beneficiaryWithId = beneficiary.copyWith(id: existingId);
          
          return await db.update(
            'beneficiaries',
            beneficiaryWithId.toMap(),
            where: 'beneficiary_id = ?',
            whereArgs: [beneficiary.beneficiaryId],
          );
        }
      } else if (beneficiary.offlineId != null) {
        // Get existing record to preserve local id
        final existing = await db.query(
          'beneficiaries',
          where: 'offline_id = ?',
          whereArgs: [beneficiary.offlineId],
        );
        
        if (existing.isNotEmpty) {
          final existingId = existing.first['id'] as int;
          final beneficiaryWithId = beneficiary.copyWith(id: existingId);
          
          return await db.update(
            'beneficiaries',
            beneficiaryWithId.toMap(),
            where: 'offline_id = ?',
            whereArgs: [beneficiary.offlineId],
          );
        }
      }
      return 0;
    } catch (e) {
      developer.log('Error updating beneficiary: $e', name: 'BeneficiaryRepository');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'beneficiaries',
      where: 'beneficiary_id = ? OR offline_id = ?',
      whereArgs: [id, id],
    );
  }

  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM beneficiaries');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUnsyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM beneficiaries WHERE s_is_sync = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSyncedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM beneficiaries WHERE s_is_sync = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Beneficiary>> getUnsynced() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'beneficiaries',
      where: 's_is_sync = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
  }

  Future<List<Beneficiary>> getSynced() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'beneficiaries',
      where: 's_is_sync = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
  }

  Future<void> insertBulk(List<Beneficiary> beneficiaries) async {
    final db = await _dbHelper.database;
    
    try {
      int inserted = 0;
      int updated = 0;
      int failed = 0;
      
      // Process each beneficiary individually to avoid transaction rollback on single failure
      for (var beneficiary in beneficiaries) {
        try {
          // If beneficiary has beneficiary_id, check if it exists and update instead
          if (beneficiary.beneficiaryId != null) {
            final existing = await db.query(
              'beneficiaries',
              where: 'beneficiary_id = ?',
              whereArgs: [beneficiary.beneficiaryId],
            );
            
            if (existing.isNotEmpty) {
              // Update existing record - preserve the local id
              final existingId = existing.first['id'] as int;
              developer.log('Bulk update: beneficiary_id ${beneficiary.beneficiaryId} (local id: $existingId)', name: 'BeneficiaryRepository');
              
              // Create updated beneficiary with preserved local id
              final beneficiaryWithId = beneficiary.copyWith(id: existingId);
              
              await db.update(
                'beneficiaries',
                beneficiaryWithId.toMap(),
                where: 'beneficiary_id = ?',
                whereArgs: [beneficiary.beneficiaryId],
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              updated++;
              continue;
            }
          }
          
          // Insert new record (don't include id, let SQLite auto-generate it)
          developer.log('Bulk insert: beneficiary_id ${beneficiary.beneficiaryId}, offline_id ${beneficiary.offlineId}', name: 'BeneficiaryRepository');
          await db.insert(
            'beneficiaries',
            beneficiary.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          inserted++;
        } catch (e, stackTrace) {
          developer.log('Error in bulk operation for beneficiary ${beneficiary.beneficiaryId ?? beneficiary.offlineId}: $e', name: 'BeneficiaryRepository');
          developer.log('Stack trace: $stackTrace', name: 'BeneficiaryRepository');
          developer.log('Beneficiary data: firstName=${beneficiary.firstName}, lastName=${beneficiary.lastName}', name: 'BeneficiaryRepository');
          failed++;
          // Continue with next beneficiary instead of failing entire operation
        }
      }
      
      developer.log('========================================', name: 'BeneficiaryRepository');
      developer.log('Bulk operation completed:', name: 'BeneficiaryRepository');
      developer.log('✅ Inserted: $inserted', name: 'BeneficiaryRepository');
      developer.log('🔄 Updated: $updated', name: 'BeneficiaryRepository');
      developer.log('❌ Failed: $failed', name: 'BeneficiaryRepository');
      developer.log('========================================', name: 'BeneficiaryRepository');
    } catch (e, stackTrace) {
      developer.log('Critical error in bulk insert: $e', name: 'BeneficiaryRepository');
      developer.log('Stack trace: $stackTrace', name: 'BeneficiaryRepository');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('beneficiaries');
  }

  /// Generate next offline ID for new beneficiary
  Future<int> getNextOfflineId() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(offline_id) as max_id FROM beneficiaries',
    );
    final maxId = Sqflite.firstIntValue(result) ?? 0;
    return maxId + 1;
  }

  /// Update beneficiary with server-assigned beneficiary_id after sync
  Future<int> updateWithServerId(int offlineId, int beneficiaryId) async {
    final db = await _dbHelper.database;
    try {
      developer.log('Updating beneficiary with server ID - offline_id: $offlineId, beneficiary_id: $beneficiaryId', name: 'BeneficiaryRepository');
      
      // First check if this beneficiary_id already exists
      final existingWithBeneficiaryId = await db.query(
        'beneficiaries',
        where: 'beneficiary_id = ?',
        whereArgs: [beneficiaryId],
      );
      
      if (existingWithBeneficiaryId.isNotEmpty) {
        final existing = Beneficiary.fromMap(existingWithBeneficiaryId.first);
        developer.log('⚠️ WARNING: beneficiary_id $beneficiaryId already exists!', name: 'BeneficiaryRepository');
        developer.log('Existing record: offline_id=${existing.offlineId}, beneficiary_id=${existing.beneficiaryId}, name=${existing.firstName} ${existing.lastName}', name: 'BeneficiaryRepository');
        
        // Check if it's the same record (same offline_id)
        if (existing.offlineId == offlineId) {
          developer.log('Same record, just marking as synced', name: 'BeneficiaryRepository');
          return await db.update(
            'beneficiaries',
            {'s_is_sync': 1},
            where: 'offline_id = ?',
            whereArgs: [offlineId],
          );
        } else {
          throw Exception('beneficiary_id $beneficiaryId already exists for a different record (offline_id: ${existing.offlineId})');
        }
      }
      
      // Update with server ID and mark as synced
      // Do NOT update modified_date - it should only change when record is edited
      return await db.update(
        'beneficiaries',
        {
          'beneficiary_id': beneficiaryId,
          's_is_sync': 1,
        },
        where: 'offline_id = ?',
        whereArgs: [offlineId],
      );
    } catch (e) {
      developer.log('Error updating beneficiary with server ID: $e', name: 'BeneficiaryRepository');
      rethrow;
    }
  }

  /// Check if National ID already exists (excluding current beneficiary if editing)
  Future<bool> isNationalIdExists(String nationalId, {int? excludeBeneficiaryId, int? excludeOfflineId}) async {
    final db = await _dbHelper.database;
    try {
      String whereClause = 'national_id = ?';
      List<dynamic> whereArgs = [nationalId];
      
      if (excludeBeneficiaryId != null) {
        whereClause += ' AND beneficiary_id != ?';
        whereArgs.add(excludeBeneficiaryId);
      }
      
      if (excludeOfflineId != null) {
        whereClause += ' AND offline_id != ?';
        whereArgs.add(excludeOfflineId);
      }
      
      final result = await db.query(
        'beneficiaries',
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      developer.log('Error checking national ID existence: $e', name: 'BeneficiaryRepository');
      return false;
    }
  }

  /// Check if Device Serial Number already exists (excluding current beneficiary if editing)
  Future<bool> isDeviceSerialNoExists(String deviceSerialNo, {int? excludeBeneficiaryId, int? excludeOfflineId}) async {
    final db = await _dbHelper.database;
    try {
      String whereClause = 'device_serial_no = ?';
      List<dynamic> whereArgs = [deviceSerialNo];
      
      if (excludeBeneficiaryId != null) {
        whereClause += ' AND beneficiary_id != ?';
        whereArgs.add(excludeBeneficiaryId);
      }
      
      if (excludeOfflineId != null) {
        whereClause += ' AND offline_id != ?';
        whereArgs.add(excludeOfflineId);
      }
      
      final result = await db.query(
        'beneficiaries',
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      developer.log('Error checking device serial number existence: $e', name: 'BeneficiaryRepository');
      return false;
    }
  }

  /// Check if a beneficiary was edited after creation
  /// Returns true if modified_date is different from created_date
  bool wasEditedAfterCreation(Beneficiary beneficiary) {
    if (beneficiary.createdDate == null || beneficiary.modifiedDate == null) {
      return false;
    }
    
    try {
      final created = DateTime.parse(beneficiary.createdDate!);
      final modified = DateTime.parse(beneficiary.modifiedDate!);
      
      // Consider edited if modified is more than 1 second after created
      return modified.difference(created).inSeconds > 1;
    } catch (e) {
      developer.log('Error comparing dates: $e', name: 'BeneficiaryRepository');
      return false;
    }
  }
}
