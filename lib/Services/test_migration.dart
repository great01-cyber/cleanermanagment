import 'video_migration_service.dart';

/// Test the migration service
class TestMigration {
  static Future<void> testMigration() async {
    try {
      print('Testing video migration...');
      
      // Reset migration flag for testing
      VideoMigrationService.resetMigrationFlag();
      
      // Test migration
      await VideoMigrationService.checkAndMigrate();
      
      print('Migration test completed successfully!');
    } catch (e) {
      print('Migration test failed: $e');
    }
  }
}
