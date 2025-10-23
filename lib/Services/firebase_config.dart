import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';

// Firebase configuration and service access
class FirebaseConfig {
  // Get Firebase Auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;
  // Get Firestore database instance
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  // Get Firebase Storage instance
  static FirebaseStorage get storage => FirebaseStorage.instance;

  // Initialize Firebase with platform-specific options
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

// User roles for the application
enum UserRole {
  admin,      // System administrator
  supervisor, // Zone supervisor
  cleaner,    // Cleaning staff
}

// Zone definitions for supervisor assignments
enum Zone {
  zoneA('Zone A - Building 1, Floors 1-5'),
  zoneB('Zone B - Building 2, Floors 1-3'),
  zoneC('Zone C - Building 3, Floors 1-4'),
  zoneD('Zone D - Outdoor Areas'),
  zoneE('Zone E - Common Areas');

  const Zone(this.description);
  final String description; // Human-readable zone description
}

// Supervisor data model
class SupervisorModel {
  final String uid;                    // Unique user ID
  final String email;                 // Supervisor email
  final String name;                  // Supervisor full name
  final Zone assignedZone;            // Zone they supervise
  final DateTime createdAt;          // Account creation date
  final bool isActive;                // Account status
  final String? profileImageUrl;      // Profile picture URL
  final List<String> assignedCleaners; // List of cleaner IDs under this supervisor

  SupervisorModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.assignedZone,
    required this.createdAt,
    this.isActive = true,
    this.profileImageUrl,
    this.assignedCleaners = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': 'supervisor',
      'assignedZone': assignedZone.name,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'assignedCleaners': assignedCleaners,
    };
  }

  factory SupervisorModel.fromMap(Map<String, dynamic> map) {
    return SupervisorModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      assignedZone: Zone.values.firstWhere(
        (e) => e.name == map['assignedZone'],
        orElse: () => Zone.zoneA,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'],
      assignedCleaners: List<String>.from(map['assignedCleaners'] ?? []),
    );
  }
}

// Cleaner data model
class CleanerModel {
  final String uid;              // Unique user ID
  final String email;             // Cleaner email
  final String name;              // Cleaner full name
  final String supervisorId;       // ID of assigned supervisor
  final String supervisorName;    // Name of assigned supervisor
  final DateTime createdAt;       // Account creation date
  final bool isActive;             // Account status
  final String? profileImageUrl;   // Profile picture URL

  CleanerModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.supervisorId,
    required this.supervisorName,
    required this.createdAt,
    this.isActive = true,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': 'cleaner',
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory CleanerModel.fromMap(Map<String, dynamic> map) {
    return CleanerModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      supervisorId: map['supervisorId'] ?? '',
      supervisorName: map['supervisorName'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'],
    );
  }
}

// General user model (backward compatibility)
class UserModel {
  final String uid;                    // Unique user ID
  final String email;                  // User email
  final String name;                   // User full name
  final UserRole role;                 // User role (admin/supervisor/cleaner)
  final DateTime createdAt;            // Account creation date
  final bool isActive;                 // Account status
  final String? profileImageUrl;       // Profile picture URL
  final String? supervisorId;          // Supervisor ID (for cleaners)
  final String? supervisorName;        // Supervisor name (for cleaners)
  final Zone? assignedZone;            // Assigned zone (for supervisors)
  final List<String>? assignedCleaners; // Assigned cleaners (for supervisors)

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.profileImageUrl,
    this.supervisorId,
    this.supervisorName,
    this.assignedZone,
    this.assignedCleaners,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'assignedZone': assignedZone?.name,
      'assignedCleaners': assignedCleaners,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.cleaner,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'],
      supervisorId: map['supervisorId'],
      supervisorName: map['supervisorName'],
      assignedZone: map['assignedZone'] != null 
          ? Zone.values.firstWhere(
              (e) => e.name == map['assignedZone'],
              orElse: () => Zone.zoneA,
            )
          : null,
      assignedCleaners: map['assignedCleaners'] != null 
          ? List<String>.from(map['assignedCleaners'])
          : null,
    );
  }
}
