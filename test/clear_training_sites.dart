import 'package:flutter_test/flutter_test.dart';
import 'package:irise/utils/dev_utils.dart';

/// Test script to clear training sites table
/// Run this with: flutter test test/clear_training_sites.dart
void main() {
  test('Clear training sites table', () async {
    print('🧹 Clearing training sites table...');
    await DevUtils.clearTrainingSitesTable();
    print('✅ Operation completed');
  });
}