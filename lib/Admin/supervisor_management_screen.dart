import 'package:flutter/material.dart';
import '../Services/user_management_service.dart';
import '../Services/firebase_config.dart';
import 'add_supervisor_screen.dart';

class SupervisorManagementScreen extends StatefulWidget {
  const SupervisorManagementScreen({super.key});

  @override
  State<SupervisorManagementScreen> createState() => _SupervisorManagementScreenState();
}

class _SupervisorManagementScreenState extends State<SupervisorManagementScreen> {
  List<SupervisorModel> _supervisors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Zone? _filterZone;

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
  }

  Future<void> _loadSupervisors() async {
    try {
      final supervisors = await UserManagementService.getAllSupervisors();
      setState(() {
        _supervisors = supervisors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load supervisors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<SupervisorModel> get _filteredSupervisors {
    return _supervisors.where((supervisor) {
      final matchesSearch = supervisor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          supervisor.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesZone = _filterZone == null || supervisor.assignedZone == _filterZone;
      return matchesSearch && matchesZone;
    }).toList();
  }

  Future<void> _toggleSupervisorStatus(SupervisorModel supervisor) async {
    try {
      await UserManagementService.updateSupervisorZone(
        supervisor.uid,
        supervisor.assignedZone,
      );
      await _loadSupervisors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Supervisor ${supervisor.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update supervisor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSupervisor(SupervisorModel supervisor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supervisor'),
        content: Text('Are you sure you want to delete ${supervisor.name}? This will reassign all their cleaners to unassigned status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserManagementService.deleteUser(supervisor.uid);
        await _loadSupervisors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supervisor deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete supervisor: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupervisors,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search supervisors...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Zone?>(
                        value: _filterZone,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Zone',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Zones'),
                          ),
                          ...Zone.values.map(
                            (zone) => DropdownMenuItem(
                              value: zone,
                              child: Text(zone.description),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterZone = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddSupervisorScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadSupervisors();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Supervisor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Supervisors List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSupervisors.isEmpty
                    ? const Center(
                        child: Text(
                          'No supervisors found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSupervisors.length,
                        itemBuilder: (context, index) {
                          final supervisor = _filteredSupervisors[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getZoneColor(supervisor.assignedZone),
                                child: Text(
                                  supervisor.name.isNotEmpty ? supervisor.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                supervisor.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: supervisor.isActive ? null : Colors.grey,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(supervisor.email),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          supervisor.assignedZone.description,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: _getZoneColor(supervisor.assignedZone).withOpacity(0.2),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          '${supervisor.assignedCleaners.length} Cleaners',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: Colors.blue.withOpacity(0.2),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          supervisor.isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: supervisor.isActive 
                                            ? Colors.green.withOpacity(0.2) 
                                            : Colors.red.withOpacity(0.2),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view_cleaners',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.people),
                                        const SizedBox(width: 8),
                                        Text('View Cleaners (${supervisor.assignedCleaners.length})'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(supervisor.isActive ? Icons.block : Icons.check_circle),
                                        const SizedBox(width: 8),
                                        Text(supervisor.isActive ? 'Deactivate' : 'Activate'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'view_cleaners') {
                                    _viewSupervisorCleaners(supervisor);
                                  } else if (value == 'toggle') {
                                    _toggleSupervisorStatus(supervisor);
                                  } else if (value == 'delete') {
                                    _deleteSupervisor(supervisor);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getZoneColor(Zone zone) {
    switch (zone) {
      case Zone.zoneA:
        return Colors.red;
      case Zone.zoneB:
        return Colors.blue;
      case Zone.zoneC:
        return Colors.green;
      case Zone.zoneD:
        return Colors.orange;
      case Zone.zoneE:
        return Colors.purple;
    }
  }

  void _viewSupervisorCleaners(SupervisorModel supervisor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cleaners in ${supervisor.assignedZone.description}'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: supervisor.assignedCleaners.isEmpty
              ? const Center(child: Text('No cleaners assigned'))
              : ListView.builder(
                  itemCount: supervisor.assignedCleaners.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.cleaning_services, color: Colors.white),
                      ),
                      title: Text('Cleaner ${index + 1}'),
                      subtitle: Text('ID: ${supervisor.assignedCleaners[index]}'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
