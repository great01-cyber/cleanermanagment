import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Add this package for date formatting

class SupervisorApprovalPage extends StatefulWidget {
  @override
  _SupervisorApprovalPageState createState() => _SupervisorApprovalPageState();
}

class _SupervisorApprovalPageState extends State<SupervisorApprovalPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _supervisorId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _reasonController = TextEditingController();

  // --- NEW: Function to APPROVE a request ---
  Future<void> _approveRequest(String docId) async {
    try {
      await _db.collection('leave_requests').doc(docId).update({
        'status': 'Approved',
        'supervisorReason': 'Approved',
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request Approved"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- NEW: Function to DECLINE a request (with a reason) ---
  Future<void> _declineRequest(String docId) async {
    // Clear the controller for the new dialog
    _reasonController.clear();

    // Show a dialog to get the reason
    String? reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reason for Decline'),
        content: TextField(
          controller: _reasonController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter reason here'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Submit'),
            onPressed: () {
              if (_reasonController.text.isNotEmpty) {
                Navigator.pop(context, _reasonController.text);
              }
            },
          ),
        ],
      ),
    );

    // If a reason was submitted, update Firestore
    if (reason != null && reason.isNotEmpty) {
      try {
        await _db.collection('leave_requests').doc(docId).update({
          'status': 'Declined',
          'supervisorReason': reason,
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Request Declined"), backgroundColor: Colors.red));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pending Approvals"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query for requests assigned to THIS supervisor that are "Pending"
        stream: _db
            .collection('leave_requests')
            .where('supervisorId', isEqualTo: _supervisorId)
            .where('status', isEqualTo: 'Pending')
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No pending requests."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              // Helper to format dates nicely
              String formatDate(Timestamp ts) {
                return DateFormat('EEE, MMM d, yyyy').format(ts.toDate());
              }

              final String dateRange =
                  "${formatDate(data['startDate'])} to ${formatDate(data['endDate'])}";

              return Card(
                margin: EdgeInsets.all(10),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'Unknown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${data['daysRequested']} days requested",
                        style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                      ),
                      Text(dateRange, style: TextStyle(fontStyle: FontStyle.italic)),
                      SizedBox(height: 8),
                      Text("Reason: ${data['reason']}"),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // --- DECLINE BUTTON (X) ---
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.red, size: 30),
                            onPressed: () => _declineRequest(doc.id),
                          ),
                          SizedBox(width: 16),
                          // --- APPROVE BUTTON (✓) ---
                          IconButton(
                            icon: Icon(Icons.check_rounded, color: Colors.green, size: 30),
                            onPressed: () => _approveRequest(doc.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}