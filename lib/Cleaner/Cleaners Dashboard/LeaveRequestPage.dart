import 'package:flutter/material.dart';
import 'package.cloud_firestore/cloud_firestore.dart';
import 'package.firebase_auth/firebase_auth.dart';
import 'package.fl_chart/fl_chart.dart'; // <-- NEW: Import for charts

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
  bool _isLoadingSupervisor = true;

  // --- Leave Day State Variables ---
  final int totalLeaveEntitlement = 38; // Total Annual Leave

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    _fetchUserData();
  }

  // --- MODIFIED: Fetches user data using a query ---
  Future<void> _fetchUserData() async {
    if (_userId == null) {
      setState(() {
        _isLoadingSupervisor = false;
      });
      return;
    }

    try {
      // Query the 'users' collection for a document where 'userId' matches
      final querySnapshot = await _db
          .collection('users')
          .where('userId', isEqualTo: _userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final data = userDoc.data();

        // ! ADJUST these field names if yours are different!
        final supervisorId = data['supervisorId'] as String?;
        final userName = data['fullName'] as String?; // or 'name', etc.

        if (supervisorId == null || userName == null) {
          _showErrorSnackBar(
              "Profile incomplete (missing supervisor or name). Contact admin.");
        }

        setState(() {
          _mySupervisorId = supervisorId;
          _myUserName = userName;
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

  // --- NEW: Calculates all stats in one pass ---
  /// Calculates used and pending days from a list of documents.
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
        // Declined days are just ignored
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

  Future<void> _selectDate(TextEditingController controller) async {
    // ... (This function is unchanged)
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    // ... (This function is unchanged from the last version)
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

      await _db.collection('leave_requests').add({
        'userId': _userId,
        'userName': _myUserName,
        'supervisorId': _mySupervisorId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': _reasonController.text,
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

  // --- NEW: Function to show the decline reason dialog ---
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Annual Leave Request",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('leave_requests')
            .where('userId', isEqualTo: _userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading data: ${snapshot.error}"));
          }

          final leaveDocs = snapshot.data?.docs ?? [];

          // --- MODIFIED: Calculate all stats ---
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

    // --- MODIFIED: Remaining days calculation is now more accurate ---
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

                  // --- NEW: Pie Chart Widget ---
                  SizedBox(
                    height: 150, // Give the chart a defined height
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

          // --- Leave Request Form Card ---
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
                  _buildTextField(_startDateController, "Start Date",
                      Icons.calendar_today, () => _selectDate(_startDateController)),
                  SizedBox(height: 15),
                  _buildTextField(_endDateController, "End Date",
                      Icons.calendar_today, () => _selectDate(_endDateController)),
                  SizedBox(height: 15),
                  _buildTextField(_reasonController, "Reason", Icons.edit, null,
                      maxLines: 3),
                  SizedBox(height: 20),
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

          // --- MODIFIED: Includes the "Decline Reason" icon logic ---
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
                // Get the decline reason
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

                // --- Build the trailing widget conditionally ---
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
                  // Otherwise, just show the Chip
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

  // --- NEW: Helper widget to build the pie chart ---
  Widget _buildPieChart(
      BuildContext context, int usedDays, int pendingDays, int remainingDays) {
    // This list will hold the slices
    List<PieChartSectionData> sections = [];

    // Only add slices if their value is greater than 0
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

    // If all are 0, show a simple "empty" chart
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        color: Colors.grey[300],
        value: 1, // Must have some value
        title: 'No Data',
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
        sectionsSpace: 2, // Space between slices
        centerSpaceRadius: 40, // Makes it a donut chart
        sections: sections,
      ),
    );
  }

  // --- MODIFIED: Helper widget for the stats card now accepts a color ---
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
    // ... (This function is unchanged)
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
}