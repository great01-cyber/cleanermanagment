import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // --- NEW ---
import 'package:firebase_auth/firebase_auth.dart';     // --- NEW ---

class AnnualRequestPage extends StatefulWidget {
  @override
  _LeaveRequestPageState createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<AnnualRequestPage> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // --- NEW: Firebase Instances ---
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  // --- Leave Day State Variables ---
  final int totalLeaveEntitlement = 38; // Total Annual Leave
  int usedLeaveDays = 0; // Used Annual Leave
  int get remainingLeaveDays => totalLeaveEntitlement - usedLeaveDays;

  // --- REMOVED: Hard-coded leaveHistory list ---
  // List<Map<String, String>> leaveHistory = [ ... ];

  @override
  void initState() {
    super.initState();
    // --- NEW: Get the current user's ID ---
    // This assumes the user is already logged in when visiting this page
    _userId = _auth.currentUser?.uid;

    // We no longer call _updateLeaveCount() here.
    // The StreamBuilder will handle it when data is loaded.
  }

  /// --- MODIFIED: Calculates days from data snapshot ---
  void _updateLeaveCount(List<QueryDocumentSnapshot> leaveDocs) {
    int calculatedDays = 0;
    for (var doc in leaveDocs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data["status"] == "Approved" && data["type"] == "Annual Leave") {
        // Calculate from Timestamps
        final Timestamp start = data['startDate'];
        final Timestamp end = data['endDate'];
        calculatedDays += _calculateDaysFromTimestamps(start, end);
      }
    }

    // --- NEW: Safely update state after build ---
    // This prevents the "setState() called during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          usedLeaveDays = calculatedDays;
        });
      }
    });
  }

  /// --- MODIFIED: Helper function to calculate from Timestamps ---
  int _calculateDaysFromTimestamps(Timestamp start, Timestamp end) {
    try {
      final startDate = start.toDate();
      final endDate = end.toDate();
      // Add 1 to make the range inclusive (e.g., 15th to 18th is 4 days)
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

  // --- MODIFIED: Now async and writes to Firestore ---
  Future<void> _submitLeaveRequest() async {
    if (_startDateController.text.isEmpty ||
        _endDateController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // --- NEW: Check for user ID ---
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: You must be logged in.")),
      );
      return;
    }

    try {
      // --- NEW: Convert string dates to DateTime objects ---
      final DateTime startDate = DateTime.parse(_startDateController.text);
      final DateTime endDate = DateTime.parse(_endDateController.text);

      if(endDate.isBefore(startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("End date cannot be before start date.")),
        );
        return;
      }

      // --- NEW: Add data to Firestore 'leave_requests' collection ---
      await _db.collection('leave_requests').add({
        'userId': _userId,
        'startDate': Timestamp.fromDate(startDate), // Use Timestamp for dates
        'endDate': Timestamp.fromDate(endDate),     // Use Timestamp for dates
        'reason': _reasonController.text,
        'type': "Annual Leave", // Hard-coded as in your original
        'status': "Pending",
        'createdAt': FieldValue.serverTimestamp(), // Good for sorting
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Annual Leave request submitted successfully!")),
      );

      _startDateController.clear();
      _endDateController.clear();
      _reasonController.clear();

    } catch (e) {
      print("Error submitting leave request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Annual Leave Request", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Leave Counter Card (No changes here) ---
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Your Annual Leave Balance",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLeaveStat("Total", totalLeaveEntitlement.toString()),
                        _buildLeaveStat("Used", usedLeaveDays.toString()),
                        _buildLeaveStat("Remaining", remainingLeaveDays.toString(), isRemaining: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // --- Leave Request Form Card (No changes here) ---
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Request Annual Leave", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    SizedBox(height: 15),
                    _buildTextField(_startDateController, "Start Date", Icons.calendar_today, () => _selectDate(_startDateController)),
                    SizedBox(height: 15),
                    _buildTextField(_endDateController, "End Date", Icons.calendar_today, () => _selectDate(_endDateController)),
                    SizedBox(height: 15),
                    _buildTextField(_reasonController, "Reason", Icons.edit, null, maxLines: 3),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitLeaveRequest,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          "Submit Request",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),

            // --- MODIFIED: Leave History Section ---
            Text("Leave Request History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 10),

            // --- NEW: StreamBuilder to read live data from Firestore ---
            StreamBuilder<QuerySnapshot>(
              // Listen to the collection, filtered by the current user's ID
              stream: _db
                  .collection('leave_requests')
                  .where('userId', isEqualTo: _userId)
                  .orderBy('createdAt', descending: true) // Show newest first
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
                // Handle no data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  _updateLeaveCount([]); // Update count to 0
                  return Center(child: Text("No leave requests found."));
                }

                // --- NEW: Get the list of documents ---
                final leaveDocs = snapshot.data!.docs;

                // --- NEW: Update the "Used" days count based on this data ---
                _updateLeaveCount(leaveDocs);

                // --- NEW: Use ListView.builder to display the list ---
                return ListView.builder(
                  // We are inside a SingleChildScrollView, so we must add these:
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: leaveDocs.length,
                  itemBuilder: (context, index) {
                    final doc = leaveDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // --- NEW: Get data from the document ---
                    final String type = data['type'] ?? 'Unknown';
                    final String status = data['status'] ?? 'Unknown';

                    // --- NEW: Format Timestamps back to strings for display ---
                    final String startDate = (data['startDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0];
                    final String endDate = (data['endDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0];
                    final String dateRange = "$startDate to $endDate";

                    // Determine color for the chip
                    Color statusColor;
                    Color backgroundColor;
                    if (status == "Approved") {
                      statusColor = Colors.green;
                      backgroundColor = Colors.green[100]!;
                    } else if (status == "Pending") {
                      statusColor = Colors.orange;
                      backgroundColor = Colors.orange[100]!;
                    } else { // "Rejected" or other
                      statusColor = Colors.red;
                      backgroundColor = Colors.red[100]!;
                    }

                    return Card(
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Icon(
                            type == "Annual Leave" ? Icons.beach_access : Icons.medical_services,
                            color: Colors.green
                        ),
                        title: Text(type, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: Text(dateRange, style: TextStyle(fontSize: 14)),
                        trailing: Chip(
                          label: Text(status, style: TextStyle(color: statusColor)),
                          backgroundColor: backgroundColor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for the stats card (No changes here)
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

  /// Helper widget for building text fields (No changes here)
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, VoidCallback? onTap, {int maxLines = 1}) {
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}