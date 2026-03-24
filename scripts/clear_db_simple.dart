import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

/// Simple script to clear training sites table
/// Run with: dart run scripts/clear_db_simple.dart
void main() async {
  try {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    print('🧹 Starting to clear training sites table...');
    
    // Try common database paths
    final possiblePaths = [
      'irise_database.db',
      'databases/irise_database.db',
      '/data/data/com.irise.irise/databases/irise_database.db',
    ];
    
    Database? database;
    String? foundPath;
    
    for (final path in possiblePaths) {
      try {
        if (await File(path).exists()) {
          database = await openDatabase(path);
          foundPath = path;
          break;
        }
      } catch (e) {
        // Continue to next path
      }
    }
    
    if (database == null) {
      print('❌ Could not find or open database file');
      print('💡 Try running this after the app has been launched at least once');
      return;
    }
    
    print('📍 Found database at: $foundPath');
    
    // Check if training_sites table exists
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='training_sites'"
    );
    
    if (tables.isEmpty) {
      print('❌ training_sites table does not exist');
      await database.close();
      return;
    }
    
    // Get current count
    final countResult = await database.rawQuery('SELECT COUNT(*) as count FROM training_sites');
    final currentCount = countResult.first['count'] as int;
    
    print('📊 Current training sites count: $currentCount');
    
    if (currentCount == 0) {
      print('✅ Training sites table is already empty');
      await database.close();
      return;
    }
    
    // Clear the table
    await database.delete('training_sites');
    
    // Verify it's cleared
    final newCountResult = await database.rawQuery('SELECT COUNT(*) as count FROM training_sites');
    final newCount = newCountResult.first['count'] as int;
    
    print('✅ Successfully cleared training sites table');
    print('📊 Removed $currentCount records, new count: $newCount');
    
    await database.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}