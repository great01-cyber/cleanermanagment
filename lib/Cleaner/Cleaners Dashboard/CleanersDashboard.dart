
import 'package:cleanerapplication/HomePage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Services/FullMessagePage.dart';
import '../../Services/Notification.dart';
import '../Cleaners.dart';
import '../UserTrainning.dart';
import '../EnhancedUserTraining.dart';
import 'CleanerReportAccidents.dart';
import 'LeaveRequestPage.dart';
import 'QRscanning.dart';
import 'ReportsIssues.dart';
import 'SafetyRules.dart';
import 'SeeShifts.dart';
import '../SocialBoardPage.dart';
import 'StoreInventory.dart';
import 'ToDoList.dart';
import 'MyTasks.dart';
import '../../Reports/ShiftHistoryScreen.dart';
import '../../Notifications/NotificationScreen.dart';
import '../../Services/Notification.dart';
import '../../Services/notification_provider.dart' as notification_provider;

class CleanersDashboard extends StatefulWidget {
  @override
  _CleanersDashboardState createState() => _CleanersDashboardState();
}

class _CleanersDashboardState extends State<CleanersDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedFilter = 'all'; // 'all', 'task_assignment', 'shift_update', 'general'

  @override
  Widget build(BuildContext context) {
    // Initialize Firebase notifications when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<notification_provider.NotificationProvider>().initializeNotifications();
      } catch (e) {
        // Provider not available, skip initialization
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Cleaners Dashboard', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF440099),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white,),
            onPressed: () {
              // Refresh the dashboard
              setState(() {});
            },
          ),
          Consumer<notification_provider.NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, size: 30, color: Colors.white,),
                    onPressed: () {
                      _scaffoldKey.currentState!.openEndDrawer(); // Open notification drawer
                    },
                  ),
                  if (notificationProvider.notifications.isNotEmpty)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 8,
                        child: Text(
                          '${notificationProvider.notifications.length}', // Shows unread notifications count
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      drawer: _buildMainDrawer(context),
      endDrawer: _buildNotificationDrawer(),

      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        childAspectRatio: 1.5,
        children: [
          // --- Core Tasks (Blue/Indigo Family) ---
          _buildDashboardButton('My Tasks', Icons.task_alt, Colors.blue[700]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyTasks()))),
          _buildDashboardButton('See Shifts', Icons.calendar_today, Colors.blue[500]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => SeeShifts()))),
          _buildDashboardButton('To-Do List', Icons.checklist, Colors.lightBlue[600]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ToDoList()))),
          _buildDashboardButton('QR Scanning', Icons.qr_code_scanner, Colors.indigo[700]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => QrScanning()))),

// --- Logistics & Admin (Green Family) ---
          _buildDashboardButton('Store Inventory', Icons.inventory_2, Colors.green[800]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoreInventory()))),
          _buildDashboardButton('Annual Leave', Icons.event_available, Colors.green[600]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnnualRequestPage()))),

// --- History & Info (Grey/Purple Family) ---
          _buildDashboardButton('Shift History', Icons.history, Colors.grey[700]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShiftHistoryScreen()))),
          _buildDashboardButton('See Tickets', Icons.receipt_long, Colors.deepPurple[400]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => SeeTickets()))),

// --- Community & Training (Teal/Purple Family) ---
          _buildDashboardButton('Notifications', Icons.notifications, Colors.purple[500]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()))),
          _buildDashboardButton('Users Training', Icons.school, Colors.purple[300]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => EnhancedUserTraining()))),
          _buildDashboardButton('Social Board', Icons.group, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => SocialBoardPage()))),

// --- Safety & Alerts (Red/Orange Family) ---
          _buildDashboardButton('Report Accidents', Icons.warning, Colors.red[700]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => CleanerReportAccidents()))),
          _buildDashboardButton('Reports Issues', Icons.report_problem, Colors.orange[600]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsIssues()))),
          _buildDashboardButton('Safety Rules', Icons.safety_check, Colors.amber[700]!, () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyRules()))),
        ],
      ),
    );
  }


  // 🔍 Get filtered notifications based on selected filter
  List<Map<String, dynamic>> _getFilteredNotifications(List<Map<String, dynamic>> notifications) {
    if (_selectedFilter == 'all') {
      return notifications;
    }
    return notifications.where((notification) => notification['type'] == _selectedFilter).toList();
  }

  // 🏷️ Build filter chip
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.green.withOpacity(0.3),
      checkmarkColor: Colors.green,
    );
  }

  // 🎯 Get notification icon based on type
  Icon _getNotificationIcon(String? type) {
    switch (type) {
      case 'task_assignment':
        return const Icon(Icons.assignment, color: Colors.blue);
      case 'shift_assignment':
        return const Icon(Icons.schedule, color: Colors.orange);
      case 'shift_update':
        return const Icon(Icons.update, color: Colors.purple);
      case 'general':
        return const Icon(Icons.info, color: Colors.grey);
      default:
        return const Icon(Icons.notifications, color: Colors.green);
    }
  }

  // 🔷 Function to create the Main Left-Side Drawer
  Widget _buildMainDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            child: const Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
            _buildDrawerItem(Icons.assignment, 'My Tasks', () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyTasks()))),
            _buildDrawerItem(Icons.history, 'Shift History', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShiftHistoryScreen()))),
            _buildDrawerItem(Icons.notifications, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()))),
            _buildDrawerItem(Icons.inventory, 'Store Inventory', () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoreInventory()))),
          _buildDrawerItem(Icons.report_problem, 'Reports Issues', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsIssues()))),
          _buildDrawerItem(Icons.school, 'Users Training', () => Navigator.push(context, MaterialPageRoute(builder: (context) => EnhancedUserTraining()))),
          _buildDrawerItem(Icons.group, 'Social Board', () => Navigator.push(context, MaterialPageRoute(builder: (context) => SocialBoardPage()))),
          _buildDrawerItem(Icons.room, 'See Shifts', () => Navigator.push(context, MaterialPageRoute(builder: (context) => SeeShifts()))),
          _buildDrawerItem(Icons.request_page, 'Annual Leave', () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnnualRequestPage()))),
          _buildDrawerItem(Icons.qr_code, 'QR Scanning', () => Navigator.push(context, MaterialPageRoute(builder: (context) => QrScanning()))),
          _buildDrawerItem(Icons.assignment, 'See Tickets', () => Navigator.push(context, MaterialPageRoute(builder: (context) => SeeTickets()))),
          _buildDrawerItem(Icons.list, 'To-Do List', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ToDoList()))),
          _buildDrawerItem(Icons.safety_check, 'Safety Rules', () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyRules()))),
          _buildDrawerItem(Icons.safety_check, 'Report Accidents/ Slips / Incidents', () => Navigator.push(context, MaterialPageRoute(builder: (context) => CleanerReportAccidents()))),
          _buildDrawerItem(Icons.logout, 'Logout', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()))),
        ],
      ),
    );
  }

  // 🔔 Right-side notification drawer
  Widget _buildNotificationDrawer() {
    return Drawer(
      child: Consumer<notification_provider.NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.green),
                child: const Center(
                  child: Text("Notifications", style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ),
              // Filter chips
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('task_assignment', 'Tasks'),
                      const SizedBox(width: 8),
                      _buildFilterChip('shift_assignment', 'Shifts'),
                      const SizedBox(width: 8),
                      _buildFilterChip('shift_update', 'Updates'),
                      const SizedBox(width: 8),
                      _buildFilterChip('general', 'General'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _getFilteredNotifications(notificationProvider.notifications).isNotEmpty
                    ? ListView.builder(
                  itemCount: _getFilteredNotifications(notificationProvider.notifications).length,
                  itemBuilder: (context, index) {
                    final notification = _getFilteredNotifications(notificationProvider.notifications)[index];
                    return ListTile(
                      leading: _getNotificationIcon(notification['type']),
                      title: Text(
                        notification['title'] ?? 'No Title',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        notification['body'] ?? notification['message'] ?? 'No content',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        // Navigate to FullMessagePage when a notification is clicked
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullMessagePage(
                              message: notification['message'] ?? notification['body'] ?? 'No content',
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
                    : const Center(child: Text("No new notifications")),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFullMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Full Message"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // Helper function to create drawer list items
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  // 🔷 Function to create dashboard buttons
  Widget _buildDashboardButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0), color: color),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}
