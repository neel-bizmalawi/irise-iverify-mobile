import 'package:flutter_test/flutter_test.dart';
import 'package:irise/data/services/data_service.dart';

/// Test script to reset the database
/// Run with: flutter test test/database_reset_test.dart
void main() {
  test('Reset Database', () async {
    print('🔄 Resetting database...');
    
    final dataService = DataService();
    final result = await dataService.resetDatabase();
    
    print('📊 Database Reset Result:');
    print('Success: ${result.success}');
    print('Message: ${result.message}');
    
    expect(result, isNotNull);
  });
}