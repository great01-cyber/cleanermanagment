import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';

class UserAuthService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Login for cleaners and supervisors
  static Future<UserCredential?> login(String email, String password, String requiredRole) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user role
      final userRole = await _getUserRole(credential.user!.uid);
      if (userRole != requiredRole) {
        await _auth.signOut();
        throw Exception('Access denied. ${requiredRole.capitalize()} privileges required.');
      }

      // Check if user is active
      final userData = await _getUserData(credential.user!.uid);
      if (userData != null && !userData['isActive']) {
        await _auth.signOut();
        throw Exception('Account has been deactivated. Please contact administrator.');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Get user role from Firestore
  static Future<String?> _getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get current user's role
  static Future<String?> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) return null;
    return await _getUserRole(user.uid);
  }

  // Get current user's data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    return await _getUserData(user.uid);
  }

  // Check if user is cleaner
  static Future<bool> isCleaner() async {
    final role = await getCurrentUserRole();
    return role == 'cleaner';
  }

  // Check if user is supervisor
  static Future<bool> isSupervisor() async {
    final role = await getCurrentUserRole();
    return role == 'supervisor';
  }

  // Check if user is admin
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
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

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
