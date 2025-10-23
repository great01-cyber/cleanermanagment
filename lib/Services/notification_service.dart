import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_config.dart';

// Enhanced notification service for real-time notifications
class NotificationService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // Send notification to a specific user
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'title': title,
        'message': message,
        'type': type ?? 'general',
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'readAt': null,
      };

      await _firestore.collection('notifications').add(notification);
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  // Send task assignment notification
  static Future<void> sendTaskNotification({
    required String cleanerId,
    required String taskTitle,
    required String supervisorName,
    required String taskId,
  }) async {
    try {
      await sendNotification(
        userId: cleanerId,
        title: 'New Task Assigned',
        message: 'You have been assigned a new task: $taskTitle by $supervisorName',
        type: 'task_assignment',
        data: {
          'taskId': taskId,
          'supervisorName': supervisorName,
          'taskTitle': taskTitle,
        },
      );
    } catch (e) {
      throw Exception('Failed to send task notification: $e');
    }
  }

  // Send shift assignment notification
  static Future<void> sendShiftNotification({
    required String cleanerId,
    required String shiftTitle,
    required String supervisorName,
    required String shiftId,
    required DateTime dueDate,
  }) async {
    try {
      await sendNotification(
        userId: cleanerId,
        title: 'New Shift Assigned',
        message: 'You have been assigned a new shift: $shiftTitle by $supervisorName. Due: ${dueDate.day}/${dueDate.month}/${dueDate.year} at ${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}',
        type: 'shift_assignment',
        data: {
          'shiftId': shiftId,
          'supervisorName': supervisorName,
          'shiftTitle': shiftTitle,
          'dueDate': dueDate.toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to send shift notification: $e');
    }
  }

  // Send shift update notification
  static Future<void> sendShiftUpdateNotification({
    required String cleanerId,
    required String shiftTitle,
    required String updateType,
    required String supervisorName,
    String? reason,
  }) async {
    try {
      String message = 'Your shift "$shiftTitle" has been $updateType by $supervisorName';
      if (reason != null && reason.isNotEmpty) {
        message += '. Reason: $reason';
      }

      await sendNotification(
        userId: cleanerId,
        title: 'Shift $updateType',
        message: message,
        type: 'shift_update',
        data: {
          'updateType': updateType,
          'supervisorName': supervisorName,
          'shiftTitle': shiftTitle,
          'reason': reason,
        },
      );
    } catch (e) {
      throw Exception('Failed to send shift update notification: $e');
    }
  }

  // Get notifications for current user
  static Future<List<Map<String, dynamic>>> getMyNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(50)
          .get();

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt in descending order (newest first) on client side
      notifications.sort((a, b) {
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
      
      return notifications;
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications
  static Future<void> deleteAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Get notifications by type
  static Future<List<Map<String, dynamic>>> getNotificationsByType(String type) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: type)
          .get();

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt in descending order (newest first) on client side
      notifications.sort((a, b) {
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
      
      return notifications;
    } catch (e) {
      throw Exception('Failed to get notifications by type: $e');
    }
  }

  // Send bulk notification to multiple users
  static Future<void> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final batch = _firestore.batch();
      
      for (String userId in userIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        final notification = {
          'id': notificationRef.id,
          'userId': userId,
          'title': title,
          'message': message,
          'type': type ?? 'general',
          'data': data ?? {},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'readAt': null,
        };
        
        batch.set(notificationRef, notification);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send bulk notification: $e');
    }
  }
}