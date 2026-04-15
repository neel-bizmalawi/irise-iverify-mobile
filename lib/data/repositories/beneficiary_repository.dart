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
          // Update existing record - preserve the local offline_id
          final existingOfflineId = existing.first['offline_id'] as int;
          developer.log(
              'Updating existing beneficiary with beneficiary_id: ${beneficiary.beneficiaryId} (local offline_id: $existingOfflineId)',
              name: 'BeneficiaryRepository');

          // Update existing record
          return await db.update(
            'beneficiaries',
            beneficiary.toMap(),
            where: 'beneficiary_id = ?',
            whereArgs: [beneficiary.beneficiaryId],
          );
        }
      }

      // Insert new record (don't include id, let SQLite auto-generate it)
      developer.log(
          'Inserting new beneficiary (beneficiary_id: ${beneficiary.beneficiaryId}, offline_id: ${beneficiary.offlineId})',
          name: 'BeneficiaryRepository');
      return await db.insert(
        'beneficiaries',
        beneficiary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting beneficiary: $e',
          name: 'BeneficiaryRepository');
      rethrow;
    }
  }

  Future<List<Beneficiary>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('beneficiaries');
    return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
  }

  /// Fetch beneficiaries in pages, ordered with unsynced first and newest first.
  Future<List<Beneficiary>> getPaged({
    required int limit,
    required int offset,
    String? searchQuery,
  }) async {
    final db = await _dbHelper.database;

    final normalizedSearch = searchQuery?.trim().toLowerCase();
    final hasSearch = normalizedSearch != null && normalizedSearch.isNotEmpty;
    final whereClause = hasSearch
        ? '(LOWER(COALESCE(first_name, \"\")) LIKE ? OR LOWER(COALESCE(last_name, \"\")) LIKE ? OR LOWER(COALESCE(national_id, \"\")) LIKE ?)'
        : null;
    final whereArgs = hasSearch
        ? [
            '%$normalizedSearch%',
            '%$normalizedSearch%',
            '%$normalizedSearch%',
          ]
        : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'beneficiaries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy:
          's_is_sync ASC, CASE WHEN s_is_sync = 0 THEN COALESCE(offline_id, 0) ELSE COALESCE(beneficiary_id, 0) END DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => Beneficiary.fromMap(maps[i]));
  }

  /// Get total records count for a given search query.
  Future<int> getFilteredCount({String? searchQuery}) async {
    final db = await _dbHelper.database;

    final normalizedSearch = searchQuery?.trim().toLowerCase();
    final hasSearch = normalizedSearch != null && normalizedSearch.isNotEmpty;

    final result = await db.rawQuery(
      hasSearch
          ? 'SELECT COUNT(*) as count FROM beneficiaries WHERE (LOWER(COALESCE(first_name, \"\")) LIKE ? OR LOWER(COALESCE(last_name, \"\")) LIKE ? OR LOWER(COALESCE(national_id, \"\")) LIKE ?)'
          : 'SELECT COUNT(*) as count FROM beneficiaries',
      hasSearch
          ? [
              '%$normalizedSearch%',
              '%$normalizedSearch%',
              '%$normalizedSearch%',
            ]
          : null,
    );

    return Sqflite.firstIntValue(result) ?? 0;
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
          // Update existing record using beneficiary_id
          return await db.update(
            'beneficiaries',
            beneficiary.toMap(),
            where: 'beneficiary_id = ?',
            whereArgs: [beneficiary.beneficiaryId],
          );
        }
      } else if (beneficiary.offlineId != null) {
        // Update existing record using offline_id
        final existing = await db.query(
          'beneficiaries',
          where: 'offline_id = ?',
          whereArgs: [beneficiary.offlineId],
        );

        if (existing.isNotEmpty) {
          // Update existing record using offline_id
          return await db.update(
            'beneficiaries',
            beneficiary.toMap(),
            where: 'offline_id = ?',
            whereArgs: [beneficiary.offlineId],
          );
        }
      }
      return 0;
    } catch (e) {
      developer.log('Error updating beneficiary: $e',
          name: 'BeneficiaryRepository');
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
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM beneficiaries');
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

      // Get the current max offline_id to assign new ones for downloaded beneficiaries
      int nextOfflineId = await getNextOfflineId();

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
              // Update existing record - preserve the local offline_id
              final existingOfflineId = existing.first['offline_id'] as int;
              developer.log(
                  'Bulk update: beneficiary_id ${beneficiary.beneficiaryId} (local offline_id: $existingOfflineId)',
                  name: 'BeneficiaryRepository');

              // Update existing record
              await db.update(
                'beneficiaries',
                beneficiary.toMap(),
                where: 'beneficiary_id = ?',
                whereArgs: [beneficiary.beneficiaryId],
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              updated++;
              continue;
            }
          }

          // CRITICAL FIX: Assign offline_id to downloaded beneficiaries if they don't have one
          // This prevents ID collision and ensures proper tracking
          Beneficiary beneficiaryToInsert = beneficiary;
          if (beneficiary.offlineId == null) {
            beneficiaryToInsert =
                beneficiary.copyWith(offlineId: nextOfflineId);
            developer.log(
                'Assigning offline_id $nextOfflineId to downloaded beneficiary_id ${beneficiary.beneficiaryId}',
                name: 'BeneficiaryRepository');
            nextOfflineId++;
          }

          // Insert new record (don't include id, let SQLite auto-generate it)
          developer.log(
              'Bulk insert: beneficiary_id ${beneficiaryToInsert.beneficiaryId}, offline_id ${beneficiaryToInsert.offlineId}',
              name: 'BeneficiaryRepository');
          await db.insert(
            'beneficiaries',
            beneficiaryToInsert.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          inserted++;
        } catch (e, stackTrace) {
          developer.log(
              'Error in bulk operation for beneficiary ${beneficiary.beneficiaryId ?? beneficiary.offlineId}: $e',
              name: 'BeneficiaryRepository');
          developer.log('Stack trace: $stackTrace',
              name: 'BeneficiaryRepository');
          developer.log(
              'Beneficiary data: firstName=${beneficiary.firstName}, lastName=${beneficiary.lastName}',
              name: 'BeneficiaryRepository');
          failed++;
          // Continue with next beneficiary instead of failing entire operation
        }
      }

      developer.log('========================================',
          name: 'BeneficiaryRepository');
      developer.log('Bulk operation completed:', name: 'BeneficiaryRepository');
      developer.log('✅ Inserted: $inserted', name: 'BeneficiaryRepository');
      developer.log('🔄 Updated: $updated', name: 'BeneficiaryRepository');
      developer.log('❌ Failed: $failed', name: 'BeneficiaryRepository');
      developer.log('========================================',
          name: 'BeneficiaryRepository');
    } catch (e, stackTrace) {
      developer.log('Critical error in bulk insert: $e',
          name: 'BeneficiaryRepository');
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

  Future<int> remapTrainingSiteId(
      int fromTrainingSiteId, int toTrainingSiteId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'beneficiaries',
      {'training_site': toTrainingSiteId},
      where: 'training_site = ?',
      whereArgs: [fromTrainingSiteId],
    );
  }

  /// Update beneficiary with server-assigned beneficiary_id after sync
  Future<int> updateWithServerId(int offlineId, int beneficiaryId) async {
    final db = await _dbHelper.database;
    try {
      developer.log(
          'Updating beneficiary with server ID - offline_id: $offlineId, beneficiary_id: $beneficiaryId',
          name: 'BeneficiaryRepository');

      // First check if this beneficiary_id already exists
      final existingWithBeneficiaryId = await db.query(
        'beneficiaries',
        where: 'beneficiary_id = ?',
        whereArgs: [beneficiaryId],
      );

      if (existingWithBeneficiaryId.isNotEmpty) {
        final existing = Beneficiary.fromMap(existingWithBeneficiaryId.first);
        developer.log(
            '⚠️ WARNING: beneficiary_id $beneficiaryId already exists!',
            name: 'BeneficiaryRepository');
        developer.log(
            'Existing record: offline_id=${existing.offlineId}, beneficiary_id=${existing.beneficiaryId}, name=${existing.firstName} ${existing.lastName}',
            name: 'BeneficiaryRepository');

        // Check if it's the same record (same offline_id)
        if (existing.offlineId == offlineId) {
          developer.log('Same record, just marking as synced',
              name: 'BeneficiaryRepository');
          return await db.update(
            'beneficiaries',
            {'s_is_sync': 1},
            where: 'offline_id = ?',
            whereArgs: [offlineId],
          );
        } else {
          throw Exception(
              'beneficiary_id $beneficiaryId already exists for a different record (offline_id: ${existing.offlineId})');
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
      developer.log('Error updating beneficiary with server ID: $e',
          name: 'BeneficiaryRepository');
      rethrow;
    }
  }

  /// Check if National ID already exists (excluding current beneficiary if editing)
  Future<bool> isNationalIdExists(String nationalId,
      {int? excludeBeneficiaryId, int? excludeOfflineId}) async {
    final db = await _dbHelper.database;
    try {
      String whereClause = 'national_id = ?';
      List<dynamic> whereArgs = [nationalId];

      // Build exclusion clause: exclude if EITHER beneficiary_id OR offline_id matches
      // This handles cases where record has both IDs or only one
      if (excludeBeneficiaryId != null || excludeOfflineId != null) {
        whereClause += ' AND NOT (';
        List<String> exclusionConditions = [];

        if (excludeBeneficiaryId != null) {
          exclusionConditions.add('beneficiary_id = ?');
          whereArgs.add(excludeBeneficiaryId);
        }

        if (excludeOfflineId != null) {
          exclusionConditions.add('offline_id = ?');
          whereArgs.add(excludeOfflineId);
        }

        whereClause += exclusionConditions.join(' OR ');
        whereClause += ')';
      }

      developer.log(
          'Checking national ID: "$nationalId" with query: $whereClause, args: $whereArgs',
          name: 'BeneficiaryRepository');

      final result = await db.query(
        'beneficiaries',
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      developer.log(
          'National ID check result: ${result.isNotEmpty ? "EXISTS" : "NOT EXISTS"} (found ${result.length} records)',
          name: 'BeneficiaryRepository');

      return result.isNotEmpty;
    } catch (e) {
      developer.log('Error checking national ID existence: $e',
          name: 'BeneficiaryRepository');
      return false;
    }
  }

  /// Check if Device Serial Number already exists (excluding current beneficiary if editing)
  Future<bool> isDeviceSerialNoExists(String deviceSerialNo,
      {int? excludeBeneficiaryId, int? excludeOfflineId}) async {
    final db = await _dbHelper.database;
    try {
      developer.log('========================================',
          name: 'BeneficiaryRepository');
      developer.log('isDeviceSerialNoExists called',
          name: 'BeneficiaryRepository');
      developer.log('Input deviceSerialNo: "$deviceSerialNo"',
          name: 'BeneficiaryRepository');
      developer.log('excludeBeneficiaryId: $excludeBeneficiaryId',
          name: 'BeneficiaryRepository');
      developer.log('excludeOfflineId: $excludeOfflineId',
          name: 'BeneficiaryRepository');

      // First, let's see ALL beneficiaries with device_serial_no
      final allBeneficiaries = await db.query(
        'beneficiaries',
        columns: [
          'beneficiary_id',
          'offline_id',
          'device_serial_no',
          'first_name',
          'last_name'
        ],
        where: 'device_serial_no IS NOT NULL AND device_serial_no != ""',
      );

      developer.log(
          'Total beneficiaries with device_serial_no: ${allBeneficiaries.length}',
          name: 'BeneficiaryRepository');
      for (var ben in allBeneficiaries) {
        developer.log(
            '  - ID: ${ben['beneficiary_id']}, Offline: ${ben['offline_id']}, Serial: "${ben['device_serial_no']}", Name: ${ben['first_name']} ${ben['last_name']}',
            name: 'BeneficiaryRepository');
      }

      String whereClause = 'device_serial_no = ?';
      List<dynamic> whereArgs = [deviceSerialNo];

      // Build exclusion clause: exclude if EITHER beneficiary_id OR offline_id matches
      // This handles cases where record has both IDs or only one
      if (excludeBeneficiaryId != null || excludeOfflineId != null) {
        whereClause += ' AND NOT (';
        List<String> exclusionConditions = [];

        if (excludeBeneficiaryId != null) {
          exclusionConditions.add('beneficiary_id = ?');
          whereArgs.add(excludeBeneficiaryId);
        }

        if (excludeOfflineId != null) {
          exclusionConditions.add('offline_id = ?');
          whereArgs.add(excludeOfflineId);
        }

        whereClause += exclusionConditions.join(' OR ');
        whereClause += ')';
      }

      developer.log('SQL WHERE: $whereClause', name: 'BeneficiaryRepository');
      developer.log('SQL ARGS: $whereArgs', name: 'BeneficiaryRepository');

      final result = await db.query(
        'beneficiaries',
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      developer.log('Query returned ${result.length} records',
          name: 'BeneficiaryRepository');
      if (result.isNotEmpty) {
        developer.log('MATCH FOUND:', name: 'BeneficiaryRepository');
        for (var record in result) {
          developer.log(
              '  - ID: ${record['beneficiary_id']}, Offline: ${record['offline_id']}, Serial: "${record['device_serial_no']}", Name: ${record['first_name']} ${record['last_name']}',
              name: 'BeneficiaryRepository');
        }
      } else {
        developer.log('NO MATCH FOUND', name: 'BeneficiaryRepository');
      }

      final exists = result.isNotEmpty;
      developer.log('FINAL RESULT: ${exists ? "EXISTS" : "NOT EXISTS"}',
          name: 'BeneficiaryRepository');
      developer.log('========================================',
          name: 'BeneficiaryRepository');

      return exists;
    } catch (e, stackTrace) {
      developer.log('ERROR in isDeviceSerialNoExists: $e',
          name: 'BeneficiaryRepository');
      developer.log('Stack trace: $stackTrace', name: 'BeneficiaryRepository');
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
