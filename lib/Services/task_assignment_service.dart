import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_config.dart';
import 'supervisor_service.dart';
import 'notification_service.dart';

// Task assignment data model
class TaskAssignment {
  final String id;
  final String supervisorId;
  final String supervisorName;
  final String cleanerId;
  final String cleanerName;
  final String title;
  final String description;
  final String location;
  final DateTime assignedDate;
  final DateTime dueDate;
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final DateTime? completedAt;
  final String? notes;

  TaskAssignment({
    required this.id,
    required this.supervisorId,
    required this.supervisorName,
    required this.cleanerId,
    required this.cleanerName,
    required this.title,
    required this.description,
    required this.location,
    required this.assignedDate,
    required this.dueDate,
    this.status = 'pending',
    this.completedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'title': title,
      'description': description,
      'location': location,
      'assignedDate': assignedDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory TaskAssignment.fromMap(Map<String, dynamic> map) {
    return TaskAssignment(
      id: map['id'] ?? '',
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
      cleanerId: map['cleanerId'] ?? '',
      cleanerName: map['cleanerName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      assignedDate: DateTime.parse(map['assignedDate'] ?? DateTime.now().toIso8601String()),
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'pending',
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      notes: map['notes'],
    );
  }
}

// Service for task assignment operations
class TaskAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore; // Firestore database
  static final FirebaseAuth _auth = FirebaseConfig.auth; // Firebase Auth instance

  // Assign task to cleaner
  static Future<void> assignTask({
    required String cleanerName,
    required String title,
    required String description,
    required String location,
    required DateTime dueDate,
    String? notes,
  }) async {
    try {
      // Get current supervisor info
      final supervisor = await SupervisorService.getCurrentSupervisor();
      if (supervisor == null) {
        throw Exception('Supervisor not found');
      }

      // Get cleaner info
      final cleaner = await SupervisorService.getCleanerByName(cleanerName);
      if (cleaner == null) {
        throw Exception('Cleaner not found');
      }

      // Create task assignment
      final taskId = _firestore.collection('tasks').doc().id;
      final task = TaskAssignment(
        id: taskId,
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

      // Save to Firestore
      await _firestore.collection('tasks').doc(taskId).set(task.toMap());

      // Send notification to cleaner
      await NotificationService.sendTaskNotification(
        cleanerId: cleaner.uid,
        taskTitle: title,
        supervisorName: supervisor.name,
        taskId: taskId,
      );

    } catch (e) {
      throw Exception('Failed to assign task: $e');
    }
  }

  // Get tasks assigned by current supervisor
  static Future<List<TaskAssignment>> getMyAssignedTasks() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('tasks')
          .where('supervisorId', isEqualTo: currentUser.uid)
          .get();

      final tasks = snapshot.docs
          .map((doc) => TaskAssignment.fromMap(doc.data()))
          .toList();
          
      // Sort by assigned date in descending order (newest first)
      tasks.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
      
      return tasks;
    } catch (e) {
      return [];
    }
  }

  // Get tasks assigned to current cleaner
  static Future<List<TaskAssignment>> getMyTasks() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('tasks')
          .where('cleanerId', isEqualTo: currentUser.uid)
          .get();

      final tasks = snapshot.docs
          .map((doc) => TaskAssignment.fromMap(doc.data()))
          .toList();
          
      // Sort by assigned date in descending order (newest first)
      tasks.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
      
      return tasks;
    } catch (e) {
      return [];
    }
  }

  // Update task status
  static Future<void> updateTaskStatus(String taskId, String status, {String? notes}) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (status == 'completed') {
        updates['completedAt'] = DateTime.now().toIso8601String();
      }

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _firestore.collection('tasks').doc(taskId).update(updates);
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }


  // Get task statistics for supervisor
  static Future<Map<String, int>> getTaskStatistics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('tasks')
          .where('supervisorId', isEqualTo: currentUser.uid)
          .get();

      int totalTasks = snapshot.docs.length;
      int pendingTasks = 0;
      int inProgressTasks = 0;
      int completedTasks = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        
        switch (status) {
          case 'pending':
            pendingTasks++;
            break;
          case 'in_progress':
            inProgressTasks++;
            break;
          case 'completed':
            completedTasks++;
            break;
        }
      }

      return {
        'total': totalTasks,
        'pending': pendingTasks,
        'in_progress': inProgressTasks,
        'completed': completedTasks,
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
