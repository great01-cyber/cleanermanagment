import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/shift_management_service.dart';
import '../Services/task_assignment_service.dart';
import '../Services/user_management_service.dart';

// Comprehensive shift history and reporting screen
class ShiftHistoryScreen extends StatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  List<TaskAssignment> _allShifts = [];
  List<TaskAssignment> _filteredShifts = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _selectedPeriod = 'all';
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadShiftHistory();
  }

  // Load shift history and statistics
  Future<void> _loadShiftHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get shift history
      _allShifts = await ShiftManagementService.getShiftHistory(currentUser.uid);
      
      // Get statistics
      _statistics = await ShiftManagementService.getShiftStatistics(currentUser.uid);
      
      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load shift history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Apply filters to shifts
  void _applyFilters() {
    setState(() {
      _filteredShifts = _allShifts.where((shift) {
        // Status filter
        bool statusMatch = _selectedStatus == 'all' || shift.status == _selectedStatus;
        
        // Period filter
        bool periodMatch = true;
        if (_selectedPeriod != 'all') {
          final now = DateTime.now();
          switch (_selectedPeriod) {
            case 'today':
              periodMatch = shift.assignedDate.day == now.day &&
                           shift.assignedDate.month == now.month &&
                           shift.assignedDate.year == now.year;
              break;
            case 'week':
              final weekAgo = now.subtract(const Duration(days: 7));
              periodMatch = shift.assignedDate.isAfter(weekAgo);
              break;
            case 'month':
              final monthAgo = now.subtract(const Duration(days: 30));
              periodMatch = shift.assignedDate.isAfter(monthAgo);
              break;
          }
        }
        
        // Date range filter
        bool dateRangeMatch = true;
        if (_startDate != null && _endDate != null) {
          dateRangeMatch = shift.assignedDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                          shift.assignedDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }
        
        return statusMatch && periodMatch && dateRangeMatch;
      }).toList();
      
      // Sort by assigned date (newest first)
      _filteredShifts.sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
    });
  }

  // Export shift history
  Future<void> _exportHistory() async {
    try {
      // This would typically export to CSV or PDF
      // For now, we'll show a dialog with the data
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Shift History'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _filteredShifts.length,
              itemBuilder: (context, index) {
                final shift = _filteredShifts[index];
                return ListTile(
                  title: Text(shift.title),
                  subtitle: Text('${shift.status} - ${shift.assignedDate.day}/${shift.assignedDate.month}/${shift.assignedDate.year}'),
                  trailing: Text(shift.location),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export functionality would be implemented here'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Export'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift History'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportHistory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShiftHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics cards
          if (!_isLoading) _buildStatisticsCards(),
          
          // Filters
          _buildFilters(),
          
          // Shifts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredShifts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No shift history found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredShifts.length,
                        itemBuilder: (context, index) {
                          final shift = _filteredShifts[index];
                          return _buildShiftCard(shift);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Build statistics cards
  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shift Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Shifts',
                  '${_statistics['totalShifts'] ?? 0}',
                  Icons.work,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '${_statistics['completedShifts'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completion Rate',
                  '${(_statistics['completionRate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Recent Shifts',
                  '${_statistics['recentShifts'] ?? 0}',
                  Icons.schedule,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build statistics card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build filters
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Period filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Time'),
                const SizedBox(width: 8),
                _buildFilterChip('today', 'Today'),
                const SizedBox(width: 8),
                _buildFilterChip('week', 'This Week'),
                const SizedBox(width: 8),
                _buildFilterChip('month', 'This Month'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Status'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'In Progress'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed'),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Date range picker
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                        _applyFilters();
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _startDate != null 
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Select Start Date',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                        _applyFilters();
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _endDate != null 
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Select End Date',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build filter chip
  Widget _buildFilterChip(String value, String label) {
    final isSelected = (_selectedPeriod == value && value != 'all') || 
                      (_selectedStatus == value && value != 'all');
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (['all', 'today', 'week', 'month'].contains(value)) {
            _selectedPeriod = value;
          } else {
            _selectedStatus = value;
          }
          _applyFilters();
        });
      },
      selectedColor: Colors.blue.withOpacity(0.3),
      checkmarkColor: Colors.blue,
    );
  }

  // Build shift card
  Widget _buildShiftCard(TaskAssignment shift) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getStatusIcon(shift.status),
                  color: _getStatusColor(shift.status),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shift.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(shift.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shift.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(shift.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              shift.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            
            // Details
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  shift.location,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Spacer(),
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${shift.assignedDate.day}/${shift.assignedDate.month}/${shift.assignedDate.year}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            
            // Completion info
            if (shift.status == 'completed' && shift.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Completed: ${shift.completedAt!.day}/${shift.completedAt!.month}/${shift.completedAt!.year}',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.work;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
