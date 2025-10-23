import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // --- NEW: User Data State ---
  String? _mySupervisorId;
  String? _myUserName;
  bool _isLoadingSupervisor = true; // Start as true

  // --- Leave Day State Variables ---
  final int totalLeaveEntitlement = 38; // Total Annual Leave

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    // --- NEW: Fetch user data when page loads ---
    _fetchUserData();
  }

  // --- NEW: Function to fetch user's supervisor and name ---
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
        final userName = data['fullName'] as String?; // or 'name', etc.

        if (supervisorId == null || userName == null) {
          _showErrorSnackBar(
              "Profile incomplete (missing supervisor or name). Contact admin.");
        }

        // Update the state
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

  // --- NEW: Helper for showing errors ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Calculates used days from a list of documents.
  int _calculateUsedDays(List<QueryDocumentSnapshot> leaveDocs) {
    int calculatedDays = 0;
    for (var doc in leaveDocs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data["status"] == "Approved" && data["type"] == "Annual Leave") {
        final Timestamp start = data['startDate'];
        final Timestamp end = data['endDate'];
        calculatedDays += _calculateDaysFromTimestamps(start, end);
      }
    }
    return calculatedDays;
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

  // --- MODIFIED: Now includes supervisorId and userName ---
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

    // --- NEW: Check if supervisor data is loaded ---
    if (_isLoadingSupervisor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Still loading user data, please wait...")),
      );
      return;
    }

    // --- NEW: Check if supervisor/name was found ---
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

      // --- NEW: Add data to Firestore 'leave_requests' collection ---
      await _db.collection('leave_requests').add({
        'userId': _userId,
        'userName': _myUserName, // <-- ADDED
        'supervisorId': _mySupervisorId, // <-- ADDED
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Annual Leave Request",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      // --- MODIFIED: StreamBuilder now wraps the entire body ---
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

          // 1. CALCULATE used days right here
          final int calculatedUsedDays = _calculateUsedDays(leaveDocs);

          // 2. BUILD the page content using the calculated data
          return _buildPageContent(context, calculatedUsedDays, leaveDocs);
        },
      ),
    );
  }

  // --- NEW: Helper method to build the page content ---
  Widget _buildPageContent(
      BuildContext context, int usedDays, List<QueryDocumentSnapshot> leaveDocs) {
    // Calculate remaining days locally
    final int remainingDays = totalLeaveEntitlement - usedDays;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Leave Counter Card (Now uses 'usedDays' parameter) ---
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
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLeaveStat(
                          "Total", totalLeaveEntitlement.toString()),
                      _buildLeaveStat("Used", usedDays.toString()),
                      _buildLeaveStat("Remaining", remainingDays.toString(),
                          isRemaining: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // --- Leave Request Form Card (MODIFIED button) ---
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
                      // --- MODIFIED: Disable button while loading supervisor data ---
                      onPressed: _isLoadingSupervisor ? null : _submitLeaveRequest,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      // --- MODIFIED: Show loader or text ---
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

          // --- MODIFIED: Leave History Section ---
          Text("Leave Request History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          SizedBox(height: 10),

          // --- MODIFIED: No StreamBuilder here. Just build from the list. ---
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
                    trailing: Chip(
                      label:
                      Text(status, style: TextStyle(color: statusColor)),
                      backgroundColor: backgroundColor,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Helper widget for the stats card
  Widget _buildLeaveStat(String label, String value, {bool isRemaining = false}) {
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
            color: isRemaining ? Colors.green[700] : Colors.black87,
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
}