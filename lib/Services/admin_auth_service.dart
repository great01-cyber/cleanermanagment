import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';

// Service for admin authentication and user management
class AdminAuthService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;        // Firebase Auth instance
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore; // Firestore database

  // Get current authenticated user
  static User? get currentUser => _auth.currentUser;

  // Check if current user has admin role
  static Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false; // No user logged in

    try {
      // Check user role in Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final userData = doc.data()!;
        return userData['role'] == 'admin'; // Verify admin role
      }
      return false; // User document doesn't exist
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Admin login with role verification
  static Future<UserCredential?> adminLogin(String email, String password) async {
    try {
      // Authenticate user with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user has admin role
      final isAdminUser = await isAdmin();
      if (!isAdminUser) {
        await _auth.signOut(); // Sign out if not admin
        throw Exception('Access denied. Admin privileges required.');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Create new user (admin function)
  static Future<UserModel> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Create user document in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('User creation failed: $e');
    }
  }

  // Get all users (admin function)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Update user (admin function)
  static Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user (admin function)
  static Future<void> deleteUser(String uid) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();
      
      // Note: Deleting from Firebase Auth requires admin privileges
      // This would typically be done through Firebase Admin SDK on the server
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Toggle user active status
  static Future<void> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
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
