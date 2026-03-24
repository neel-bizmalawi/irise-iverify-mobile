import 'package:irise/data/services/data_service.dart';
import 'dart:developer' as developer;

/// Developer utilities for database operations
class DevUtils {
  static final DataService _dataService = DataService();

  /// Clear all training sites from local database
  /// This is a developer utility function
  static Future<void> clearTrainingSitesTable() async {
    try {
      developer.log('DevUtils: Starting to clear training sites table...', name: 'DevUtils');
      
      final response = await _dataService.clearLocalTrainingSites();
      
      if (response.success) {
        developer.log('DevUtils: Successfully cleared training sites table', name: 'DevUtils');
        print('✅ Training sites table cleared successfully');
      } else {
        developer.log('DevUtils: Failed to clear training sites table: ${response.message}', name: 'DevUtils');
        print('❌ Failed to clear training sites table: ${response.message}');
      }
    } catch (e) {
      developer.log('DevUtils: Error clearing training sites table: $e', name: 'DevUtils');
      print('❌ Error clearing training sites table: $e');
    }
  }
}