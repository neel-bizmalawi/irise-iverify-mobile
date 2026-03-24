import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// Script to clear training sites table directly
/// Run with: dart run scripts/clear_training_sites.dart
void main() async {
  // Initialize sqflite for desktop/CLI usage
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    print('🧹 Clearing training sites table...');
    
    // Get the database path (this might need adjustment based on your setup)
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'irise_database.db');
    
    print('📍 Database path: $path');
    
    // Check if database exists
    if (!await File(path).exists()) {
      print('❌ Database file not found at: $path');
      print('💡 The database might be in a different location or not created yet.');
      return;
    }
    
    // Open database
    final database = await openDatabase(path);
    
    // Clear training sites table
    final count = await database.delete('training_sites');
    
    print('✅ Successfully cleared $count training sites from the database');
    
    // Close database
    await database.close();
    
  } catch (e) {
    print('❌ Error clearing training sites: $e');
  }
}