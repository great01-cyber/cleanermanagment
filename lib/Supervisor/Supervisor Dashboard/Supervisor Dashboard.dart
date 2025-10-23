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
        title: const Text('Supervisor Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
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
          decoration: BoxDecoration(color: Colors.blueAccent),
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
    _buildDrawerTile(context, 'Post Message', Icons.message, PostMessage()),
    _buildDrawerTile(context, 'Store Inventory', Icons.store, StoreInventoryPage()),
    _buildDrawerTile(context, 'Create Vouchers', Icons.card_giftcard, CreateVouchers()),
    _buildDrawerTile(context, 'Assign Tasks', Icons.assignment, AssignTasks()),
    _buildDrawerTile(context, 'Reports', Icons.report, ReportsIssuesS()),
    _buildDrawerTile(context, 'Create Notification', Icons.notifications, CreateNotification()),
    _buildDrawerTile(context, 'Report Accidents', Icons.notifications, CleanerReportAccidents()),
    _buildDrawerTile(context, 'Emergency', Icons.emergency, OrderSuppliesPage()),
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
    leading: Icon(icon, color: Colors.blueAccent),
    title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    },
  );
}

List<Widget> _buildDashboardButtons(BuildContext context) {
  return [
    _buildDashboardButton(context, 'Post Shifts', Icons.post_add, Colors.blueAccent, PostShifts()),
    _buildDashboardButton(context, 'Shift Management', Icons.schedule, Colors.indigo, ShiftManagementScreen()),
    _buildDashboardButton(context, 'Post Message', Icons.message, Colors.deepPurple, PostMessage()),
    _buildDashboardButton(context, 'Store Inventory', Icons.store, Colors.green, StoreInventoryPage()),
    _buildDashboardButton(context, 'Create Vouchers', Icons.card_giftcard, Colors.orange, CreateVouchers()),
    _buildDashboardButton(context, 'Assign Tasks', Icons.assignment, Colors.redAccent, AssignTasks()),
    _buildDashboardButton(context, 'Reports', Icons.report, Colors.teal, ReportsIssuesS()),
    _buildDashboardButton(context, 'Create Notification', Icons.notifications, Colors.purple, CreateNotification()),
    _buildDashboardButton(context, 'Order Supplies', Icons.inventory, Colors.red, OrderSuppliesPage()),
    _buildDashboardButton(context, 'Accidents/Near Misses/ Incidents/ Slips', Icons.inventory, Colors.red, CleanerReportAccidents())

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
