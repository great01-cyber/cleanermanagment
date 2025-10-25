import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// --- NEW: Import the calendar package ---
import 'package:table_calendar/table_calendar.dart';

class SupervisorApprovalPage extends StatefulWidget {
  @override
  _SupervisorApprovalPageState createState() => _SupervisorApprovalPageState();
}

class _SupervisorApprovalPageState extends State<SupervisorApprovalPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _supervisorId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _reasonController = TextEditingController();

  // --- NEW: State variables for the calendar ---
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  // --- Your _approveRequest and _declineRequest functions are perfect ---
  // --- They don't need any changes. ---
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

  Future<void> _declineRequest(String docId) async {
    _reasonController.clear();
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
        title: Text("Supervisor Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),
      // --- MODIFIED: The body is now a StreamBuilder that powers the whole page ---
      body: StreamBuilder<QuerySnapshot>(
        // --- MODIFIED: Query for ALL requests (Pending AND Approved) ---
        // We will filter them in the builder
        stream: _db
            .collection('leave_requests')
            .where('supervisorId', isEqualTo: _supervisorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No requests found for your team."));
          }

          // --- NEW: Filter all docs into two separate lists ---
          final allDocs = snapshot.data!.docs;

          final pendingDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'Pending';
          }).toList();

          final approvedDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'Approved';
          }).toList();

          // --- NEW: Process approved docs to get a Set of all leave dates ---
          final Set<DateTime> approvedLeaveDays = {};
          for (var doc in approvedDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final DateTime start = (data['startDate'] as Timestamp).toDate();
            final DateTime end = (data['endDate'] as Timestamp).toDate();

            // Loop from the start date to the end date (inclusive)
            for (var day = start;
            day.isBefore(end.add(Duration(days: 1)));
            day = day.add(Duration(days: 1))) {
              // Add the date (normalized to UTC to avoid timezone issues)
              approvedLeaveDays.add(DateTime.utc(day.year, day.month, day.day));
            }
          }

          // --- MODIFIED: Build the new two-section layout ---
          return Column(
            children: [
              // --- SECTION 1: Pending Requests List ---
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Pending Requests",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                // We pass only the pending docs to this builder
                child: _buildPendingList(pendingDocs),
              ),

              Divider(thickness: 2, height: 2),

              // --- SECTION 2: Team Calendar ---
              // We pass the Set of approved dates to this builder
              _buildTeamCalendar(approvedLeaveDays),
            ],
          );
        },
      ),
    );
  }

  // --- NEW: Helper widget to build the pending list ---
  Widget _buildPendingList(List<QueryDocumentSnapshot> pendingDocs) {
    if (pendingDocs.isEmpty) {
      return Center(child: Text("No pending requests."));
    }

    return ListView.builder(
      itemCount: pendingDocs.length,
      itemBuilder: (context, index) {
        var doc = pendingDocs[index];
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
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.red, size: 30),
                      onPressed: () => _declineRequest(doc.id),
                    ),
                    SizedBox(width: 16),
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
  }

  // --- NEW: Helper widget to build the team calendar ---
  Widget _buildTeamCalendar(Set<DateTime> approvedLeaveDays) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      // --- This function provides the red dots ---
      eventLoader: (day) {
        // Normalize the day to UTC to match our Set
        final normalizedDay = DateTime.utc(day.year, day.month, day.day);
        if (approvedLeaveDays.contains(normalizedDay)) {
          return ['On Leave']; // Return a list (any list) to show a marker
        }
        return []; // Return an empty list for no marker
      },
      // --- Style the red dots ---
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
      // --- Manage calendar state ---
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
    );
  }
}