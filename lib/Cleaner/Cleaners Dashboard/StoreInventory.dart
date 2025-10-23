import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Services/InventoryProvider.dart';

class StoreInventory extends StatefulWidget {
  const StoreInventory({super.key});

  @override
  State<StoreInventory> createState() => _StoreInventoryState();
}

class _StoreInventoryState extends State<StoreInventory> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Load products from InventoryProvider
  void _loadProducts() {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    
    // Check if widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _products = inventoryProvider.storeInventory.entries.map((entry) {
          return {
            "name": entry.key,
            "image": entry.value["image"],
            "quantity": 0, // User's selected quantity
            "isSelected": false,
            "availableQuantity": entry.value["quantity"], // Available in store
          };
        }).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Inventory Page'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Show available quantities info
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Available items in your zone store. Select quantities and collect items.',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(index);
                      },
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleEndTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'End Task',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductCard(int index) {
    final product = _products[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          product["isSelected"] = !product["isSelected"];
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: product["isSelected"] ? Colors.green.shade100 : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Image.asset(
                  product["image"],
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
                if (product["isSelected"])
                  const Positioned(
                    top: 5,
                    right: 5,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product["name"],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            // Show available quantity
            Text(
              "Available: ${product["availableQuantity"]}",
              style: TextStyle(
                fontSize: 12,
                color: product["availableQuantity"] > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (product["quantity"] > 0) {
                        product["quantity"]--;
                      }
                    });
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                ),
                Text(
                  "${product["quantity"]}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Check if we can add more (don't exceed available quantity)
                      if (product["quantity"] < product["availableQuantity"]) {
                        product["quantity"]++;
                      }
                    });
                  },
                  icon: Icon(
                    Icons.add_circle, 
                    color: product["quantity"] < product["availableQuantity"] ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleEndTask() {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final selectedProducts = _products.where((product) => product["isSelected"] && product["quantity"] > 0).toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items selected!'), 
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String confirmationMessage = "You have selected the following items:\n\n";
    for (var product in selectedProducts) {
      confirmationMessage += "${product["name"]}: ${product["quantity"]} pcs\n";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Selection'),
          content: Text(confirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Get current user's name
                  final currentUser = FirebaseAuth.instance.currentUser;
                  String cleanerName = "Cleaner"; // Default fallback
                  
                  if (currentUser != null) {
                    // Try to get cleaner name from user data
                    try {
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .get();
                      if (userDoc.exists) {
                        cleanerName = userDoc.data()?['name'] ?? userDoc.data()?['fullName'] ?? "Cleaner";
                      }
                    } catch (e) {
                      print('Error getting cleaner name: $e');
                    }
                  }
                  
                  // Collect each selected item
                  for (var product in selectedProducts) {
                    await inventoryProvider.collectItem(
                      cleanerName,
                      product["name"],
                      product["quantity"],
                    );
                  }
                  
                  // Check if widget is still mounted before accessing context
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Successfully collected ${selectedProducts.length} item(s) from store!',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    
                    // Refresh the products list
                    _loadProducts();
                  }
                } catch (e) {
                  // Check if widget is still mounted before accessing context
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error collecting items: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Collect Items'),
            ),
          ],
        );
      },
    );
  }


}