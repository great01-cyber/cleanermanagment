import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/report_service.dart';

class ReportsIssuesS extends StatefulWidget {
  const ReportsIssuesS({super.key});

  @override
  State<ReportsIssuesS> createState() => _ReportsIssuesSState();
}

class _ReportsIssuesSState extends State<ReportsIssuesS> {
  List<IssueReport> _reports = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get reports from assigned cleaners only
      final reports = await ReportService.getSupervisorReports(currentUser.uid);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    }
  }

  List<IssueReport> get _filteredReports {
    if (_selectedFilter == 'all') return _reports;
    return _reports.where((report) => report.status == _selectedFilter).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports from My Cleaners"),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('pending', 'Pending'),
                  _buildFilterChip('in_progress', 'In Progress'),
                  _buildFilterChip('resolved', 'Resolved'),
                  _buildFilterChip('closed', 'Closed'),
                ],
              ),
            ),
          ),
          // Reports list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No reports from your cleaners', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('Reports from your assigned cleaners will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = _filteredReports[index];
                          return _buildReportCard(report);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.amber.withOpacity(0.3),
        checkmarkColor: Colors.amber[800],
      ),
    );
  }

  Widget _buildReportCard(IssueReport report) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(report.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.priority.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              report.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('${report.reporterName} (${report.reporterRole})', style: TextStyle(fontSize: 12)),
                SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('Floor ${report.floor}, Door ${report.doorNumber}', style: TextStyle(fontSize: 12)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Spacer(),
                Text(
                  '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (report.status == 'pending' || report.status == 'in_progress') ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateReportStatus(report.id, 'in_progress'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: Text('Start'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
              child: ElevatedButton(
                      onPressed: () => _updateReportStatus(report.id, 'resolved'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text('Resolve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    try {
      await ReportService.updateReportStatus(reportId, status);
      await _loadReports();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update report: $e')),
      );
    }
  }
}
