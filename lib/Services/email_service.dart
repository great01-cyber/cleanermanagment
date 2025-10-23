import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'firebase_config.dart';

// Email configuration model
class EmailConfig {
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final bool useTLS;
  final String fromEmail;
  final String fromName;
  final String adminEmail;

  EmailConfig({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    this.useTLS = true,
    required this.fromEmail,
    required this.fromName,
    required this.adminEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'smtpUsername': smtpUsername,
      'smtpPassword': smtpPassword,
      'useTLS': useTLS,
      'fromEmail': fromEmail,
      'fromName': fromName,
      'adminEmail': adminEmail,
    };
  }

  factory EmailConfig.fromMap(Map<String, dynamic> map) {
    return EmailConfig(
      smtpHost: map['smtpHost'] ?? '',
      smtpPort: map['smtpPort'] ?? 587,
      smtpUsername: map['smtpUsername'] ?? '',
      smtpPassword: map['smtpPassword'] ?? '',
      useTLS: map['useTLS'] ?? true,
      fromEmail: map['fromEmail'] ?? '',
      fromName: map['fromName'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
    );
  }
}

// Email service for sending notifications
class EmailService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final FirebaseAuth _auth = FirebaseConfig.auth;

  // Save email configuration
  static Future<void> saveEmailConfig(EmailConfig config) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      await _firestore
          .collection('email_config')
          .doc('admin_config')
          .set(config.toMap());
    } catch (e) {
      throw Exception('Failed to save email configuration: $e');
    }
  }

  // Get email configuration
  static Future<EmailConfig?> getEmailConfig() async {
    try {
      final doc = await _firestore
          .collection('email_config')
          .doc('admin_config')
          .get();

      if (doc.exists) {
        return EmailConfig.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get email configuration: $e');
    }
  }

  // Send email using a cloud function or external service
  static Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? htmlBody,
    List<String>? attachments,
  }) async {
    try {
      final config = await getEmailConfig();
      if (config == null) {
        throw Exception('Email configuration not found');
      }

      // For Flutter web/mobile, we'll use a cloud function or external service
      // This is a simplified version - in production, you'd use Firebase Functions
      await _sendEmailViaCloudFunction(
        config: config,
        to: to,
        subject: subject,
        body: body,
        htmlBody: htmlBody,
      );
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  // Send issue report email to admin
  static Future<void> sendIssueReportEmail({
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
      final config = await getEmailConfig();
      if (config == null) {
        print('Email configuration not found - skipping email notification');
        return;
      }

      final subject = 'New Issue Report: $title';
      final htmlBody = _generateIssueReportHtml(
        reporterName: reporterName,
        reporterRole: reporterRole,
        title: title,
        description: description,
        floor: floor,
        doorNumber: doorNumber,
        toiletType: toiletType,
        priority: priority,
        imageUrl: imageUrl,
      );

      await sendEmail(
        to: config.adminEmail,
        subject: subject,
        body: _generateIssueReportText(
          reporterName: reporterName,
          reporterRole: reporterRole,
          title: title,
          description: description,
          floor: floor,
          doorNumber: doorNumber,
          toiletType: toiletType,
          priority: priority,
        ),
        htmlBody: htmlBody,
      );
    } catch (e) {
      print('Failed to send issue report email: $e');
      // Don't throw error - email failure shouldn't break the app
    }
  }

  // Test email configuration
  static Future<bool> testEmailConfig(EmailConfig config) async {
    try {
      await sendEmail(
        to: config.adminEmail,
        subject: 'Test Email - Cleaner App',
        body: 'This is a test email to verify your email configuration is working correctly.',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Private method to send email via cloud function
  static Future<void> _sendEmailViaCloudFunction({
    required EmailConfig config,
    required String to,
    required String subject,
    required String body,
    String? htmlBody,
  }) async {
    try {
      // Create email log entry - this will trigger the Cloud Function
      await _firestore.collection('email_logs').add({
        'to': to,
        'subject': subject,
        'body': body,
        'htmlBody': htmlBody,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Email queued for sending to: $to');
    } catch (e) {
      print('Error queuing email: $e');
      throw Exception('Failed to queue email: $e');
    }
  }

  // Generate HTML email for issue report
  static String _generateIssueReportHtml({
    required String reporterName,
    required String reporterRole,
    required String title,
    required String description,
    required String floor,
    required String doorNumber,
    required String toiletType,
    required String priority,
    String? imageUrl,
  }) {
    final priorityColor = _getPriorityColor(priority);
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Issue Report</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #f4f4f4; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
            .priority { display: inline-block; padding: 5px 10px; border-radius: 3px; color: white; font-weight: bold; }
            .content { background: white; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
            .field { margin-bottom: 15px; }
            .label { font-weight: bold; color: #666; }
            .value { margin-top: 5px; }
            .image { max-width: 100%; height: auto; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h2>New Issue Report</h2>
                <span class="priority" style="background-color: $priorityColor;">$priority.toUpperCase()</span>
            </div>
            <div class="content">
                <div class="field">
                    <div class="label">Title:</div>
                    <div class="value">$title</div>
                </div>
                <div class="field">
                    <div class="label">Description:</div>
                    <div class="value">$description</div>
                </div>
                <div class="field">
                    <div class="label">Reporter:</div>
                    <div class="value">$reporterName ($reporterRole)</div>
                </div>
                <div class="field">
                    <div class="label">Location:</div>
                    <div class="value">Floor $floor, Door $doorNumber</div>
                </div>
                <div class="field">
                    <div class="label">Toilet Type:</div>
                    <div class="value">$toiletType</div>
                </div>
                ${imageUrl != null ? '''
                <div class="field">
                    <div class="label">Image:</div>
                    <div class="value">
                        <img src="$imageUrl" alt="Issue Image" class="image">
                    </div>
                </div>
                ''' : ''}
                <div class="field">
                    <div class="label">Reported At:</div>
                    <div class="value">${DateTime.now().toString()}</div>
                </div>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  // Generate plain text email for issue report
  static String _generateIssueReportText({
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
New Issue Report

Title: $title
Priority: $priority.toUpperCase()

Description:
$description

Reporter: $reporterName ($reporterRole)
Location: Floor $floor, Door $doorNumber
Toilet Type: $toiletType

Reported At: ${DateTime.now().toString()}

Please log into the admin dashboard to manage this report.
    ''';
  }

  // Get priority color for HTML
  static String _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return '#dc3545';
      case 'high': return '#fd7e14';
      case 'medium': return '#ffc107';
      case 'low': return '#28a745';
      default: return '#6c757d';
    }
  }
}
