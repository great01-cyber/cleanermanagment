import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_config.dart';
import 'task_assignment_service.dart';

// Enhanced shift management service with advanced features
class ShiftManagementService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // Edit an existing shift
  static Future<void> editShift({
    required String shiftId,
    String? title,
    String? description,
    String? location,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final updates = <String, dynamic>{};
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (location != null) updates['location'] = location;
      if (dueDate != null) updates['dueDate'] = dueDate.toIso8601String();
      if (notes != null) updates['notes'] = notes;
      
      updates['lastModified'] = DateTime.now().toIso8601String();
      updates['modifiedBy'] = currentUser.uid;

      await _firestore.collection('tasks').doc(shiftId).update(updates);
    } catch (e) {
      throw Exception('Failed to edit shift: $e');
    }
  }

  // Cancel a shift
  static Future<void> cancelShift(String shiftId, String reason) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      await _firestore.collection('tasks').doc(shiftId).update({
        'status': 'cancelled',
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancelledBy': currentUser.uid,
        'cancellationReason': reason,
        'lastModified': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to cancel shift: $e');
    }
  }

  // Reschedule a shift
  static Future<void> rescheduleShift({
    required String shiftId,
    required DateTime newDueDate,
    String? reason,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      await _firestore.collection('tasks').doc(shiftId).update({
        'dueDate': newDueDate.toIso8601String(),
        'status': 'pending', // Reset to pending when rescheduled
        'rescheduledAt': DateTime.now().toIso8601String(),
        'rescheduledBy': currentUser.uid,
        'rescheduleReason': reason,
        'lastModified': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to reschedule shift: $e');
    }
  }

  // Get shift history for a cleaner
  static Future<List<TaskAssignment>> getShiftHistory(String cleanerId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('cleanerId', isEqualTo: cleanerId)
          .get();

      final tasks = snapshot.docs
          .map((doc) => TaskAssignment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter only shift assignments and sort by date
      final shifts = tasks.where((task) => 
        task.title.toLowerCase().contains('shift') || 
        task.notes == 'Shift assignment'
      ).toList();

      shifts.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
      
      return shifts;
    } catch (e) {
      throw Exception('Failed to get shift history: $e');
    }
  }

  // Get shift statistics for a cleaner
  static Future<Map<String, dynamic>> getShiftStatistics(String cleanerId) async {
    try {
      final shifts = await getShiftHistory(cleanerId);
      
      int totalShifts = shifts.length;
      int completedShifts = shifts.where((s) => s.status == 'completed').length;
      int pendingShifts = shifts.where((s) => s.status == 'pending').length;
      int inProgressShifts = shifts.where((s) => s.status == 'in_progress').length;
      int cancelledShifts = shifts.where((s) => s.status == 'cancelled').length;
      
      // Calculate completion rate
      double completionRate = totalShifts > 0 ? (completedShifts / totalShifts) * 100 : 0.0;
      
      // Get recent activity (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      int recentShifts = shifts.where((s) => s.assignedDate.isAfter(thirtyDaysAgo)).length;
      
      return {
        'totalShifts': totalShifts,
        'completedShifts': completedShifts,
        'pendingShifts': pendingShifts,
        'inProgressShifts': inProgressShifts,
        'cancelledShifts': cancelledShifts,
        'completionRate': completionRate,
        'recentShifts': recentShifts,
      };
    } catch (e) {
      throw Exception('Failed to get shift statistics: $e');
    }
  }

  // Get shifts by date range
  static Future<List<TaskAssignment>> getShiftsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? cleanerId,
  }) async {
    try {
      Query query = _firestore.collection('tasks');
      
      if (cleanerId != null) {
        query = query.where('cleanerId', isEqualTo: cleanerId);
      }
      
      final snapshot = await query.get();
      
      final tasks = snapshot.docs
          .map((doc) => TaskAssignment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter shifts and date range
      final shifts = tasks.where((task) {
        final isShift = task.title.toLowerCase().contains('shift') || 
                       task.notes == 'Shift assignment';
        final inDateRange = task.assignedDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                           task.assignedDate.isBefore(endDate.add(const Duration(days: 1)));
        return isShift && inDateRange;
      }).toList();

      shifts.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
      
      return shifts;
    } catch (e) {
      throw Exception('Failed to get shifts by date range: $e');
    }
  }

  // Bulk operations
  static Future<void> bulkUpdateShiftStatus(List<String> shiftIds, String status) async {
    try {
      final batch = _firestore.batch();
      
      for (String shiftId in shiftIds) {
        final shiftRef = _firestore.collection('tasks').doc(shiftId);
        batch.update(shiftRef, {
          'status': status,
          'lastModified': DateTime.now().toIso8601String(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update shifts: $e');
    }
  }

  // Get overdue shifts
  static Future<List<TaskAssignment>> getOverdueShifts() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('tasks')
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      final tasks = snapshot.docs
          .map((doc) => TaskAssignment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter overdue shifts
      final overdueShifts = tasks.where((task) {
        final isShift = task.title.toLowerCase().contains('shift') || 
                       task.notes == 'Shift assignment';
        final isOverdue = task.dueDate.isBefore(now);
        return isShift && isOverdue;
      }).toList();

      overdueShifts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      
      return overdueShifts;
    } catch (e) {
      throw Exception('Failed to get overdue shifts: $e');
    }
  }
}
