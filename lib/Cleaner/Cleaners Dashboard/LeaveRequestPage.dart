import 'package:flutter/material.dart';

class AnnualRequestPage extends StatefulWidget {
  @override
  _LeaveRequestPageState createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<AnnualRequestPage> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  // String? selectedLeaveType; // <-- REMOVED

  // --- Leave Day State Variables ---
  final int totalLeaveEntitlement = 38; // Total Annual Leave
  int usedLeaveDays = 0; // Used Annual Leave
  int get remainingLeaveDays => totalLeaveEntitlement - usedLeaveDays;
  // ---

  List<Map<String, String>> leaveHistory = [
    // This will be counted (4 days)
    {"date": "2024-02-15 to 2024-02-18", "type": "Annual Leave", "status": "Approved"},
    // This will NOT be counted
    {"date": "2024-04-01 to 2024-04-01", "type": "Sick Leave", "status": "Approved"},
    // This will NOT be counted (it's Pending)
    {"date": "2024-05-10 to 2024-05-12", "type": "Annual Leave", "status": "Pending"},
  ];

  @override
  void initState() {
    super.initState();
    _updateLeaveCount();
  }

  /// Calculates total used *Annual Leave* days from "Approved" requests
  void _updateLeaveCount() {
    int calculatedDays = 0;
    for (var entry in leaveHistory) {
      // --- MODIFIED: Added check for "Annual Leave" type ---
      if (entry["status"] == "Approved" && entry["type"] == "Annual Leave") {
        calculatedDays += _calculateDaysFromEntry(entry["date"]!);
      }
    }
    setState(() {
      usedLeaveDays = calculatedDays;
    });
  }

  /// Helper function to parse date strings and find the duration
  int _calculateDaysFromEntry(String dateRange) {
    try {
      final dates = dateRange.split(' to ');
      final startDate = DateTime.parse(dates[0]);
      final endDate = DateTime.parse(dates[1]);
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

  void _submitLeaveRequest() {
    // --- MODIFIED: Removed check for selectedLeaveType ---
    if (_startDateController.text.isEmpty ||
        _endDateController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      leaveHistory.add({
        "date": "${_startDateController.text} to ${_endDateController.text}",
        "type": "Annual Leave", // <-- HARD-CODED type
        "status": "Pending"
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Annual Leave request submitted successfully!")),
    );

    _startDateController.clear();
    _endDateController.clear();
    _reasonController.clear();
    // setState(() { selectedLeaveType = null; }); // <-- REMOVED
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
            // --- Leave Counter Card ---
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

            // --- Leave Request Form Card ---
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

                    // --- REMOVED Leave Type Dropdown ---

                    // --- Reason Field ---
                    _buildTextField(_reasonController, "Reason", Icons.edit, null, maxLines: 3),
                    SizedBox(height: 20),

                    // Submit Button
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

            // --- Leave History Section ---
            Text("Leave Request History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 10),
            ...leaveHistory.map((entry) {
              // Determine color for the chip
              Color statusColor;
              Color backgroundColor;
              if (entry["status"] == "Approved") {
                statusColor = Colors.green;
                backgroundColor = Colors.green[100]!;
              } else if (entry["status"] == "Pending") {
                statusColor = Colors.orange;
                backgroundColor = Colors.orange[100]!;
              } else {
                statusColor = Colors.red;
                backgroundColor = Colors.red[100]!;
              }

              return Card(
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: Icon(
                      entry["type"] == "Annual Leave" ? Icons.beach_access : Icons.medical_services,
                      color: Colors.green
                  ),
                  title: Text(entry["type"]!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text(entry["date"]!, style: TextStyle(fontSize: 14)),
                  trailing: Chip(
                    label: Text(entry["status"]!, style: TextStyle(color: statusColor)),
                    backgroundColor: backgroundColor,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
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