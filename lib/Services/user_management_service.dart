import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';

// Service for managing users (supervisors and cleaners)
class UserManagementService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;        // Firebase Auth instance
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore; // Firestore database

  // Create a new supervisor account
  static Future<SupervisorModel> createSupervisor({
    required String email,
    required String password,
    required String name,
    required Zone assignedZone,
  }) async {
    try {
      // Create user account in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Create supervisor profile in Firestore
      final supervisor = SupervisorModel(
        uid: user.uid,
        email: email,
        name: name,
        assignedZone: assignedZone,
        createdAt: DateTime.now(),
      );

      // Save supervisor data to database
      await _firestore.collection('users').doc(user.uid).set(supervisor.toMap());

      return supervisor;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Supervisor creation failed: $e');
    }
  }

  // Create a new cleaner account
  static Future<CleanerModel> createCleaner({
    required String email,
    required String password,
    required String name,
    required String supervisorId,
    required String supervisorName,
  }) async {
    try {
      // Create user account in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Create cleaner profile in Firestore
      final cleaner = CleanerModel(
        uid: user.uid,
        email: email,
        name: name,
        supervisorId: supervisorId,
        supervisorName: supervisorName,
        createdAt: DateTime.now(),
      );

      // Save cleaner data to database
      await _firestore.collection('users').doc(user.uid).set(cleaner.toMap());

      // Add cleaner to supervisor's assigned list
      await _updateSupervisorCleaners(supervisorId, user.uid, true);

      return cleaner;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Cleaner creation failed: $e');
    }
  }

  // Get all supervisors
  static Future<List<SupervisorModel>> getAllSupervisors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'supervisor')
          .get();
      
      return snapshot.docs
          .map((doc) => SupervisorModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting supervisors: $e');
      return [];
    }
  }

  // Get all cleaners
  static Future<List<CleanerModel>> getAllCleaners() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'cleaner')
          .get();
      
      return snapshot.docs
          .map((doc) => CleanerModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting cleaners: $e');
      return [];
    }
  }

  // Get cleaners by supervisor
  static Future<List<CleanerModel>> getCleanersBySupervisor(String supervisorId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'cleaner')
          .where('supervisorId', isEqualTo: supervisorId)
          .get();
      
      return snapshot.docs
          .map((doc) => CleanerModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting cleaners by supervisor: $e');
      return [];
    }
  }

  // Get supervisor by ID
  static Future<SupervisorModel?> getSupervisorById(String supervisorId) async {
    try {
      final doc = await _firestore.collection('users').doc(supervisorId).get();
      if (doc.exists) {
        return SupervisorModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting supervisor by ID: $e');
      return null;
    }
  }

  // Update supervisor's assigned cleaners
  static Future<void> _updateSupervisorCleaners(String supervisorId, String cleanerId, bool add) async {
    try {
      final supervisorRef = _firestore.collection('users').doc(supervisorId);
      final supervisorDoc = await supervisorRef.get();
      
      if (supervisorDoc.exists) {
        final supervisorData = supervisorDoc.data()!;
        List<String> assignedCleaners = List<String>.from(supervisorData['assignedCleaners'] ?? []);
        
        if (add) {
          if (!assignedCleaners.contains(cleanerId)) {
            assignedCleaners.add(cleanerId);
          }
        } else {
          assignedCleaners.remove(cleanerId);
        }
        
        await supervisorRef.update({'assignedCleaners': assignedCleaners});
      }
    } catch (e) {
      print('Error updating supervisor cleaners: $e');
    }
  }

  // Assign cleaner to supervisor
  static Future<void> assignCleanerToSupervisor(String cleanerId, String newSupervisorId, String newSupervisorName) async {
    try {
      // Get current cleaner data
      final cleanerRef = _firestore.collection('users').doc(cleanerId);
      final cleanerDoc = await cleanerRef.get();
      
      if (cleanerDoc.exists) {
        final cleanerData = cleanerDoc.data()!;
        final oldSupervisorId = cleanerData['supervisorId'];
        
        // Update cleaner's supervisor
        await cleanerRef.update({
          'supervisorId': newSupervisorId,
          'supervisorName': newSupervisorName,
        });
        
        // Remove from old supervisor's list
        if (oldSupervisorId != null) {
          await _updateSupervisorCleaners(oldSupervisorId, cleanerId, false);
        }
        
        // Add to new supervisor's list
        await _updateSupervisorCleaners(newSupervisorId, cleanerId, true);
      }
    } catch (e) {
      print('Error assigning cleaner to supervisor: $e');
      throw Exception('Failed to assign cleaner to supervisor: $e');
    }
  }

  // Update supervisor zone
  static Future<void> updateSupervisorZone(String supervisorId, Zone newZone) async {
    try {
      await _firestore.collection('users').doc(supervisorId).update({
        'assignedZone': newZone.name,
      });
    } catch (e) {
      print('Error updating supervisor zone: $e');
      throw Exception('Failed to update supervisor zone: $e');
    }
  }

  // Delete user (supervisor or cleaner)
  static Future<void> deleteUser(String userId) async {
    try {
      // Get user data first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final role = userData['role'];
        
        if (role == 'supervisor') {
          // If deleting supervisor, reassign cleaners to unassigned
          final assignedCleaners = List<String>.from(userData['assignedCleaners'] ?? []);
          for (String cleanerId in assignedCleaners) {
            await _firestore.collection('users').doc(cleanerId).update({
              'supervisorId': '',
              'supervisorName': 'Unassigned',
            });
          }
        } else if (role == 'cleaner') {
          // If deleting cleaner, remove from supervisor's list
          final supervisorId = userData['supervisorId'];
          if (supervisorId != null && supervisorId.isNotEmpty) {
            await _updateSupervisorCleaners(supervisorId, userId, false);
          }
        }
      }
      
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Get zone statistics
  static Future<Map<String, dynamic>> getZoneStatistics() async {
    try {
      final supervisors = await getAllSupervisors();
      final cleaners = await getAllCleaners();
      
      Map<String, dynamic> zoneStats = {};
      
      for (Zone zone in Zone.values) {
        final zoneSupervisors = supervisors.where((s) => s.assignedZone == zone).toList();
        final zoneCleaners = cleaners.where((c) {
          final supervisor = supervisors.firstWhere(
            (s) => s.uid == c.supervisorId,
            orElse: () => SupervisorModel(
              uid: '',
              email: '',
              name: '',
              assignedZone: zone,
              createdAt: DateTime.now(),
            ),
          );
          return supervisor.assignedZone == zone;
        }).toList();
        
        zoneStats[zone.name] = {
          'supervisors': zoneSupervisors.length,
          'cleaners': zoneCleaners.length,
          'total': zoneSupervisors.length + zoneCleaners.length,
        };
      }
      
      return zoneStats;
    } catch (e) {
      print('Error getting zone statistics: $e');
      return {};
    }
  }

  // Helper method for auth error messages
  static String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
