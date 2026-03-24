import 'package:irise/core/database/database_helper.dart';
import 'package:irise/data/models/authority.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;

class AuthorityRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _tableName = 'authorities';

  /// Insert a single authority
  Future<int> insert(Authority authority) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(_tableName, _toMap(authority));
      developer.log('Inserted authority: ${authority.authorityName}', name: 'AuthorityRepository');
      return id;
    } catch (e) {
      developer.log('Error inserting authority: $e', name: 'AuthorityRepository');
      rethrow;
    }
  }

  /// Insert multiple authorities (bulk insert)
  Future<void> insertBulk(List<Authority> authorities) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();
      
      for (final authority in authorities) {
        batch.insert(
          _tableName,
          _toMap(authority),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      developer.log('Bulk inserted ${authorities.length} authorities', name: 'AuthorityRepository');
    } catch (e) {
      developer.log('Error bulk inserting authorities: $e', name: 'AuthorityRepository');
      rethrow;
    }
  }

  /// Get all authorities
  Future<List<Authority>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'authority_name ASC',
      );
      
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all authorities: $e', name: 'AuthorityRepository');
      return [];
    }
  }

  /// Get authorities by district ID
  Future<List<Authority>> getByDistrictId(int districtId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'district_id = ?',
        whereArgs: [districtId],
        orderBy: 'authority_name ASC',
      );
      
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting authorities by district: $e', name: 'AuthorityRepository');
      return [];
    }
  }

  /// Get authority by ID
  Future<Authority?> getById(int id) async {
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
      developer.log('Error getting authority by ID: $e', name: 'AuthorityRepository');
      return null;
    }
  }

  /// Get authority by name
  Future<Authority?> getByName(String name) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'authority_name = ?',
        whereArgs: [name],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return _fromMap(maps.first);
      }
      return null;
    } catch (e) {
      developer.log('Error getting authority by name: $e', name: 'AuthorityRepository');
      return null;
    }
  }

  /// Update an authority
  Future<int> update(Authority authority) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        _tableName,
        _toMap(authority),
        where: 'id = ?',
        whereArgs: [authority.id],
      );
    } catch (e) {
      developer.log('Error updating authority: $e', name: 'AuthorityRepository');
      rethrow;
    }
  }

  /// Delete an authority
  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting authority: $e', name: 'AuthorityRepository');
      rethrow;
    }
  }

  /// Clear all authorities
  Future<void> clearAll() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(_tableName);
      developer.log('Cleared all authorities', name: 'AuthorityRepository');
    } catch (e) {
      developer.log('Error clearing authorities: $e', name: 'AuthorityRepository');
      rethrow;
    }
  }

  /// Get count of authorities
  Future<int> getCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      developer.log('Error getting authority count: $e', name: 'AuthorityRepository');
      return 0;
    }
  }

  /// Convert Authority to Map for database
  Map<String, dynamic> _toMap(Authority authority) {
    return {
      'id': authority.id,
      'authority_name': authority.authorityName,
      'slug': authority.slug,
      'district_id': authority.districtId,
      'status': authority.status,
    };
  }

  /// Convert Map to Authority
  Authority _fromMap(Map<String, dynamic> map) {
    return Authority(
      id: map['id'] as int?,
      authorityName: map['authority_name'] as String?,
      slug: map['slug'] as String?,
      districtId: map['district_id'] as int?,
      status: map['status'] as String?,
    );
  }
}
