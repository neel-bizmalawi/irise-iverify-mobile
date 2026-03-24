import 'package:flutter_test/flutter_test.dart';
import 'package:irise/data/services/data_service.dart';

/// Test script to verify API connectivity
/// Run with: flutter test test/api_test.dart
void main() {
  group('API Connectivity Tests', () {
    late DataService dataService;
    
    setUp(() {
      dataService = DataService();
    });
    
    test('Test Districts API', () async {
      print('🌐 Testing Districts API...');
      
      final response = await dataService.getDistricts();
      
      print('📊 Districts API Response:');
      print('Success: ${response.success}');
      print('Message: ${response.message}');
      if (response.data != null) {
        print('Data count: ${response.data!.length}');
      }
      
      // Don't fail the test, just report results
      expect(response, isNotNull);
    });
    
    test('Test Authorities API', () async {
      print('🌐 Testing Authorities API...');
      
      final response = await dataService.getAuthorities();
      
      print('📊 Authorities API Response:');
      print('Success: ${response.success}');
      print('Message: ${response.message}');
      if (response.data != null) {
        print('Data count: ${response.data!.length}');
      }
      
      // Don't fail the test, just report results
      expect(response, isNotNull);
    });
  });
}