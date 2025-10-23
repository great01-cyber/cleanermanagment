import 'package:flutter/material.dart';
import '../Services/user_management_service.dart';
import '../Services/firebase_config.dart';
import 'add_cleaner_screen.dart';

class CleanerManagementScreen extends StatefulWidget {
  const CleanerManagementScreen({super.key});

  @override
  State<CleanerManagementScreen> createState() => _CleanerManagementScreenState();
}

class _CleanerManagementScreenState extends State<CleanerManagementScreen> {
  List<CleanerModel> _cleaners = [];
  List<SupervisorModel> _supervisors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterSupervisor;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        UserManagementService.getAllCleaners(),
        UserManagementService.getAllSupervisors(),
      ]);
      
      setState(() {
        _cleaners = results[0] as List<CleanerModel>;
        _supervisors = results[1] as List<SupervisorModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<CleanerModel> get _filteredCleaners {
    return _cleaners.where((cleaner) {
      final matchesSearch = cleaner.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cleaner.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSupervisor = _filterSupervisor == null || cleaner.supervisorId == _filterSupervisor;
      return matchesSearch && matchesSupervisor;
    }).toList();
  }

  Future<void> _toggleCleanerStatus(CleanerModel cleaner) async {
    try {
      // Update cleaner status in Firestore
      await UserManagementService.updateSupervisorZone(
        cleaner.uid,
        Zone.zoneA, // This is a placeholder, we need a proper method
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleaner ${cleaner.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update cleaner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCleaner(CleanerModel cleaner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cleaner'),
        content: Text('Are you sure you want to delete ${cleaner.name}? This action cannot be undone.'),
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
        await UserManagementService.deleteUser(cleaner.uid);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cleaner deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete cleaner: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _reassignCleaner(CleanerModel cleaner) async {
    final newSupervisor = await showDialog<SupervisorModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Cleaner'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView.builder(
            itemCount: _supervisors.length,
            itemBuilder: (context, index) {
              final supervisor = _supervisors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getZoneColor(supervisor.assignedZone),
                  child: Text(
                    supervisor.name.isNotEmpty ? supervisor.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(supervisor.name),
                subtitle: Text(supervisor.assignedZone.description),
                onTap: () => Navigator.of(context).pop(supervisor),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (newSupervisor != null) {
      try {
        await UserManagementService.assignCleanerToSupervisor(
          cleaner.uid,
          newSupervisor.uid,
          newSupervisor.name,
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cleaner reassigned to ${newSupervisor.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reassign cleaner: $e'),
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
        title: const Text('Cleaner Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                    hintText: 'Search cleaners...',
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
                      child: DropdownButtonFormField<String?>(
                        value: _filterSupervisor,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Supervisor',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Supervisors'),
                          ),
                          ..._supervisors.map(
                            (supervisor) => DropdownMenuItem(
                              value: supervisor.uid,
                              child: Text(supervisor.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterSupervisor = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddCleanerScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Cleaner'),
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
          // Cleaners List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCleaners.isEmpty
                    ? const Center(
                        child: Text(
                          'No cleaners found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCleaners.length,
                        itemBuilder: (context, index) {
                          final cleaner = _filteredCleaners[index];
                          final supervisor = _supervisors.firstWhere(
                            (s) => s.uid == cleaner.supervisorId,
                            orElse: () => SupervisorModel(
                              uid: '',
                              email: '',
                              name: 'Unassigned',
                              assignedZone: Zone.zoneA,
                              createdAt: DateTime.now(),
                            ),
                          );
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  cleaner.name.isNotEmpty ? cleaner.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                cleaner.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cleaner.isActive ? null : Colors.grey,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cleaner.email),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          'Supervisor: ${supervisor.name}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: Colors.blue.withOpacity(0.2),
                                      ),
                                      const SizedBox(width: 8),
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
                                          cleaner.isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: cleaner.isActive 
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
                                    value: 'reassign',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.swap_horiz),
                                        const SizedBox(width: 8),
                                        const Text('Reassign to Supervisor'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(cleaner.isActive ? Icons.block : Icons.check_circle),
                                        const SizedBox(width: 8),
                                        Text(cleaner.isActive ? 'Deactivate' : 'Activate'),
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
                                  if (value == 'reassign') {
                                    _reassignCleaner(cleaner);
                                  } else if (value == 'toggle') {
                                    _toggleCleanerStatus(cleaner);
                                  } else if (value == 'delete') {
                                    _deleteCleaner(cleaner);
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
}
