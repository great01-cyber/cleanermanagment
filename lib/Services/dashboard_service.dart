import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';

class DashboardService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // Get total user count
  static Future<int> getTotalUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting total users: $e');
      return 0;
    }
  }

  // Get active users count
  static Future<int> getActiveUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active users: $e');
      return 0;
    }
  }

  // Get users by role
  static Future<int> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting users by role: $e');
      return 0;
    }
  }

  // Get active users by role
  static Future<int> getActiveUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active users by role: $e');
      return 0;
    }
  }

  // Get zone statistics
  static Future<Map<String, int>> getZoneStatistics() async {
    try {
      final zonesSnapshot = await _firestore.collection('zones').get();
      final totalZones = zonesSnapshot.docs.length;
      
      int activeZones = 0;
      for (var doc in zonesSnapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == true) {
          activeZones++;
        }
      }
      
      return {
        'totalZones': totalZones,
        'activeZones': activeZones,
      };
    } catch (e) {
      print('Error getting zone statistics: $e');
      return {
        'totalZones': 0,
        'activeZones': 0,
      };
    }
  }


  // Get all dashboard statistics
  static Future<Map<String, int>> getAllStatistics() async {
    try {
      final totalUsers = await getTotalUsers();
      final activeUsers = await getActiveUsers();
      final admins = await getUsersByRole('admin');
      final supervisors = await getUsersByRole('supervisor');
      final cleaners = await getUsersByRole('cleaner');
      final activeAdmins = await getActiveUsersByRole('admin');
      final activeSupervisors = await getActiveUsersByRole('supervisor');
      final activeCleaners = await getActiveUsersByRole('cleaner');
      
      final zoneStats = await getZoneStatistics();

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'admins': admins,
        'supervisors': supervisors,
        'cleaners': cleaners,
        'activeAdmins': activeAdmins,
        'activeSupervisors': activeSupervisors,
        'activeCleaners': activeCleaners,
        'totalZones': zoneStats['totalZones'] ?? 0,
        'activeZones': zoneStats['activeZones'] ?? 0,
      };
    } catch (e) {
      print('Error getting all statistics: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'admins': 0,
        'supervisors': 0,
        'cleaners': 0,
        'activeAdmins': 0,
        'activeSupervisors': 0,
        'activeCleaners': 0,
        'totalZones': 0,
        'activeZones': 0,
        'totalStores': 0,
        'activeStores': 0,
      };
    }
  }

  // Stream for real-time updates
  static Stream<Map<String, int>> getStatisticsStream() {
    return _firestore.collection('users').snapshots().asyncMap((snapshot) async {
      int totalUsers = snapshot.docs.length;
      int activeUsers = 0;
      int admins = 0;
      int supervisors = 0;
      int cleaners = 0;
      int activeAdmins = 0;
      int activeSupervisors = 0;
      int activeCleaners = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] ?? true;
        final role = data['role'] ?? '';

        if (isActive) {
          activeUsers++;
        }

        switch (role) {
          case 'admin':
            admins++;
            if (isActive) activeAdmins++;
            break;
          case 'supervisor':
            supervisors++;
            if (isActive) activeSupervisors++;
            break;
          case 'cleaner':
            cleaners++;
            if (isActive) activeCleaners++;
            break;
        }
      }

      // Get zone and store statistics
      final zoneStats = await getZoneStatistics();

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'admins': admins,
        'supervisors': supervisors,
        'cleaners': cleaners,
        'activeAdmins': activeAdmins,
        'activeSupervisors': activeSupervisors,
        'activeCleaners': activeCleaners,
        'totalZones': zoneStats['totalZones'] ?? 0,
        'activeZones': zoneStats['activeZones'] ?? 0,
      };
    });
  }
}
