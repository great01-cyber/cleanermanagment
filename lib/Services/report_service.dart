import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'firebase_config.dart';
import 'email_service.dart';

// Issue Report data model
class IssueReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterRole;
  final String title;
  final String description;
  final String floor;
  final String doorNumber;
  final String toiletType;
  final String status; // 'pending', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? assignedTo; // supervisor ID who will handle this
  final String? assignedToName;
  final String? resolution;
  final String? imageUrl;
  final String? notes;

  IssueReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterRole,
    required this.title,
    required this.description,
    required this.floor,
    required this.doorNumber,
    required this.toiletType,
    this.status = 'pending',
    this.priority = 'medium',
    required this.createdAt,
    this.resolvedAt,
    this.assignedTo,
    this.assignedToName,
    this.resolution,
    this.imageUrl,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterRole': reporterRole,
      'title': title,
      'description': description,
      'floor': floor,
      'doorNumber': doorNumber,
      'toiletType': toiletType,
      'status': status,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'resolution': resolution,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  factory IssueReport.fromMap(Map<String, dynamic> map) {
    return IssueReport(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reporterRole: map['reporterRole'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      floor: map['floor'] ?? '',
      doorNumber: map['doorNumber'] ?? '',
      toiletType: map['toiletType'] ?? '',
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'medium',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt']) : null,
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
      resolution: map['resolution'],
      imageUrl: map['imageUrl'],
      notes: map['notes'],
    );
  }
}

// Service for managing issue reports
class ReportService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final FirebaseStorage _storage = FirebaseConfig.storage;

  // Submit a new issue report
  static Future<String> submitReport({
    required String title,
    required String description,
    required String floor,
    required String doorNumber,
    required String toiletType,
    String priority = 'medium',
    File? image,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get user details
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data()!;
      final reporterName = userData['name'] ?? userData['fullName'] ?? 'Unknown';
      final reporterRole = userData['role'] ?? 'cleaner';

      // Upload image if provided
      String? imageUrl;
      if (image != null) {
        final ref = _storage.ref().child('issue_reports/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(image);
        imageUrl = await ref.getDownloadURL();
      }

      // Create report
      final reportId = _firestore.collection('issue_reports').doc().id;
      final report = IssueReport(
        id: reportId,
        reporterId: currentUser.uid,
        reporterName: reporterName,
        reporterRole: reporterRole,
        title: title,
        description: description,
        floor: floor,
        doorNumber: doorNumber,
        toiletType: toiletType,
        priority: priority,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        notes: notes,
      );

      // Save to Firestore
      await _firestore.collection('issue_reports').doc(reportId).set(report.toMap());

      // Send notification to assigned supervisor
      await _notifySupervisors(report);

      return reportId;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  // Get all reports for supervisors
  static Future<List<IssueReport>> getAllReports() async {
    try {
      final snapshot = await _firestore
          .collection('issue_reports')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => IssueReport.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports: $e');
    }
  }

  // Get reports for a specific supervisor (from their assigned cleaners)
  static Future<List<IssueReport>> getSupervisorReports(String supervisorId) async {
    try {
      // Get all cleaners assigned to this supervisor
      final cleanersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'cleaner')
          .where('supervisorId', isEqualTo: supervisorId)
          .get();

      if (cleanersSnapshot.docs.isEmpty) {
        return [];
      }

      // Get cleaner IDs
      final cleanerIds = cleanersSnapshot.docs.map((doc) => doc.id).toList();

      // Get reports from these cleaners
      final reportsSnapshot = await _firestore
          .collection('issue_reports')
          .where('reporterId', whereIn: cleanerIds)
          .orderBy('createdAt', descending: true)
          .get();

      return reportsSnapshot.docs
          .map((doc) => IssueReport.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get supervisor reports: $e');
    }
  }

  // Get reports by status
  static Future<List<IssueReport>> getReportsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('issue_reports')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => IssueReport.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports by status: $e');
    }
  }

  // Get reports submitted by current user
  static Future<List<IssueReport>> getMyReports() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('issue_reports')
          .where('reporterId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => IssueReport.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get my reports: $e');
    }
  }

  // Update report status
  static Future<void> updateReportStatus(String reportId, String status, {String? resolution, String? notes}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final updateData = <String, dynamic>{
        'status': status,
        'assignedTo': currentUser.uid,
        'assignedToName': await _getCurrentUserName(),
      };

      if (status == 'resolved' || status == 'closed') {
        updateData['resolvedAt'] = DateTime.now().toIso8601String();
        if (resolution != null) updateData['resolution'] = resolution;
      }

      if (notes != null) updateData['notes'] = notes;

      await _firestore.collection('issue_reports').doc(reportId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  // Get report statistics
  static Future<Map<String, int>> getReportStatistics() async {
    try {
      final snapshot = await _firestore.collection('issue_reports').get();
      final reports = snapshot.docs.map((doc) => IssueReport.fromMap(doc.data())).toList();

      return {
        'total': reports.length,
        'pending': reports.where((r) => r.status == 'pending').length,
        'in_progress': reports.where((r) => r.status == 'in_progress').length,
        'resolved': reports.where((r) => r.status == 'resolved').length,
        'closed': reports.where((r) => r.status == 'closed').length,
        'urgent': reports.where((r) => r.priority == 'urgent').length,
        'high': reports.where((r) => r.priority == 'high').length,
      };
    } catch (e) {
      throw Exception('Failed to get report statistics: $e');
    }
  }

  // Helper method to get current user name
  static Future<String> _getCurrentUserName() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 'Unknown';

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['name'] ?? userData['fullName'] ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Notify assigned supervisor about new report
  static Future<void> _notifySupervisors(IssueReport report) async {
    try {
      // Get the reporter's supervisor
      final reporterDoc = await _firestore.collection('users').doc(report.reporterId).get();
      if (!reporterDoc.exists) {
        print('Reporter not found');
        return;
      }

      final reporterData = reporterDoc.data()!;
      final supervisorId = reporterData['supervisorId'] as String?;
      
      if (supervisorId == null) {
        print('No supervisor assigned to this cleaner');
        return;
      }

      // Send notification to the assigned supervisor
      await _firestore.collection('notifications').add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': supervisorId,
        'title': 'New Issue Report from ${report.reporterName}',
        'message': '${report.reporterName} reported: ${report.title}',
        'type': 'issue_report',
        'data': {
          'reportId': report.id,
          'reporterName': report.reporterName,
          'reporterId': report.reporterId,
          'priority': report.priority,
          'location': 'Floor ${report.floor}, Door ${report.doorNumber}',
          'toiletType': report.toiletType,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'readAt': null,
      });

      print('Notification sent to supervisor: $supervisorId');
    } catch (e) {
      print('Error notifying supervisor: $e');
    }
  }

  // Send email notification to admin
  static Future<void> _sendEmailNotification(IssueReport report) async {
    try {
      await EmailService.sendIssueReportEmail(
        reporterName: report.reporterName,
        reporterRole: report.reporterRole,
        title: report.title,
        description: report.description,
        floor: report.floor,
        doorNumber: report.doorNumber,
        toiletType: report.toiletType,
        priority: report.priority,
        imageUrl: report.imageUrl,
      );
    } catch (e) {
      print('Error sending email notification: $e');
      // Don't throw error - email failure shouldn't break the app
    }
  }
}
