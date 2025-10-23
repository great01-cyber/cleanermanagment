import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Services/InventoryProvider.dart';
import '../../Services/zone_inventory_service.dart';

class StoreInventoryPage extends StatefulWidget {
  const StoreInventoryPage({super.key});

  @override
  State<StoreInventoryPage> createState() => _StoreInventoryPageState();
}

class _StoreInventoryPageState extends State<StoreInventoryPage> {
  final Map<String, TextEditingController> _stockControllers = {};

  // Helper method to get item name from itemId
  String _getItemName(String itemId, InventoryProvider inventoryProvider) {
    try {
      final item = inventoryProvider.inventoryItems.firstWhere(
        (item) => item.itemId == itemId,
        orElse: () => InventoryItem(
          itemId: itemId,
          name: 'Unknown Item',
          description: '',
          image: '',
          category: '',
          unit: '',
          createdAt: DateTime.now(),
        ),
      );
      return item.name;
    } catch (e) {
      return 'Unknown Item';
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Inventory'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await inventoryProvider.refreshTransactions();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const Text("Update Store Inventory",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Input Fields for Updating Inventory
            Column(
              children: inventoryProvider.storeInventory.entries.map((entry) {
                // Create controller for this item if it doesn't exist
                if (!_stockControllers.containsKey(entry.key)) {
                  _stockControllers[entry.key] = TextEditingController();
                }
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Show Image Next to Product Name
                    Row(
                      children: [
                        Image.asset(entry.value["image"], width: 40,
                            height: 40),
                        const SizedBox(width: 10),
                        Text(entry.key, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _stockControllers[entry.key],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: entry.value["quantity"].toString(),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        int newStock =
                            int.tryParse(_stockControllers[entry.key]!.text) ??
                                entry.value["quantity"];
                        inventoryProvider.updateStock(entry.key, newStock);
                        _stockControllers[entry.key]!.clear();
                      },
                      child: const Text("Update"),
                    ),
                  ],
                );
              }).toList(),
            ),

            const Divider(),

            // Display Current Store Inventory
            const Text("Current Store Inventory",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: inventoryProvider.storeInventory.entries.map((entry) {
                  return ListTile(
                    leading: Image.asset(
                        entry.value["image"], width: 40, height: 40),
                    title: Text("${entry.key}: ${entry
                        .value["quantity"]} remaining"),
                  );
                }).toList(),
              ),
            ),

            const Divider(),

            // Display Items Collected by Cleaners
            const Text("Items Collected by Cleaners",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: inventoryProvider.transactions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No items collected yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Cleaners will appear here when they collect items',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: inventoryProvider.transactions.length,
                      itemBuilder: (context, index) {
                        var transaction = inventoryProvider.transactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Icon(
                                Icons.inventory_2,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              "${transaction.cleanerName} collected ${transaction.quantity} ${_getItemName(transaction.itemId, inventoryProvider)}",
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              "Date: ${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year} at ${transaction.timestamp.hour}:${transaction.timestamp.minute.toString().padLeft(2, '0')}",
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${transaction.quantity}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}