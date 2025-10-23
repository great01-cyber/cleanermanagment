import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';

// Service for analytics and statistics
class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore; // Firestore database

  // Get user registration trends for the last 30 days
  static Future<List<Map<String, dynamic>>> getUserRegistrationTrends() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      // Query users created in the last 30 days
      final snapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: thirtyDaysAgo.toIso8601String())
          .orderBy('createdAt')
          .get();

      // Group registrations by date
      Map<String, int> dailyCounts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['createdAt'];
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr);
          final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
        }
      }

      // Create trend data for chart display
      List<Map<String, dynamic>> trends = [];
      for (int i = 0; i < 30; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        trends.insert(0, {
          'date': dateKey,
          'count': dailyCounts[dateKey] ?? 0,
          'day': date.day,
          'month': date.month,
        });
      }

      return trends;
    } catch (e) {
      print('Error getting user registration trends: $e');
      return [];
    }
  }

  // Get user count by role (admin, supervisor, cleaner)
  static Future<Map<String, int>> getUserActivityByRole() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      Map<String, int> roleCounts = {
        'admin': 0,
        'supervisor': 0,
        'cleaner': 0,
      };

      // Count active users by role
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] ?? 'cleaner';
        final isActive = data['isActive'] ?? true;
        
        if (isActive) {
          roleCounts[role] = (roleCounts[role] ?? 0) + 1;
        }
      }

      return roleCounts;
    } catch (e) {
      print('Error getting user activity by role: $e');
      return {'admin': 0, 'supervisor': 0, 'cleaner': 0};
    }
  }

  // Get user count by status (active/inactive)
  static Future<Map<String, int>> getUserActivityByStatus() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      int activeCount = 0;
      int inactiveCount = 0;

      // Count users by active status
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] ?? true;
        
        if (isActive) {
          activeCount++;
        } else {
          inactiveCount++;
        }
      }

      return {
        'active': activeCount,
        'inactive': inactiveCount,
      };
    } catch (e) {
      print('Error getting user activity by status: $e');
      return {'active': 0, 'inactive': 0};
    }
  }

  // Get monthly user growth data for charts
  static Future<List<Map<String, dynamic>>> getMonthlyUserGrowth() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt')
          .get();

      // Group user registrations by month
      Map<String, int> monthlyCounts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['createdAt'];
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr);
          final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
        }
      }

      // Create growth data for chart display
      List<Map<String, dynamic>> growth = [];
      for (int i = 11; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i * 30));
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        growth.add({
          'month': monthKey,
          'count': monthlyCounts[monthKey] ?? 0,
          'monthName': _getMonthName(date.month),
        });
      }

      return growth;
    } catch (e) {
      print('Error getting monthly user growth: $e');
      return [];
    }
  }

  // Get system overview statistics for dashboard
  static Future<Map<String, dynamic>> getSystemOverview() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      int totalUsers = snapshot.docs.length;
      int activeUsers = 0;
      int newUsersThisWeek = 0;
      int newUsersThisMonth = 0;

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Calculate statistics from user data
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAtStr = data['createdAt'];
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr);
          final isActive = data['isActive'] ?? true;
          
          if (isActive) activeUsers++;

          // Count new users this week
          if (createdAt.isAfter(weekAgo)) {
            newUsersThisWeek++;
          }
          // Count new users this month
          if (createdAt.isAfter(monthAgo)) {
            newUsersThisMonth++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'newUsersThisWeek': newUsersThisWeek,
        'newUsersThisMonth': newUsersThisMonth,
        'inactiveUsers': totalUsers - activeUsers,
        'activityRate': totalUsers > 0 ? (activeUsers / totalUsers * 100).toStringAsFixed(1) : '0.0',
      };
    } catch (e) {
      print('Error getting system overview: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'newUsersThisWeek': 0,
        'newUsersThisMonth': 0,
        'inactiveUsers': 0,
        'activityRate': '0.0',
      };
    }
  }

  // Helper method to get month name from number
  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1]; // Convert 1-based month to 0-based array index
  }
}
