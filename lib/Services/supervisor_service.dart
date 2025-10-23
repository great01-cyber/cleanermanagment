import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';
import 'user_management_service.dart';

// Service for supervisor-specific operations and team management
class SupervisorService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;        // Firebase Auth instance
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore; // Firestore database

  // Get current supervisor's assigned cleaners from Firebase
  static Future<List<CleanerModel>> getMyAssignedCleaners() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get cleaners assigned to current supervisor
      final cleaners = await UserManagementService.getCleanersBySupervisor(currentUser.uid);
      return cleaners;
    } catch (e) {
      print('Error getting assigned cleaners: $e');
      return [];
    }
  }

  // Get current supervisor's information from Firebase
  static Future<SupervisorModel?> getCurrentSupervisor() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get supervisor data from Firestore
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        return SupervisorModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting current supervisor: $e');
      return null;
    }
  }

  // Get cleaner names for dropdown UI (simplified list)
  static Future<List<String>> getCleanerNames() async {
    try {
      final cleaners = await getMyAssignedCleaners();
      return cleaners.map((cleaner) => cleaner.name).toList();
    } catch (e) {
      print('Error getting cleaner names: $e');
      return [];
    }
  }

  // Get cleaner by name for task assignment
  static Future<CleanerModel?> getCleanerByName(String name) async {
    try {
      final cleaners = await getMyAssignedCleaners();
      return cleaners.firstWhere(
        (cleaner) => cleaner.name == name,
        orElse: () => throw Exception('Cleaner not found'),
      );
    } catch (e) {
      print('Error getting cleaner by name: $e');
      return null;
    }
  }

  // Check if current user has supervisor role
  static Future<bool> isSupervisor() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check user role in Firestore
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        final userData = doc.data()!;
        return userData['role'] == 'supervisor';
      }
      return false;
    } catch (e) {
      print('Error checking supervisor status: $e');
      return false;
    }
  }
}
