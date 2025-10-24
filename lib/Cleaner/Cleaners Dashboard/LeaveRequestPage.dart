import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class AnnualRequestPage extends StatefulWidget {
  @override
  _LeaveRequestPageState createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<AnnualRequestPage> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // --- Firebase Instances ---
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  // --- User Data State ---
  String? _mySupervisorId;
  String? _myUserName;
  bool _isLoadingSupervisor = true; // Start as true

  // --- Leave Day State Variables ---
  final int totalLeaveEntitlement = 38; // Total Annual Leave

  @override
  void initState() {
    super.initState(); // <-- Don't forget super.initState()
    _userId = _auth.currentUser?.uid;
    _fetchUserData();
  }

  // --- MODIFIED: Fixed 'fullName' bug ---
  Future<void> _fetchUserData() async {
    if (_userId == null) {
      setState(() {
        _isLoadingSupervisor = false;
      });
      return;
    }

    try {
      // Get the current user's document from the 'users' collection
      // ! ADJUST 'users' and 'supervisorId'/'fullName' to match your database!
      final userDoc = await _db.collection('users').doc(_userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;

        // Extract the supervisorId and userName
        final supervisorId = data['supervisorId'] as String?;
        // --- FIX: This should be the employee's name, not supervisor's ---
        final name = data['fullName'] as String?; // or 'name', etc.

        if (supervisorId == null || name == null) {
          _showErrorSnackBar(
              "Profile incomplete (missing supervisor or name). Contact admin.");
        }

        // Update the state
        setState(() {
          _mySupervisorId = supervisorId;
          _myUserName = name;
          _isLoadingSupervisor = false;
        });
      } else {
        _showErrorSnackBar("Could not find your user profile. Contact admin.");
        setState(() {
          _isLoadingSupervisor = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      _showErrorSnackBar("Error loading user data: $e");
      setState(() {
        _isLoadingSupervisor = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- NEW: Calculates all stats in one pass (for pie chart) ---
  Map<String, int> _calculateLeaveStats(List<QueryDocumentSnapshot> leaveDocs) {
    int approvedDays = 0;
    int pendingDays = 0;

    for (var doc in leaveDocs) {
      final data = doc.data() as Map<String, dynamic>;
      // We only care about Annual Leave for this page
      if (data["type"] == "Annual Leave") {
        final Timestamp start = data['startDate'];
        final Timestamp end = data['endDate'];
        int days = _calculateDaysFromTimestamps(start, end);

        if (data["status"] == "Approved") {
          approvedDays += days;
        } else if (data["status"] == "Pending") {
          pendingDays += days;
        }
      }
    }
    return {'approved': approvedDays, 'pending': pendingDays};
  }

  /// Helper function to calculate from Timestamps
  int _calculateDaysFromTimestamps(Timestamp start, Timestamp end) {
    try {
      final startDate = start.toDate();
      final endDate = end.toDate();
      // Add 1 to make the range inclusive
      return endDate.difference(startDate).inDays + 1;
    } catch (e) {
      print("Error parsing date: $e");
      return 0;
    }
  }

  // --- NEW: Function just for the Start Date ---
  Future<void> _selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      // --- FIX: firstDate is now dynamic ---
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDateController.text = picked.toLocal().toString().split(' ')[0];
        // --- NEW: Clear end date if start date changes ---
        _endDateController.clear();
      });
    }
  }

  // --- NEW: Function just for the End Date ---
  Future<void> _selectEndDate() async {
    // Check if start date is selected first
    if (_startDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a start date first")),
      );
      return;
    }

    final DateTime startDate = DateTime.parse(_startDateController.text);

    DateTime? picked = await showDatePicker(
      context: context,
      // --- FIX: Initial and first dates are based on the start date ---
      initialDate: startDate,
      firstDate: startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  // --- MODIFIED: Includes daysRequested field ---
  Future<void> _submitLeaveRequest() async {
    if (_startDateController.text.isEmpty ||
        _endDateController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (_userId == null) {
      _showErrorSnackBar("Error: You must be logged in.");
      return;
    }

    if (_isLoadingSupervisor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Still loading user data, please wait...")),
      );
      return;
    }

    if (_mySupervisorId == null || _myUserName == null) {
      _showErrorSnackBar(
          "Cannot submit: User profile is incomplete. Please contact admin.");
      return;
    }

    try {
      final DateTime startDate = DateTime.parse(_startDateController.text);
      final DateTime endDate = DateTime.parse(_endDateController.text);

      if (endDate.isBefore(startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("End date cannot be before start date.")),
        );
        return;
      }

      // --- FIX: Define and calculate daysRequested HERE ---
      final int daysRequested = endDate.difference(startDate).inDays + 1;

      // --- Add data to Firestore 'leave_requests' collection ---
      await _db.collection('leave_requests').add({
        'userId': _userId,
        'userName': _myUserName,
        'supervisorId': _mySupervisorId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': _reasonController.text,
        'daysRequested': daysRequested, // <-- THE FIX
        'type': "Annual Leave",
        'status': "Pending",
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Annual Leave request submitted successfully!")),
      );

      _startDateController.clear();
      _endDateController.clear();
      _reasonController.clear();
    } catch (e) {
      print("Error submitting leave request: $e");
      _showErrorSnackBar("Error submitting request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Annual Leave Request",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      // --- MODIFIED: StreamBuilder now calculates all stats ---
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('leave_requests')
            .where('userId', isEqualTo: _userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text("Error loading data: ${snapshot.error}"));
          }

          // --- Data is loaded (or empty) ---
          final leaveDocs = snapshot.data?.docs ?? [];

          // --- MODIFIED: Calculate all stats for pie chart ---
          final Map<String, int> stats = _calculateLeaveStats(leaveDocs);
          final int usedDays = stats['approved'] ?? 0;
          final int pendingDays = stats['pending'] ?? 0;

          // --- MODIFIED: Pass all stats to the build method ---
          return _buildPageContent(
              context, usedDays, pendingDays, leaveDocs);
        },
      ),
    );
  }

  // --- MODIFIED: Now accepts 'pendingDays' ---
  Widget _buildPageContent(BuildContext context, int usedDays, int pendingDays,
      List<QueryDocumentSnapshot> leaveDocs) {
    // --- MODIFIED: More accurate remaining days calculation ---
    final int remainingDays =
    (totalLeaveEntitlement - usedDays - pendingDays)
        .clamp(0, totalLeaveEntitlement);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- MODIFIED: Leave Counter Card now has Pie Chart ---
          Card(
            elevation: 5,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Your Annual Leave Balance",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800]),
                  ),
                  SizedBox(height: 16),
                  // --- RE-ADDED: Pie Chart Widget ---
                  SizedBox(
                    height: 150,
                    child: _buildPieChart(
                        context, usedDays, pendingDays, remainingDays),
                  ),
                  SizedBox(height: 16),
                  // --- MODIFIED: Row now includes "Pending" ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLeaveStat(
                          "Total", totalLeaveEntitlement.toString()),
                      _buildLeaveStat("Used", usedDays.toString(),
                          color: Colors.red[700]),
                      _buildLeaveStat("Pending", pendingDays.toString(),
                          color: Colors.orange[700]),
                      _buildLeaveStat("Remaining", remainingDays.toString(),
                          isRemaining: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // --- Leave Request Form Card (FIXED) ---
          Card(
            elevation: 5,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Request Annual Leave",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  SizedBox(height: 15),
                  // --- FIX: Calls the correct function ---
                  _buildTextField(_startDateController, "Start Date",
                      Icons.calendar_today, () => _selectStartDate()),
                  SizedBox(height: 15),
                  // --- FIX: Calls the correct function ---
                  _buildTextField(_endDateController, "End Date",
                      Icons.calendar_today, () => _selectEndDate()),
                  SizedBox(height: 15),
                  _buildTextField(_reasonController, "Reason", Icons.edit, null,
                      maxLines: 3),
                  SizedBox(height: 20),
                  // --- FIX: Button is here, by itself ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                      _isLoadingSupervisor ? null : _submitLeaveRequest,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      // --- FIX: Child is the Text/Indicator ---
                      child: _isLoadingSupervisor
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Submit Request",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 25),

          Text("Leave Request History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          SizedBox(height: 10),

          // --- ListView.builder with "Decline Reason" logic ---
          if (leaveDocs.isEmpty)
            Center(child: Text("No leave requests found."))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: leaveDocs.length,
              itemBuilder: (context, index) {
                final doc = leaveDocs[index];
                final data = doc.data() as Map<String, dynamic>;

                final String type = data['type'] ?? 'Unknown';
                final String status = data['status'] ?? 'Unknown';
                final String reason =
                    data['supervisorReason'] ?? 'No reason provided.';

                final String startDate = (data['startDate'] as Timestamp)
                    .toDate()
                    .toLocal()
                    .toString()
                    .split(' ')[0];
                final String endDate = (data['endDate'] as Timestamp)
                    .toDate()
                    .toLocal()
                    .toString()
                    .split(' ')[0];
                final String dateRange = "$startDate to $endDate";

                Color statusColor;
                Color backgroundColor;
                if (status == "Approved") {
                  statusColor = Colors.green;
                  backgroundColor = Colors.green[100]!;
                } else if (status == "Pending") {
                  statusColor = Colors.orange;
                  backgroundColor = Colors.orange[100]!;
                } else {
                  statusColor = Colors.red;
                  backgroundColor = Colors.red[100]!;
                }

                Widget trailingWidget;
                if (status == "Declined") {
                  trailingWidget = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(status,
                            style: TextStyle(color: statusColor)),
                        backgroundColor: backgroundColor,
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.comment_rounded,
                            color: Colors.blueGrey),
                        onPressed: () => _showDeclineReason(reason),
                        tooltip: 'View Reason',
                      ),
                    ],
                  );
                } else {
                  trailingWidget = Chip(
                    label:
                    Text(status, style: TextStyle(color: statusColor)),
                    backgroundColor: backgroundColor,
                  );
                }

                return Card(
                  color: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Icon(
                        type == "Annual Leave"
                            ? Icons.beach_access
                            : Icons.medical_services,
                        color: Colors.green),
                    title: Text(type,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    subtitle:
                    Text(dateRange, style: TextStyle(fontSize: 14)),
                    trailing: trailingWidget,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- MODIFIED: This is the only version of _buildLeaveStat needed ---
  Widget _buildLeaveStat(String label, String value,
      {bool isRemaining = false, Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isRemaining ? Colors.green[700] : (color ?? Colors.black87),
          ),
        ),
      ],
    );
  }

  /// Helper widget for building text fields
  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, VoidCallback? onTap,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      readOnly: onTap != null,
      maxLines: maxLines,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  // --- Function to show the decline reason ---
  void _showDeclineReason(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reason for Decline"),
        content: SingleChildScrollView(
          child: Text(reason.isEmpty ? "No reason provided." : reason),
        ),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // --- Function to build the pie chart ---
  Widget _buildPieChart(
      BuildContext context, int usedDays, int pendingDays, int remainingDays) {
    List<PieChartSectionData> sections = [];

    if (usedDays > 0) {
      sections.add(PieChartSectionData(
        color: Colors.red[400],
        value: usedDays.toDouble(),
        title: '$usedDays\nUsed',
        radius: 50,
        titleStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }
    if (pendingDays > 0) {
      sections.add(PieChartSectionData(
        color: Colors.orange[400],
        value: pendingDays.toDouble(),
        title: '$pendingDays\nPending',
        radius: 50,
        titleStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ));
    }
    // Only show remaining if it's greater than 0
    if (remainingDays > 0) {
      sections.add(PieChartSectionData(
        color: Colors.green[400],
        value: remainingDays.toDouble(),
        title: '$remainingDays\nFree',
        radius: 50,
        titleStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ));
    }

    // If all are 0, show a simple "empty" chart (full green)
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        color: Colors.green[400], // Start with a full "Free" chart
        value: totalLeaveEntitlement.toDouble(),
        title: '$totalLeaveEntitlement\nFree',
        radius: 50,
        titleStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // you can implement touch interactions here
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }
}