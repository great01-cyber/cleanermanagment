import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_config.dart';

// Real-time notification provider for managing notifications
class NotificationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseConfig.auth;
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // Initialize real-time notifications
  void initializeNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt in descending order (newest first) on client side
      _notifications.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];
        
        // Handle both Timestamp and String formats
        DateTime? aTime;
        DateTime? bTime;
        
        if (aCreatedAt is Timestamp) {
          aTime = aCreatedAt.toDate();
        } else if (aCreatedAt is String) {
          try {
            aTime = DateTime.parse(aCreatedAt);
          } catch (e) {
            aTime = null;
          }
        }
        
        if (bCreatedAt is Timestamp) {
          bTime = bCreatedAt.toDate();
        } else if (bCreatedAt is String) {
          try {
            bTime = DateTime.parse(bCreatedAt);
          } catch (e) {
            bTime = null;
          }
        }
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      _unreadCount = _notifications.where((n) => !n['isRead']).length;
      notifyListeners();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications = _notifications.where((n) => !n['isRead']).toList();
      
      if (unreadNotifications.isEmpty) return;

      final batch = _firestore.batch();
      for (var notification in unreadNotifications) {
        final docRef = _firestore.collection('notifications').doc(notification['id']);
        batch.update(docRef, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      if (_notifications.isEmpty) return;

      final batch = _firestore.batch();
      for (var notification in _notifications) {
        final docRef = _firestore.collection('notifications').doc(notification['id']);
        batch.delete(docRef);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // Get notifications by type
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return _notifications.where((n) => n['type'] == type).toList();
  }

  // Get recent notifications (last 7 days)
  List<Map<String, dynamic>> getRecentNotifications() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _notifications.where((n) {
      final createdAt = DateTime.parse(n['createdAt']);
      return createdAt.isAfter(sevenDaysAgo);
    }).toList();
  }

  // Check if there are new notifications
  bool hasNewNotifications() {
    return _unreadCount > 0;
  }

  // Get notification by ID
  Map<String, dynamic>? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((n) => n['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Filter notifications by search term
  List<Map<String, dynamic>> searchNotifications(String searchTerm) {
    if (searchTerm.isEmpty) return _notifications;
    
    final lowerSearchTerm = searchTerm.toLowerCase();
    return _notifications.where((n) {
      final title = (n['title'] ?? '').toLowerCase();
      final message = (n['message'] ?? '').toLowerCase();
      return title.contains(lowerSearchTerm) || message.contains(lowerSearchTerm);
    }).toList();
  }

  // Get notification statistics
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{
      'total': _notifications.length,
      'unread': _unreadCount,
      'read': _notifications.length - _unreadCount,
    };

    // Count by type
    for (var notification in _notifications) {
      final type = notification['type'] ?? 'general';
      stats[type] = (stats[type] ?? 0) + 1;
    }

    return stats;
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
