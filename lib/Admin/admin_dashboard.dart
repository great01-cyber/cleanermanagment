import 'package:flutter/material.dart';
import '../Services/admin_auth_service.dart';
import '../Services/dashboard_service.dart';
import 'user_management_screen.dart';
import 'supervisor_management_screen.dart';
import 'cleaner_management_screen.dart';
import 'admin_login_screen.dart';
import 'analytics_dashboard.dart';
import 'zone_management_screen.dart';
import 'admin_store_oversight_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_video_management_screen.dart';
import '../Services/video_migration_service.dart';

// Main admin dashboard with navigation tabs
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;        // Current tab index
  bool _isLoading = true;        // Loading state
  bool _isAdmin = false;         // Admin authentication status
  Map<String, int> _statistics = {  // Dashboard statistics
    'totalUsers': 0,
    'activeUsers': 0,
    'admins': 0,
    'supervisors': 0,
    'cleaners': 0,
        'totalZones': 0,
        'activeZones': 0,
  };

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();      // Verify admin access
    _loadStatistics();        // Load initial data
    _setupRealtimeUpdates();  // Setup live updates
    _migrateVideosIfNeeded();  // Migrate videos from JSON to Firebase
  }

  // Setup real-time statistics updates
  void _setupRealtimeUpdates() {
    DashboardService.getStatisticsStream().listen((stats) {
      if (mounted) {
        setState(() {
          _statistics = stats;
        });
      }
    });
  }

  // Check if current user is admin
  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminAuthService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  // Load dashboard statistics
  Future<void> _loadStatistics() async {
    try {
      final stats = await DashboardService.getAllStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdmin) {
      return const AdminLoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AdminAuthService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const AdminLoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Zones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Store Management',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_library),
          label: 'Training Videos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildUserManagement();
        case 2:
          return const ZoneManagementScreen();
        case 3:
          return const AdminStoreOversightScreen();
        case 4:
          return _buildAnalytics();
        case 5:
          return const AdminVideoManagementScreen();
        case 6:
          return const AdminSettingsScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildUserManagement() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: [
              Tab(text: 'All Users', icon: Icon(Icons.people)),
              Tab(text: 'Supervisors', icon: Icon(Icons.supervisor_account)),
              Tab(text: 'Cleaners', icon: Icon(Icons.cleaning_services)),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                UserManagementScreen(),
                SupervisorManagementScreen(),
                CleanerManagementScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time user statistics and system overview',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Users',
                  '${_statistics['totalUsers'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                  () => _navigateToUsers(),
                ),
                _buildStatCard(
                  'Active Users',
                  '${_statistics['activeUsers'] ?? 0}',
                  Icons.people_alt,
                  Colors.green,
                  () => _navigateToUsers(),
                ),
                _buildStatCard(
                  'Supervisors',
                  '${_statistics['supervisors'] ?? 0}',
                  Icons.supervisor_account,
                  Colors.blue,
                  () => _navigateToUsers(),
                ),
                _buildStatCard(
                  'Cleaners',
                  '${_statistics['cleaners'] ?? 0}',
                  Icons.cleaning_services,
                  Colors.orange,
                  () => _navigateToUsers(),
                ),
                _buildStatCard(
                  'Total Zones',
                  '${_statistics['totalZones'] ?? 0}',
                  Icons.location_on,
                  Colors.purple,
                  () => _navigateToZones(),
                ),
                _buildStatCard(
                  'Active Zones',
                  '${_statistics['activeZones'] ?? 0}',
                  Icons.location_city,
                  Colors.teal,
                  () => _navigateToZones(),
                ),
                _buildStatCard(
                  'Total Stores',
                  '${_statistics['totalStores'] ?? 0}',
                  Icons.store,
                  Colors.indigo,
                  () => _navigateToStores(),
                ),
                _buildStatCard(
                  'Active Stores',
                  '${_statistics['activeStores'] ?? 0}',
                  Icons.storefront,
                  Colors.amber,
                  () => _navigateToStores(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      VoidCallback onTap) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalytics() {
    return const AnalyticsDashboard();
  }


  void _navigateToUsers() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _navigateToZones() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _navigateToStores() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  // Migrate videos from JSON to Firebase if needed
  Future<void> _migrateVideosIfNeeded() async {
    try {
      await VideoMigrationService.checkAndMigrate();
    } catch (e) {
      print('Video migration failed: $e');
    }
  }
}
