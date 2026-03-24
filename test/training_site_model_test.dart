import 'package:flutter_test/flutter_test.dart';
import 'package:irise/data/models/training_site.dart';

/// Test script to verify TrainingSite model handles integer offline_id correctly
void main() {
  group('TrainingSite Model Tests', () {
    test('fromMap with integer offline_id', () {
      final map = {
        'training_point_id': 1,
        'training_site': 'Test Site',
        'offline_id': 1234567890, // Integer value from database
        'status': 'active',
        's_is_sync': 0,
      };
      
      final trainingSite = TrainingSite.fromMap(map);
      
      expect(trainingSite.offlineId, equals(1234567890));
      expect(trainingSite.trainingSite, equals('Test Site'));
      print('✅ Integer offline_id handled correctly: ${trainingSite.offlineId}');
    });
    
    test('fromMap with string offline_id (backward compatibility)', () {
      final map = {
        'training_point_id': 1,
        'training_site': 'Test Site',
        'offline_id': '1234567890', // String value (for backward compatibility)
        'status': 'active',
        's_is_sync': 0,
      };
      
      final trainingSite = TrainingSite.fromMap(map);
      
      expect(trainingSite.offlineId, equals(1234567890));
      expect(trainingSite.trainingSite, equals('Test Site'));
      print('✅ String offline_id converted correctly: ${trainingSite.offlineId}');
    });
    
    test('toMap produces correct types', () {
      final trainingSite = TrainingSite(
        trainingPointId: 1,
        trainingSite: 'Test Site',
        offlineId: 1234567890,
        status: 'active',
      );
      
      final map = trainingSite.toMap();
      
      expect(map['offline_id'], isA<int>());
      expect(map['offline_id'], equals(1234567890));
      print('✅ toMap produces integer offline_id: ${map['offline_id']}');
    });
    
    test('toApiJson works correctly', () {
      final trainingSite = TrainingSite(
        trainingPointId: 1,
        trainingSite: 'Test Site',
        offlineId: 1234567890,
        status: 'active',
      );
      
      final json = trainingSite.toApiJson();
      
      expect(json['offline_id'], isA<int>());
      expect(json['offline_id'], equals(1234567890));
      print('✅ toApiJson produces integer offline_id: ${json['offline_id']}');
    });
  });
}