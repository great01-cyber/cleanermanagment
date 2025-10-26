import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Cleaner/Cleaners Dashboard/CleanerReportAccidents.dart';
import '../../CreateVoucher.dart';
import '../../HomePage.dart';
import '../../Services/CreateNotification.dart';
import '../ReportsIssues.dart';
import 'AssignTask.dart';
import 'OrderSuppliesPage.dart';
import 'PostMessage.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard',  style: TextStyle(
            fontSize: 22,
            color: Colors.white
        )
        ),
        backgroundColor: Color(0xFF440099),
        elevation: 4,
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: _buildDashboardButtons(context),
        ),
      ),
    );
  }
}


Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Color(0xFF440099)),
          child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView(
            children: _buildDrawerItems(context),
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
    _buildDrawerTile(context, 'My Todo List', Icons.checklist, CleanerReportAccidents()), // <-- ADDED
    _buildDrawerTile(context, 'Annual Leave Request', Icons.event_available, SupervisorApprovalPage()),
    _buildDrawerTile(context, 'Post Message', Icons.message, PostMessage()),
    _buildDrawerTile(context, 'Create Notification', Icons.notifications, CreateNotification()),
    _buildDrawerTile(context, 'Store Inventory', Icons.store, StoreInventoryPage()),
    _buildDrawerTile(context, 'Create Vouchers', Icons.card_giftcard, CreateVouchers()),
    _buildDrawerTile(context, 'Reports', Icons.assessment, ReportsIssuesS()),
    _buildDrawerTile(context, 'Report Accidents', Icons.warning, CleanerReportAccidents()),
    _buildDrawerTile(context, 'Emergency', Icons.emergency, CleanerReportAccidents()),
    ListTile(
      leading: Icon(Icons.logout, color: Colors.redAccent),
      title: Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      onTap: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      },
    ),
  ];
}

Widget _buildDrawerTile(BuildContext context, String title, IconData icon, Widget page) {
  return ListTile(
    leading: Icon(icon, color: Color(0xFF440099)),
    title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    },
  );
}

List<Widget> _buildDashboardButtons(BuildContext context) {
  return [
    // --- Core Schedule & Team Management (Blue/Indigo Family) ---

    _buildDashboardButton(context, 'Shift Management', Icons.schedule, Colors.indigo, ShiftManagementScreen()),
    _buildDashboardButton(context, 'Post Shifts', Icons.post_add, Colors.blue[700]!, PostShifts()),
    _buildDashboardButton(context, 'Assign Tasks', Icons.assignment_ind, Colors.blue[600]!, AssignTasks()),
    _buildDashboardButton(context, 'Annual Leave', Icons.event_available, Colors.indigo[300]!, SupervisorApprovalPage()),
    _buildDashboardButton(context, 'My Todo List', Icons.checklist, Colors.blueGrey[700]!, SupervisorApprovalPage()),// Changed icon and color

// --- Communication (Purple Family) ---

    _buildDashboardButton(context, 'Post Message', Icons.message, Colors.deepPurple, PostMessage()),
    _buildDashboardButton(context, 'Create Notification', Icons.notifications_active, Colors.purple, CreateNotification()),

// --- Logistics & Inventory (Green/Teal Family) ---

    _buildDashboardButton(context, 'Store Inventory', Icons.store, Colors.green[600]!, StoreInventoryPage()),
    _buildDashboardButton(context, 'Order Supplies', Icons.shopping_cart, Colors.teal, OrderSuppliesPage()), // Changed icon and color

// --- Reports & Safety (Alert Colors) ---

    _buildDashboardButton(context, 'Accidents & Incidents', Icons.warning, Colors.red[700]!, CleanerReportAccidents()), // Changed icon, stronger red
    _buildDashboardButton(context, 'Reports', Icons.assessment, Colors.grey[700]!, ReportsIssuesS()), // Changed icon and color to be neutral

// --- Financial & Admin (Action Colors) ---

    _buildDashboardButton(context, 'Create Vouchers', Icons.card_giftcard, Colors.orange[700]!, CreateVouchers()), // Kept orange, removed duplicate


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
            SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );
}
