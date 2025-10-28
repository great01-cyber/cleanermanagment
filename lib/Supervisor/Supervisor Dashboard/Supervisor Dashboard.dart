import 'package:cleanerapplication/Supervisor/Supervisor%20Dashboard/supervisorTodolist.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- ADDED: Missing import

import '../../Cleaner/Cleaners Dashboard/CleanerReportAccidents.dart';
import '../../CreateVoucher.dart';
import '../../HomePage.dart';
import '../../Services/CreateNotification.dart';
import '../../Services/Notification.dart' as notification_provider;
import '../ReportsIssues.dart';
import '../statistics.dart';
import 'AssignTask.dart';
import 'OrderSuppliesPage.dart';
import 'PostMessage.dart' hide StatisticsPage;
import 'PostShifts.dart';
import 'StoreInventoryPage.dart';
import '../ShiftManagement/ShiftManagementScreen.dart';
import 'SupervisorApprovalPage.dart';


class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Supervisor Dashboard', style: TextStyle(
          color: Colors.white
        ),),
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
                      _scaffoldKey.currentState!.openEndDrawer();
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


      drawer: _buildDrawer(context),


      endDrawer: _buildNotificationDrawer(),


      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        childAspectRatio: 1.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,

        children: _buildDashboardButtons(context),
      ),
    );
  }



  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF440099)),
            child: Center(
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildDrawerItems(context),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNotificationDrawer() {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Notifications'),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.green,
          ),
          // TODO: Build your notification list here
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Notification list goes here...'),
            ),
          ),
        ],
      ),
    );
  }


  List<Widget> _buildDrawerItems(BuildContext context) {
    return [
      _buildDrawerTile(context, 'Post Shifts', Icons.post_add, PostShifts()),
      _buildDrawerTile(context, 'Assign Tasks', Icons.assignment_ind, AssignTasks()),
      _buildDrawerTile(context, 'My Todo List', Icons.checklist, supervisorTodolist()), // <-- FIXED: Corrected page
      _buildDrawerTile(context, 'Annual Leave Request', Icons.event_available, SupervisorApprovalPage()),
      _buildDrawerTile(context, 'Post Message', Icons.message, StatisticsPage()),
      _buildDrawerTile(context, 'Create Notification', Icons.notifications, CreateNotification()),
      _buildDrawerTile(context, 'Store Inventory', Icons.store, StoreInventoryPage()),
      _buildDrawerTile(context, 'Create Vouchers', Icons.card_giftcard, CreateVouchers()),
      _buildDrawerTile(context, 'Reports', Icons.assessment, ReportsIssuesS()),
      _buildDrawerTile(context, 'Report Accidents', Icons.warning, CleanerReportAccidents()),
      _buildDrawerTile(context, 'Emergency', Icons.emergency, AssignTasks()),
      _buildDrawerTile(context, 'Emergency', Icons.emergency, StatisticsPage()),// <-- FIXED: Corrected page
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        onTap: () {
          // Use pushReplacement to prevent user from going back to this screen
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        },
      ),
    ];
  }

  Widget _buildDrawerTile(BuildContext context, String title, IconData icon, Widget page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF440099)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }

  List<Widget> _buildDashboardButtons(BuildContext context) {
    return [

      _buildDashboardButton(context, 'Shift Management', Icons.schedule, Colors.indigo, ShiftManagementScreen()),
      _buildDashboardButton(context, 'Post Shifts', Icons.post_add, Colors.blue[700]!, PostShifts()),
      _buildDashboardButton(context, 'Assign Tasks', Icons.assignment_ind, Colors.blue[600]!, AssignTasks()),
      _buildDashboardButton(context, 'Annual Leave', Icons.event_available, Colors.indigo[300]!, SupervisorApprovalPage()),
      _buildDashboardButton(context, 'My Todo List', Icons.checklist, Colors.blueGrey[700]!, supervisorTodolist()), // <-- FIXED: Corrected page

      // --- Communication (Purple Family) ---
      _buildDashboardButton(context, 'Statistics', Icons.message, Colors.deepPurple, StatisticsPage()),
      _buildDashboardButton(context, 'Create Notification', Icons.notifications_active, Colors.purple, CreateNotification()),

      // --- Logistics & Inventory (Green/Teal Family) ---
      _buildDashboardButton(context, 'Store Inventory', Icons.store, Colors.green[600]!, StoreInventoryPage()),
      _buildDashboardButton(context, 'Order Supplies', Icons.shopping_cart, Colors.teal, OrderSuppliesPage()),

      // --- Reports & Safety (Alert Colors) ---
      _buildDashboardButton(context, 'Accidents & Incidents', Icons.warning, Colors.red[700]!, CleanerReportAccidents()),
      _buildDashboardButton(context, 'Reports', Icons.assessment, Colors.grey[700]!, ReportsIssuesS()),

      // --- Financial & Admin (Action Colors) ---
      _buildDashboardButton(context, 'Create Vouchers', Icons.card_giftcard, Colors.orange[700]!, CreateVouchers()),
    ];
  }

  Widget _buildDashboardButton(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            gradient: LinearGradient(colors: [color.withOpacity(0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}