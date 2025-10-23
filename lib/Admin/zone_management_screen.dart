import 'package:flutter/material.dart';
import '../Services/zone_inventory_service.dart';
import '../Services/firebase_config.dart';

class ZoneManagementScreen extends StatefulWidget {
  const ZoneManagementScreen({super.key});

  @override
  State<ZoneManagementScreen> createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends State<ZoneManagementScreen> {
  List<ZoneModel> _zones = [];
  List<ZoneInventory> _allInventory = [];
  List<InventoryTransaction> _allTransactions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final results = await Future.wait([
        ZoneInventoryService.getAllZones(),
        ZoneInventoryService.getAllZoneInventory(),
        ZoneInventoryService.getAllTransactions(),
      ]);
      
      setState(() {
        _zones = results[0] as List<ZoneModel>;
        _allInventory = results[1] as List<ZoneInventory>;
        _allTransactions = results[2] as List<InventoryTransaction>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load zones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ZoneModel> get _filteredZones {
    return _zones.where((zone) {
      return zone.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          zone.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Get inventory count for a zone
  int _getZoneInventoryCount(String zoneId) {
    return _allInventory.where((item) => item.zoneId == zoneId).length;
  }

  // Get total quantity for a zone
  int _getZoneTotalQuantity(String zoneId) {
    return _allInventory
        .where((item) => item.zoneId == zoneId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  // Get transaction count for a zone
  int _getZoneTransactionCount(String zoneId) {
    return _allTransactions.where((transaction) => transaction.zoneId == zoneId).length;
  }

  // Get recent transactions for a zone
  List<InventoryTransaction> _getZoneRecentTransactions(String zoneId) {
    final zoneTransactions = _allTransactions
        .where((transaction) => transaction.zoneId == zoneId)
        .toList();
    zoneTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return zoneTransactions.take(3).toList();
  }

  Future<void> _toggleZoneStatus(ZoneModel zone) async {
    try {
      await ZoneInventoryService.updateZoneStatus(zone.zoneId, !zone.isActive);
      await _loadZones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zone ${zone.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update zone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteZone(ZoneModel zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Are you sure you want to delete ${zone.name}? This action cannot be undone.'),
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
        await ZoneInventoryService.deleteZone(zone.zoneId);
        await _loadZones();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zone deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete zone: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddZoneDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Zone Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                try {
                  await ZoneInventoryService.createZone(
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                  Navigator.of(context).pop(true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create zone: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadZones();
    }
  }

  Future<void> _showEditZoneDialog(ZoneModel zone) async {
    final nameController = TextEditingController(text: zone.name);
    final descriptionController = TextEditingController(text: zone.description);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Zone Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                try {
                  await ZoneInventoryService.updateZone(
                    zone.zoneId,
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                  Navigator.of(context).pop(true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update zone: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadZones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadZones,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search zones...',
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
          ),
          // Zones List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredZones.isEmpty
                    ? const Center(
                        child: Text(
                          'No zones found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredZones.length,
                        itemBuilder: (context, index) {
                          final zone = _filteredZones[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getZoneColor(zone.name),
                                child: Text(
                                  zone.name.isNotEmpty ? zone.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                zone.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: zone.isActive ? null : Colors.grey,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(zone.description),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          zone.isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: zone.isActive 
                                            ? Colors.green.withOpacity(0.2) 
                                            : Colors.red.withOpacity(0.2),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Created: ${_formatDate(zone.createdAt)}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Store Statistics
                                  Row(
                                    children: [
                                      _buildStatChip(
                                        '${_getZoneInventoryCount(zone.zoneId)} items',
                                        Colors.blue,
                                        Icons.inventory_2,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        '${_getZoneTotalQuantity(zone.zoneId)} total',
                                        Colors.orange,
                                        Icons.shopping_cart,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatChip(
                                        '${_getZoneTransactionCount(zone.zoneId)} transactions',
                                        Colors.purple,
                                        Icons.history,
                                      ),
                                    ],
                                  ),
                                  // Recent transactions
                                  if (_getZoneRecentTransactions(zone.zoneId).isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Recent activity:',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                    ),
                                    ..._getZoneRecentTransactions(zone.zoneId).map((transaction) => 
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 2),
                                        child: Text(
                                          '• ${transaction.cleanerName} ${transaction.transactionType == 'collection' ? 'took' : 'restocked'} ${transaction.quantity} ${transaction.itemId}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit),
                                        const SizedBox(width: 8),
                                        const Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(zone.isActive ? Icons.block : Icons.check_circle),
                                        const SizedBox(width: 8),
                                        Text(zone.isActive ? 'Deactivate' : 'Activate'),
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
                                  if (value == 'edit') {
                                    _showEditZoneDialog(zone);
                                  } else if (value == 'toggle') {
                                    _toggleZoneStatus(zone);
                                  } else if (value == 'delete') {
                                    _deleteZone(zone);
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddZoneDialog,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getZoneColor(String zoneName) {
    // Generate consistent colors based on zone name
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    final index = zoneName.hashCode % colors.length;
    return colors[index.abs()];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
