import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_config.dart';

// Simplified email service that works without Cloud Functions
class SimpleEmailService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final FirebaseAuth _auth = FirebaseConfig.auth;

  // Send issue report notification (simplified version)
  static Future<void> sendIssueReportNotification({
    required String reporterName,
    required String reporterRole,
    required String title,
    required String description,
    required String floor,
    required String doorNumber,
    required String toiletType,
    required String priority,
    String? imageUrl,
  }) async {
    try {
      // Create a notification document that admins can see
      await _firestore.collection('email_notifications').add({
        'type': 'issue_report',
        'title': 'New Issue Report: $title',
        'message': _generateNotificationMessage(
          reporterName: reporterName,
          reporterRole: reporterRole,
          title: title,
          description: description,
          floor: floor,
          doorNumber: doorNumber,
          toiletType: toiletType,
          priority: priority,
        ),
        'priority': priority,
        'reporterName': reporterName,
        'reporterRole': reporterRole,
        'location': 'Floor $floor, Door $doorNumber',
        'toiletType': toiletType,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'unread',
        'isEmailSent': false, // Track if email was actually sent
      });

      // Also create a simple email log for tracking
      await _firestore.collection('email_logs').add({
        'to': 'admin@yourcompany.com', // You can configure this
        'subject': 'New Issue Report: $title',
        'body': _generateSimpleEmailText(
          reporterName: reporterName,
          reporterRole: reporterRole,
          title: title,
          description: description,
          floor: floor,
          doorNumber: doorNumber,
          toiletType: toiletType,
          priority: priority,
        ),
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'logged', // Just logged, not actually sent
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Issue report notification logged successfully');
    } catch (e) {
      print('Error logging issue report notification: $e');
    }
  }

  // Get all email notifications for admin dashboard
  static Future<List<Map<String, dynamic>>> getEmailNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('email_notifications')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting email notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('email_notifications')
          .doc(notificationId)
          .update({
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Generate notification message
  static String _generateNotificationMessage({
    required String reporterName,
    required String reporterRole,
    required String title,
    required String description,
    required String floor,
    required String doorNumber,
    required String toiletType,
    required String priority,
  }) {
    return '''
New issue report submitted:

Title: $title
Priority: ${priority.toUpperCase()}
Reporter: $reporterName ($reporterRole)
Location: Floor $floor, Door $doorNumber
Toilet Type: $toiletType

Description:
$description

Please check the admin dashboard for more details.
    ''';
  }

  // Generate simple email text
  static String _generateSimpleEmailText({
    required String reporterName,
    required String reporterRole,
    required String title,
    required String description,
    required String floor,
    required String doorNumber,
    required String toiletType,
    required String priority,
  }) {
    return '''
NEW ISSUE REPORT

Title: $title
Priority: ${priority.toUpperCase()}
Reporter: $reporterName ($reporterRole)
Location: Floor $floor, Door $doorNumber
Toilet Type: $toiletType

Description:
$description

This is an automated notification from the Cleaner App.
Please log into the admin dashboard to manage this report.

---
Cleaner App System
    ''';
  }
}
