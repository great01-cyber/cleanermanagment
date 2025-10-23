import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../Models/training_video_model.dart';
import '../Models/training_category_model.dart';

class TrainingVideoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== VIDEO OPERATIONS ====================

  static Future<String> uploadVideo(File videoFile, String fileName) async {
    try {
      final ref = _storage.ref().child('training_videos/videos/$fileName');
      final uploadTask = ref.putFile(videoFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }
  // --- Use 'uploadVideoFromBytes' from your UI instead. ---

  /// Upload video from bytes (for web, mobile, and desktop)
  static Future<String> uploadVideoFromBytes(Uint8List videoBytes, String fileName) async {
    try {
      final ref = _storage.ref().child('training_videos/videos/$fileName');
      // putData works on all platforms
      final uploadTask = ref.putData(videoBytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  static Future<String> uploadThumbnail(File thumbnailFile, String fileName) async {
    try {
      final ref = _storage.ref().child('training_videos/thumbnails/$fileName');
      final uploadTask = ref.putFile(thumbnailFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload thumbnail: $e');
    }
  }
  // --- Use 'uploadThumbnailFromBytes' from your UI instead. ---

  /// Upload thumbnail from bytes (for web, mobile, and desktop)
  static Future<String> uploadThumbnailFromBytes(Uint8List thumbnailBytes, String fileName) async {
    try {
      final ref = _storage.ref().child('training_videos/thumbnails/$fileName');
      // putData works on all platforms
      final uploadTask = ref.putData(thumbnailBytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload thumbnail: $e');
    }
  }

  /// Save video metadata to Firestore
  static Future<void> saveVideoMetadata(TrainingVideo video) async {
    try {
      await _firestore.collection('training_videos').doc(video.id).set(video.toMap());
    } catch (e) {
      throw Exception('Failed to save video metadata: $e');
    }
  }

  /// Get all active videos
  static Future<List<TrainingVideo>> getAllVideos() async {
    try {
      final snapshot = await _firestore
          .collection('training_videos')
          .where('isActive', isEqualTo: true)
          .get();

      // Sort in memory to avoid Firestore index requirement
      final videos = snapshot.docs.map((doc) => TrainingVideo.fromMap(doc.data())).toList();
      videos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return videos;
    } catch (e) {
      throw Exception('Failed to get videos: $e');
    }
  }

  /// Get videos by category
  static Future<List<TrainingVideo>> getVideosByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('training_videos')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      // Sort in memory to avoid Firestore index requirement
      final videos = snapshot.docs.map((doc) => TrainingVideo.fromMap(doc.data())).toList();
      videos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return videos;
    } catch (e) {
      throw Exception('Failed to get videos by category: $e');
    }
  }

  /// Get a specific video by ID
  static Future<TrainingVideo?> getVideoById(String videoId) async {
    try {
      final doc = await _firestore.collection('training_videos').doc(videoId).get();
      if (doc.exists) {
        return TrainingVideo.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get video: $e');
    }
  }

  /// Update video metadata
  static Future<void> updateVideo(TrainingVideo video) async {
    try {
      await _firestore.collection('training_videos').doc(video.id).update(video.toMap());
    } catch (e) {
      throw Exception('Failed to update video: $e');
    }
  }

  /// Delete video (soft delete)
  static Future<void> deleteVideo(String videoId) async {
    try {
      await _firestore.collection('training_videos').doc(videoId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }

  /// Permanently delete video and files
  static Future<void> permanentlyDeleteVideo(String videoId) async {
    try {
      // Get video data first
      final video = await getVideoById(videoId);
      if (video != null) {
        // Delete from Firestore
        await _firestore.collection('training_videos').doc(videoId).delete();

        // Delete video file from Storage
        try {
          await _storage.refFromURL(video.videoUrl).delete();
        } catch (e) {
          print('Failed to delete video file: $e');
        }

        // Delete thumbnail file from Storage
        try {
          await _storage.refFromURL(video.thumbnailUrl).delete();
        } catch (e) {
          print('Failed to delete thumbnail file: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to permanently delete video: $e');
    }
  }

  /// Increment view count
  static Future<void> incrementViewCount(String videoId) async {
    try {
      await _firestore.collection('training_videos').doc(videoId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment view count: $e');
    }
  }

  // ==================== CATEGORY OPERATIONS ====================

  /// Save category to Firestore
  static Future<void> saveCategory(TrainingCategory category) async {
    try {
      await _firestore.collection('training_categories').doc(category.id).set(category.toMap());
    } catch (e) {
      throw Exception('Failed to save category: $e');
    }
  }

  /// Get all active categories
  static Future<List<TrainingCategory>> getAllCategories() async {
    try {
      final snapshot = await _firestore
          .collection('training_categories')
          .where('isActive', isEqualTo: true)
          .get();

      // Sort in memory to avoid Firestore index requirement
      final categories = snapshot.docs.map((doc) => TrainingCategory.fromMap(doc.data())).toList();
      categories.sort((a, b) => a.name.compareTo(b.name));

      return categories;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Get a specific category by ID
  static Future<TrainingCategory?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore.collection('training_categories').doc(categoryId).get();
      if (doc.exists) {
        return TrainingCategory.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  /// Update category
  static Future<void> updateCategory(TrainingCategory category) async {
    try {
      await _firestore.collection('training_categories').doc(category.id).update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete category (soft delete)
  static Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('training_categories').doc(categoryId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Update category video count
  static Future<void> updateCategoryVideoCount(String categoryId) async {
    try {
      final videos = await getVideosByCategory(categoryId);
      await _firestore.collection('training_categories').doc(categoryId).update({
        'videoCount': videos.length,
      });
    } catch (e) {
      throw Exception('Failed to update category video count: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get current user info
  static Future<Map<String, String>> getCurrentUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return {
          'id': user.uid,
          'name': userData['name'] ?? userData['fullName'] ?? 'Unknown User',
          'role': userData['role'] ?? 'user',
        };
      }

      return {
        'id': user.uid,
        'name': user.displayName ?? 'Unknown User',
        'role': 'user',
      };
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }

  /// Generate unique filename
  static String generateFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Handle cases where the original name might not have an extension
    final parts = originalName.split('.');
    final extension = parts.length > 1 ? parts.last : '';
    final nameWithoutExtension = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('.') : originalName;

    // Ensure extension is not empty if one existed
    if (extension.isNotEmpty) {
      return '${nameWithoutExtension}_${timestamp}.$extension';
    } else {
      return '${nameWithoutExtension}_$timestamp';
    }
  }


  /// Get file size in MB
  static double getFileSizeInMB(File file) {
    return file.lengthSync() / (1024 * 1024);
  }

  /// Validate video file
  static bool isValidVideoFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
  }

  /// Validate image file
  static bool isValidImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }
}
