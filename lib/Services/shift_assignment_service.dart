import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_config.dart';
import 'notification_service.dart';
import 'user_management_service.dart';

// Data model for a shift assignment
class ShiftAssignment {
  final String id;
  final String title;
  final String description;
  final String location;
  final String cleanerId;
  final String cleanerName;
  final String supervisorId;
  final String supervisorName;
  final DateTime assignedDate;
  final DateTime dueDate;
  String status; // pending, in_progress, completed, cancelled
  final String? notes;
  DateTime? completedAt;

  ShiftAssignment({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.cleanerId,
    required this.cleanerName,
    required this.supervisorId,
    required this.supervisorName,
    required this.assignedDate,
    required this.dueDate,
    this.status = 'pending',
    this.notes,
    this.completedAt,
  });

  // Convert ShiftAssignment object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'assignedDate': assignedDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Create ShiftAssignment object from a Firestore Map
  factory ShiftAssignment.fromMap(Map<String, dynamic> map) {
    return ShiftAssignment(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      cleanerId: map['cleanerId'] ?? '',
      cleanerName: map['cleanerName'] ?? '',
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
      assignedDate: DateTime.parse(map['assignedDate'] ?? DateTime.now().toIso8601String()),
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }
}

// Service for assigning and managing shifts
class ShiftAssignmentService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // Assign a new shift to a cleaner
  static Future<void> assignShift({
    required String cleanerName,
    required String title,
    required String description,
    required String location,
    required DateTime dueDate,
    String? notes,
  }) async {
    try {
      // Get current supervisor info
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get supervisor data
      final supervisorDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!supervisorDoc.exists) {
        throw Exception('Supervisor not found');
      }
      final supervisor = SupervisorModel.fromMap(supervisorDoc.data()!);

      // Get cleaner info
      final cleaners = await UserManagementService.getCleanersBySupervisor(currentUser.uid);
      final cleaner = cleaners.where((c) => c.name == cleanerName).firstOrNull;
      if (cleaner == null) {
        throw Exception('Cleaner "$cleanerName" not found or not assigned to you');
      }

      // Create shift assignment
      final shiftId = _firestore.collection('shifts').doc().id;
      final shift = ShiftAssignment(
        id: shiftId,
        supervisorId: supervisor.uid,
        supervisorName: supervisor.name,
        cleanerId: cleaner.uid,
        cleanerName: cleaner.name,
        title: title,
        description: description,
        location: location,
        assignedDate: DateTime.now(),
        dueDate: dueDate,
        notes: notes,
      );

      // Save to Firestore in 'shifts' collection
      await _firestore.collection('shifts').doc(shiftId).set(shift.toMap());

      // Send shift notification to cleaner
      await NotificationService.sendShiftNotification(
        cleanerId: cleaner.uid,
        shiftTitle: title,
        supervisorName: supervisor.name,
        shiftId: shiftId,
        dueDate: dueDate,
      );

    } catch (e) {
      throw Exception('Failed to assign shift: $e');
    }
  }

  // Get shifts assigned by current supervisor
  static Future<List<ShiftAssignment>> getMyAssignedShifts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('shifts')
          .where('supervisorId', isEqualTo: currentUser.uid)
          .get();

      final shifts = snapshot.docs
          .map((doc) => ShiftAssignment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by assigned date in descending order (newest first)
      shifts.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));

      return shifts;
    } catch (e) {
      return [];
    }
  }

  // Get shifts assigned to current cleaner
  static Future<List<ShiftAssignment>> getMyShifts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('shifts')
          .where('cleanerId', isEqualTo: currentUser.uid)
          .get();

      final shifts = snapshot.docs
          .map((doc) => ShiftAssignment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by assigned date in descending order (newest first)
      shifts.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));

      return shifts;
    } catch (e) {
      return [];
    }
  }

  // Update shift status
  static Future<void> updateShiftStatus(String shiftId, String status, {String? notes}) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (status == 'completed') {
        updates['completedAt'] = DateTime.now().toIso8601String();
      } else {
        updates['completedAt'] = null; // Clear if not completed
      }

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _firestore.collection('shifts').doc(shiftId).update(updates);
    } catch (e) {
      throw Exception('Failed to update shift status: $e');
    }
  }

  // Get shift statistics for supervisor
  static Future<Map<String, int>> getShiftStatistics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('shifts')
          .where('supervisorId', isEqualTo: currentUser.uid)
          .get();

      int totalShifts = snapshot.docs.length;
      int pendingShifts = 0;
      int inProgressShifts = 0;
      int completedShifts = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        switch (data['status']) {
          case 'pending':
            pendingShifts++;
            break;
          case 'in_progress':
            inProgressShifts++;
            break;
          case 'completed':
            completedShifts++;
            break;
        }
      }

      return {
        'total': totalShifts,
        'pending': pendingShifts,
        'in_progress': inProgressShifts,
        'completed': completedShifts,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
      };
    }
  }
}
