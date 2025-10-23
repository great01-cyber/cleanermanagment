import 'package:flutter/material.dart';
import '../Services/zone_inventory_service.dart';
import '../Services/user_management_service.dart';

class AdminStoreOversightScreen extends StatefulWidget {
  const AdminStoreOversightScreen({super.key});

  @override
  State<AdminStoreOversightScreen> createState() => _AdminStoreOversightScreenState();
}

class _AdminStoreOversightScreenState extends State<AdminStoreOversightScreen> {
  List<ZoneModel> _zones = [];
  List<ZoneInventory> _allZoneInventory = [];
  List<InventoryTransaction> _allTransactions = [];
  bool _isLoading = true;
  String _selectedTab = 'inventory';
  String? _selectedZone;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ZoneInventoryService.getAllZones(),
        ZoneInventoryService.getAllZoneInventory(),
        ZoneInventoryService.getAllTransactions(),
      ]);
      
      setState(() {
        _zones = results[0] as List<ZoneModel>;
        _allZoneInventory = results[1] as List<ZoneInventory>;
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
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ZoneInventory> get _filteredInventory {
    if (_selectedZone == null) return _allZoneInventory;
    return _allZoneInventory.where((item) => item.zoneId == _selectedZone).toList();
  }

  List<InventoryTransaction> get _filteredTransactions {
    if (_selectedZone == null) return _allTransactions;
    return _allTransactions.where((transaction) => transaction.zoneId == _selectedZone).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Management'),
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
          // Zone Filter
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                const Text('Filter by Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedZone,
                    hint: const Text('All Zones'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Zones'),
                      ),
                      ..._zones.map((zone) => DropdownMenuItem<String>(
                        value: zone.zoneId,
                        child: Text(zone.name),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedZone = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('inventory', 'Store Inventory', Icons.inventory_2),
                ),
                Expanded(
                  child: _buildTabButton('transactions', 'Cleaner Transactions', Icons.history),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'inventory'
                    ? _buildInventoryView()
                    : _buildTransactionsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.deepPurple : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryView() {
    final filteredInventory = _filteredInventory;
    
    if (filteredInventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No inventory items found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Items will appear here when supervisors add them to their zones',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Group inventory by zone
    final Map<String, List<ZoneInventory>> inventoryByZone = {};
    for (final item in filteredInventory) {
      if (!inventoryByZone.containsKey(item.zoneId)) {
        inventoryByZone[item.zoneId] = [];
      }
      inventoryByZone[item.zoneId]!.add(item);
    }

    return ListView.builder(
      itemCount: inventoryByZone.length,
      itemBuilder: (context, index) {
        final zoneId = inventoryByZone.keys.elementAt(index);
        final zoneItems = inventoryByZone[zoneId]!;
        final zone = _zones.firstWhere((z) => z.zoneId == zoneId, orElse: () => ZoneModel(
          zoneId: zoneId,
          name: 'Unknown Zone',
          description: '',
          createdAt: DateTime.now(),
        ));

        return Card(
          margin: const EdgeInsets.all(16),
          child: ExpansionTile(
            title: Text(
              zone.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text('${zoneItems.length} items • ${zone.description}'),
            children: zoneItems.map((item) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    item.itemId.isNotEmpty ? item.itemId[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  item.itemId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Last updated: ${item.lastUpdated.day}/${item.lastUpdated.month}/${item.lastUpdated.year} by ${item.updatedBy}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.quantity > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      color: item.quantity > 0 ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsView() {
    final filteredTransactions = _filteredTransactions;
    
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions will appear here when cleaners take items',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        final zone = _zones.firstWhere((z) => z.zoneId == transaction.zoneId, orElse: () => ZoneModel(
          zoneId: transaction.zoneId,
          name: 'Unknown Zone',
          description: '',
          createdAt: DateTime.now(),
        ));

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: transaction.transactionType == 'collection' ? Colors.orange : Colors.blue,
              child: Icon(
                transaction.transactionType == 'collection' ? Icons.remove : Icons.add,
                color: Colors.white,
              ),
            ),
            title: Text(
              '${transaction.cleanerName} ${transaction.transactionType == 'collection' ? 'took' : 'restocked'} ${transaction.quantity} ${transaction.itemId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zone: ${zone.name}'),
                Text(
                  '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year} at ${transaction.timestamp.hour}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
                ),
                if (transaction.notes != null && transaction.notes!.isNotEmpty)
                  Text('Notes: ${transaction.notes}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: transaction.transactionType == 'collection' 
                    ? Colors.orange.withOpacity(0.1) 
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${transaction.transactionType == 'collection' ? '-' : '+'}${transaction.quantity}',
                style: TextStyle(
                  color: transaction.transactionType == 'collection' 
                      ? Colors.orange[700] 
                      : Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
