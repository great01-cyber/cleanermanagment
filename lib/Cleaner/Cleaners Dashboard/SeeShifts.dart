import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Services/ShiftProvider.dart';
import '../../Services/task_assignment_service.dart';
import '../../Services/shift_assignment_service.dart';

// Screen for cleaners to view their assigned shifts from Firebase
class SeeShifts extends StatefulWidget {
  @override
  _SeeShiftsState createState() => _SeeShiftsState();
}

class _SeeShiftsState extends State<SeeShifts> {
  List<ShiftAssignment> _shifts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'pending', 'in_progress', 'completed'

  @override
  void initState() {
    super.initState();
    _loadShifts(); // Load shifts from Firebase
  }

    // Load shifts assigned to current cleaner
    Future<void> _loadShifts() async {
      try {
        final shifts = await ShiftAssignmentService.getMyShifts();

        setState(() {
          _shifts = shifts;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load shifts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }


  // Update shift status
  Future<void> _updateShiftStatus(String shiftId, String status) async {
    try {
      await ShiftAssignmentService.updateShiftStatus(shiftId, status);
      await _loadShifts(); // Reload shifts
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shift status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update shift: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get filtered shifts based on selected filter
  List<ShiftAssignment> get _filteredShifts {
    if (_selectedFilter == 'all') {
      return _shifts;
    }
    return _shifts.where((shift) => shift.status == _selectedFilter).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shifts'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShifts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Shifts'),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('in_progress', 'In Progress'),
                  const SizedBox(width: 8),
                  _buildFilterChip('completed', 'Completed'),
                ],
              ),
            ),
          ),
          
          // Shifts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredShifts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No shifts assigned yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your supervisor will assign shifts to you',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
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

  // Build filter chip
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.green.withOpacity(0.3),
      checkmarkColor: Colors.green,
    );
  }

  // Build shift card
  Widget _buildShiftCard(ShiftAssignment shift) {
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
            // Shift header
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
            
            // Shift description
            Text(
              shift.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            
            // Location and due date
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
                  'Due: ${shift.dueDate.day}/${shift.dueDate.month}/${shift.dueDate.year} at ${shift.dueDate.hour}:${shift.dueDate.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Supervisor info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Assigned by: ${shift.supervisorName}',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ],
            ),
            
            // Action buttons
            if (shift.status == 'pending' || shift.status == 'in_progress') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (shift.status == 'pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateShiftStatus(shift.id, 'in_progress'),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Start Shift'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (shift.status == 'in_progress') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateShiftStatus(shift.id, 'completed'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Complete Shift'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
