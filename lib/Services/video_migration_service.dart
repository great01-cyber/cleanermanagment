import 'dart:convert';
import 'package:flutter/services.dart';
import '../Models/training_video_model.dart';
import '../Models/training_category_model.dart';
import 'training_video_service.dart';

class VideoMigrationService {
  static bool _hasMigrated = false;

  /// Check if migration is needed and perform it
  static Future<void> checkAndMigrate() async {
    if (_hasMigrated) return;

    try {
      // Check if videos already exist in Firebase
      final existingVideos = await TrainingVideoService.getAllVideos();
      if (existingVideos.isNotEmpty) {
        _hasMigrated = true;
        return;
      }

      // Perform migration
      await _migrateFromJson();
      _hasMigrated = true;
    } catch (e) {
      print('Migration failed: $e');
    }
  }

  /// Migrate videos and categories from JSON to Firebase
  static Future<void> _migrateFromJson() async {
    try {
      // Load JSON data
      final infoJson = await rootBundle.loadString('json/info.json');
      final videoInfoJson = await rootBundle.loadString('json/videoinfo.json');
      
      final info = json.decode(infoJson) as List;
      final videoInfo = json.decode(videoInfoJson) as List;

      // Create default categories from info.json
      final categories = <TrainingCategory>[];
      for (int i = 0; i < info.length; i++) {
        final categoryData = info[i] as Map<String, dynamic>;
        final category = TrainingCategory(
          id: 'category_$i',
          name: categoryData['title'] ?? 'Category ${i + 1}',
          description: 'Training category for ${categoryData['title'] ?? 'Category ${i + 1}'}',
          iconUrl: '', // Will be empty for now
          videoCount: 0,
        );
        categories.add(category);
        await TrainingVideoService.saveCategory(category);
      }

      // Create videos from videoinfo.json
      final videos = <TrainingVideo>[];
      for (int i = 0; i < videoInfo.length; i++) {
        final videoData = videoInfo[i] as Map<String, dynamic>;
        
        // Assign to a category (cycle through available categories)
        final categoryIndex = i % categories.length;
        final category = categories[categoryIndex];
        
        final video = TrainingVideo(
          id: 'video_$i',
          title: videoData['title'] ?? 'Video ${i + 1}',
          description: 'Training video: ${videoData['title'] ?? 'Video ${i + 1}'}',
          category: category.id,
          videoUrl: videoData['videoUrl'] ?? '',
          thumbnailUrl: videoData['thumbnail'] ?? '',
          duration: videoData['time'] ?? 'Unknown',
          uploadedBy: 'system',
          uploadedByName: 'System Migration',
          uploadedAt: DateTime.now().subtract(Duration(days: i)),
          isActive: true,
          viewCount: 0, categoryId: '',
        );
        
        videos.add(video);
        await TrainingVideoService.saveVideoMetadata(video);
      }

      // Update category video counts
      for (final category in categories) {
        final categoryVideos = videos.where((v) => v.category == category.id).toList();
        final updatedCategory = category.copyWith(videoCount: categoryVideos.length);
        await TrainingVideoService.updateCategory(updatedCategory);
      }

      print('Successfully migrated ${videos.length} videos and ${categories.length} categories');
    } catch (e) {
      print('Error during migration: $e');
      rethrow;
    }
  }

  /// Create sample categories if none exist
  static Future<void> createSampleCategories() async {
    try {
      final existingCategories = await TrainingVideoService.getAllCategories();
      if (existingCategories.isNotEmpty) return;

      final sampleCategories = [
        TrainingCategory(
          id: 'sinks',
          name: 'Sinks',
          description: 'Sink cleaning and maintenance procedures',
          iconUrl: '',
          videoCount: 0,
        ),
        TrainingCategory(
          id: 'blue_rolls',
          name: 'Blue Rolls',
          description: 'Blue roll changing and restocking procedures',
          iconUrl: '',
          videoCount: 0,
        ),
        TrainingCategory(
          id: 'i_mop',
          name: 'I-Mop',
          description: 'I-Mop usage and maintenance training',
          iconUrl: '',
          videoCount: 0,
        ),
        TrainingCategory(
          id: 'chemicals',
          name: 'Chemicals',
          description: 'Chemical mixing and safety procedures',
          iconUrl: '',
          videoCount: 0,
        ),
        TrainingCategory(
          id: 'general',
          name: 'General Cleaning',
          description: 'General cleaning procedures and techniques',
          iconUrl: '',
          videoCount: 0,
        ),
      ];

      for (final category in sampleCategories) {
        await TrainingVideoService.saveCategory(category);
      }

      print('Created ${sampleCategories.length} sample categories');
    } catch (e) {
      print('Error creating sample categories: $e');
    }
  }

  /// Create sample videos if none exist
  static Future<void> createSampleVideos() async {
    try {
      final existingVideos = await TrainingVideoService.getAllVideos();
      if (existingVideos.isNotEmpty) return;

      final categories = await TrainingVideoService.getAllCategories();
      if (categories.isEmpty) {
        await createSampleCategories();
        return;
      }

      final sampleVideos = [
        TrainingVideo(
          id: 'sample_video_1',
          title: 'Washing of Sink',
          description: 'Complete guide to proper sink cleaning procedures',
          category: categories.isNotEmpty ? categories[0].id : 'sinks',
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
          thumbnailUrl: '',
          duration: '45 seconds',
          uploadedBy: 'system',
          uploadedByName: 'System',
          uploadedAt: DateTime.now().subtract(Duration(days: 1)),
          isActive: true,
          viewCount: 0, categoryId: '',
        ),
        TrainingVideo(
          id: 'sample_video_2',
          title: 'Restocking Blue Rolls',
          description: 'How to properly restock blue rolls in restrooms',
          category: categories.length > 1 ? categories[1].id : categories[0].id,
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
          thumbnailUrl: '',
          duration: '55 seconds',
          uploadedBy: 'system',
          uploadedByName: 'System',
          uploadedAt: DateTime.now().subtract(Duration(days: 2)),
          isActive: true,
          viewCount: 0, categoryId: '',
        ),
        TrainingVideo(
          id: 'sample_video_3',
          title: 'Using the I-Mop',
          description: 'Proper I-Mop usage and maintenance techniques',
          category: categories.length > 2 ? categories[2].id : categories[0].id,
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
          thumbnailUrl: '',
          duration: '60 seconds',
          uploadedBy: 'system',
          uploadedByName: 'System',
          uploadedAt: DateTime.now().subtract(Duration(days: 3)),
          isActive: true,
          viewCount: 0, categoryId: '',
        ),
      ];

      for (final video in sampleVideos) {
        await TrainingVideoService.saveVideoMetadata(video);
      }

      // Update category video counts
      for (final category in categories) {
        await TrainingVideoService.updateCategoryVideoCount(category.id);
      }

      print('Created ${sampleVideos.length} sample videos');
    } catch (e) {
      print('Error creating sample videos: $e');
    }
  }

  /// Reset migration flag (for testing)
  static void resetMigrationFlag() {
    _hasMigrated = false;
  }
}
