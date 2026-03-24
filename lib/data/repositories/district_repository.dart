import 'package:irise/core/database/database_helper.dart';
import 'package:irise/data/models/district.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;

class DistrictRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'districts';

  /// Insert a single district
  Future<int> insert(District district) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(_tableName, _toMap(district));
      developer.log('Inserted district: ${district.districtName}', name: 'DistrictRepository');
      return id;
    } catch (e) {
      developer.log('Error inserting district: $e', name: 'DistrictRepository');
      rethrow;
    }
  }

  /// Insert multiple districts (bulk insert)
  Future<void> insertBulk(List<District> districts) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();
      
      for (final district in districts) {
        batch.insert(
          _tableName,
          _toMap(district),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      developer.log('Bulk inserted ${districts.length} districts', name: 'DistrictRepository');
    } catch (e) {
      developer.log('Error bulk inserting districts: $e', name: 'DistrictRepository');
      rethrow;
    }
  }

  /// Get all districts
  Future<List<District>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'district_name ASC',
      );
      
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all districts: $e', name: 'DistrictRepository');
      return [];
    }
  }

  /// Get district by ID
  Future<District?> getById(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return _fromMap(maps.first);
      }
      return null;
    } catch (e) {
      developer.log('Error getting district by ID: $e', name: 'DistrictRepository');
      return null;
    }
  }

  /// Get district by name
  Future<District?> getByName(String name) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'district_name = ?',
        whereArgs: [name],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return _fromMap(maps.first);
      }
      return null;
    } catch (e) {
      developer.log('Error getting district by name: $e', name: 'DistrictRepository');
      return null;
    }
  }

  /// Update a district
  Future<int> update(District district) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        _tableName,
        _toMap(district),
        where: 'id = ?',
        whereArgs: [district.id],
      );
    } catch (e) {
      developer.log('Error updating district: $e', name: 'DistrictRepository');
      rethrow;
    }
  }

  /// Delete a district
  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting district: $e', name: 'DistrictRepository');
      rethrow;
    }
  }

  /// Clear all districts
  Future<void> clearAll() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(_tableName);
      developer.log('Cleared all districts', name: 'DistrictRepository');
    } catch (e) {
      developer.log('Error clearing districts: $e', name: 'DistrictRepository');
      rethrow;
    }
  }

  /// Get count of districts
  Future<int> getCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting district count: $e', name: 'DistrictRepository');
      return 0;
    }
  }

  /// Convert District to Map for database
  Map<String, dynamic> _toMap(District district) {
    return {
      'id': district.id,
      'district_name': district.districtName,
      'slug': district.slug,
      'region': district.region,
      'status': district.status,
    };
  }

  /// Convert Map to District
  District _fromMap(Map<String, dynamic> map) {
    return District(
      id: map['id'] as int?,
      districtName: map['district_name'] as String?,
      slug: map['slug'] as String?,
      region: map['region'] as String?,
      status: map['status'] as String?,
    );
  }
}
