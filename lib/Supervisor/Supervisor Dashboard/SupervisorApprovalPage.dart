import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class SupervisorApprovalPage extends StatefulWidget {
  @override
  _SupervisorApprovalPageState createState() => _SupervisorApprovalPageState();
}

// --- NEW: Add 'DefaultTabController' to manage tabs ---
class _SupervisorApprovalPageState extends State<SupervisorApprovalPage>
    with SingleTickerProviderStateMixin {

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _supervisorId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _reasonController = TextEditingController();

  // Calendar state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  // --- Total leave days for calculation (same as employee page) ---
  final int _totalLeaveEntitlement = 38;

  // --- Approve/Decline functions (No changes needed) ---
  Future<void> _approveRequest(String docId) async {
    try {
      await _db.collection('leave_requests').doc(docId).update({
        'status': 'Approved',
        'supervisorReason': 'Approved',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request Approved"), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Request Declined"), backgroundColor: Colors.red));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- NEW: Helper to show who is off on a selected day ---
  void _showEmployeesOffDialog(List<String> employees) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Staff on Leave"),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: employees.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.person_outline, color: Colors.blueAccent),
                title: Text(employees[index]),
              );
            },
          ),
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

  // --- NEW: Helper to build the event map for the calendar ---
  Map<DateTime, List<String>> _buildEventsMap(
      List<QueryDocumentSnapshot> approvedDocs) {
    Map<DateTime, List<String>> events = {};
    for (var doc in approvedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final String userName = data['userName'] ?? 'Unknown Employee';
      final DateTime start = (data['startDate'] as Timestamp).toDate();
      final DateTime end = (data['endDate'] as Timestamp).toDate();

      for (var day = start;
      day.isBefore(end.add(Duration(days: 1)));
      day = day.add(Duration(days: 1))) {
        final normalizedDay = DateTime.utc(day.year, day.month, day.day);
        if (events[normalizedDay] == null) {
          events[normalizedDay] = [];
        }
        // Avoid adding duplicate names for the same day (if logic allows)
        if (!events[normalizedDay]!.contains(userName)) {
          events[normalizedDay]!.add(userName);
        }
      }
    }
    return events;
  }

  // --- NEW: Helper to calculate balances for all employees ---
  Map<String, int> _calculateAllBalances(
      List<QueryDocumentSnapshot> approvedDocs) {
    Map<String, int> usedDaysMap = {};
    for (var doc in approvedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      // We only care about Annual Leave for balances
      if (data['type'] == 'Annual Leave') {
        final String userId = data['userId'];
        // Use 'daysRequested' field, default to 0 if null
        final int days = (data['daysRequested'] as int?) ?? 0;

        if (usedDaysMap[userId] == null) {
          usedDaysMap[userId] = 0;
        }
        usedDaysMap[userId] = usedDaysMap[userId]! + days;
      }
    }
    return usedDaysMap;
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Use DefaultTabController to wrap the Scaffold ---
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Annual Leave Request"),
          backgroundColor: Colors.blueAccent,
          // --- NEW: Add the TabBar ---
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: "Approvals"),
              Tab(icon: Icon(Icons.group), text: "Team Balances"),
            ],
          ),
        ),
        // --- MODIFIED: The body is one main StreamBuilder ---
        // This stream provides data to BOTH tabs efficiently
        body: StreamBuilder<QuerySnapshot>(
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
            if (!snapshot.hasData) {
              return Center(child: Text("No data found."));
            }

            // --- NEW: Process all data here, once ---
            final allDocs = snapshot.data!.docs;

            final pendingDocs = allDocs
                .where((doc) => (doc.data() as Map)['status'] == 'Pending')
                .toList();

            final approvedDocs = allDocs
                .where((doc) => (doc.data() as Map)['status'] == 'Approved')
                .toList();

            // Data for Tab 1 (Calendar)
            final approvedEventsMap = _buildEventsMap(approvedDocs);

            // Data for Tab 2 (Balances)
            // We pass *all* approved docs, _calculateAllBalances will filter by type
            final usedDaysMap = _calculateAllBalances(approvedDocs);

            // --- NEW: Return the TabBarView ---
            return TabBarView(
              children: [
                // --- Tab 1: Approvals & Calendar ---
                _buildApprovalTab(pendingDocs, approvedEventsMap),
                // --- Tab 2: Team Balances ---
                _buildBalancesTab(usedDaysMap),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- NEW: Widget for the "Approvals" tab ---
  Widget _buildApprovalTab(List<QueryDocumentSnapshot> pendingDocs,
      Map<DateTime, List<String>> approvedEventsMap) {
    // --- NEW: Wrap in SingleChildScrollView to make it all scrollable ---
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECTION 1: Pending Requests List ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Pending Requests",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          // --- MODIFIED: Use shrinkWrap & NeverScrollable physics ---
          if (pendingDocs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text("No pending requests.")),
            )
          else
            ListView.builder(
              itemCount: pendingDocs.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var doc = pendingDocs[index];
                var data = doc.data() as Map<String, dynamic>;
                String formatDate(Timestamp ts) =>
                    DateFormat('EEE, MMM d, yyyy').format(ts.toDate());
                final String dateRange =
                    "${formatDate(data['startDate'])} to ${formatDate(data['endDate'])}";

                final String leaveType = data['type'] ?? 'Leave';
                final Color typeColor = (leaveType == 'Annual Leave')
                    ? Colors.blueAccent
                    : Colors.orange[700]!;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['userName'] ?? 'Unknown',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "$leaveType: ${data['daysRequested'] ?? '?'} days",
                          style:
                          TextStyle(fontSize: 16, color: typeColor, fontWeight: FontWeight.w500),
                        ),
                        Text(dateRange,
                            style: TextStyle(fontStyle: FontStyle.italic)),
                        SizedBox(height: 8),
                        Text("Reason: ${data['reason']}"),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.red, size: 30),
                              onPressed: () => _declineRequest(doc.id),
                            ),
                            SizedBox(width: 16),
                            IconButton(
                              icon: Icon(Icons.check_rounded,
                                  color: Colors.green, size: 30),
                              onPressed: () => _approveRequest(doc.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Divider(thickness: 2, height: 20, indent: 20, endIndent: 20),
          // --- SECTION 2: Team Calendar ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Team Leave Calendar",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          _buildTeamCalendar(approvedEventsMap),
        ],
      ),
    );
  }

  // --- NEW: Helper widget to build the calendar ---
  Widget _buildTeamCalendar(Map<DateTime, List<String>> events) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 4,
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: (day) {
          final normalizedDay = DateTime.utc(day.year, day.month, day.day);
          return events[normalizedDay] ?? [];
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          final normalizedDay =
          DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
          final employeesOff = events[normalizedDay];
          if (employeesOff != null && employeesOff.isNotEmpty) {
            _showEmployeesOffDialog(employeesOff);
          }
        },
        calendarStyle: CalendarStyle(
          // --- Style the markers ---
          markersMaxCount: 1,
          markerDecoration: BoxDecoration(
            color: Colors.red[700],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // --- NEW: Widget for the "Team Balances" tab ---
  // --- *** THIS IS THE COMPLETED METHOD *** ---
  Widget _buildBalancesTab(Map<String, int> usedDaysMap) {
    return StreamBuilder<QuerySnapshot>(
      // This stream finds all 'users' who are assigned to this supervisor
        stream: _db
            .collection('users')
            .where('supervisorId', isEqualTo: _supervisorId)
            .orderBy('fullName') // Sort alphabetically by name
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
            return Center(child: Text("No employees found on your team."));
          }

          final employeeDocs = userSnapshot.data!.docs;

          return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: employeeDocs.length,
              itemBuilder: (context, index) {
                final userDoc = employeeDocs[index];
                final data = userDoc.data() as Map<String, dynamic>;
                final String userName = data['fullName'] ?? 'Unknown Employee';

                // Get the user's ID
                final String userId = userDoc.id;

                // Get the used days from the map, defaulting to 0
                final int usedDays = usedDaysMap[userId] ?? 0;

                // Calculate remaining days
                final int remainingDays = _totalLeaveEntitlement - usedDays;

                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent[100],
                      child: Text(
                        userName.isNotEmpty ? userName[0] : '?',
                        style: TextStyle(color: Colors.blueAccent[700]),
                      ),
                    ),
                    title: Text(
                      userName,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                        "Used: $usedDays / $_totalLeaveEntitlement"
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Remaining",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          "$remainingDays",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: remainingDays > 10
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
        });
  }
}