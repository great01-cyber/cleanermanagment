import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'zone_inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  // Zone-based inventory data
  List<ZoneModel> _zones = [];
  List<InventoryItem> _inventoryItems = [];
  List<ZoneInventory> _zoneInventory = [];
  List<InventoryTransaction> _transactions = [];
  String? _currentZoneId;
  bool _isLoading = false;
  bool _migrationCompleted = false;

  // Getters
  List<ZoneModel> get zones => _zones;
  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<ZoneInventory> get zoneInventory => _zoneInventory;
  List<InventoryTransaction> get transactions => _transactions;
  String? get currentZoneId => _currentZoneId;
  bool get isLoading => _isLoading;
  bool get migrationCompleted => _migrationCompleted;

  // Get current zone inventory as map (for backward compatibility)
  Map<String, Map<String, dynamic>> get storeInventory {
    final Map<String, Map<String, dynamic>> result = {};
    
    for (final zoneInv in _zoneInventory) {
      if (zoneInv.zoneId == _currentZoneId) {
        final item = _inventoryItems.firstWhere(
          (item) => item.itemId == zoneInv.itemId,
          orElse: () => InventoryItem(
            itemId: zoneInv.itemId,
            name: zoneInv.itemId,
            description: '',
            image: '',
            category: '',
            unit: '',
            createdAt: DateTime.now(),
          ),
        );
        
        result[item.name] = {
          'quantity': zoneInv.quantity,
          'image': item.image,
          'itemId': item.itemId,
        };
      }
    }
    
    return result;
  }

  // Get inventory records (transactions) as list (for backward compatibility)
  List<Map<String, dynamic>> get inventoryRecords {
    return _transactions.map((transaction) => {
      'cleaner': transaction.cleanerName,
      'product': _inventoryItems.firstWhere(
        (item) => item.itemId == transaction.itemId,
        orElse: () => InventoryItem(
          itemId: transaction.itemId,
          name: transaction.itemId,
          description: '',
          image: '',
          category: '',
          unit: '',
          createdAt: DateTime.now(),
        ),
      ).name,
      'quantity': transaction.quantity,
      'date': transaction.timestamp.toString().substring(0, 10),
      'image': _inventoryItems.firstWhere(
        (item) => item.itemId == transaction.itemId,
        orElse: () => InventoryItem(
          itemId: transaction.itemId,
          name: transaction.itemId,
          description: '',
          image: '',
          category: '',
          unit: '',
          createdAt: DateTime.now(),
        ),
      ).image,
    }).toList();
  }

  // Initialize the provider and run migration if needed
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if migration is needed and run it
      if (await ZoneInventoryService.isMigrationNeeded()) {
        await ZoneInventoryService.runMigration();
        _migrationCompleted = true;
      }

      // Load data
      await _loadData();
    } catch (e) {
      print('Error initializing inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all data from database
  Future<void> _loadData() async {
    try {
      _zones = await ZoneInventoryService.getAllZones();
      _inventoryItems = await ZoneInventoryService.getAllInventoryItems();
      
      // Set current zone based on user role
      await _setCurrentZone();
      
      if (_currentZoneId != null) {
        _zoneInventory = await ZoneInventoryService.getZoneInventory(_currentZoneId!);
        _transactions = await ZoneInventoryService.getZoneTransactions(_currentZoneId!);
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  // Set current zone based on user role
  Future<void> _setCurrentZone() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Check if user is supervisor or cleaner
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String;

      if (userRole == 'supervisor') {
        // Get supervisor's assigned zone
        final zones = await ZoneInventoryService.getSupervisorZones(currentUser.uid);
        if (zones.isNotEmpty) {
          _currentZoneId = zones.first.zoneId;
        }
      } else if (userRole == 'cleaner') {
        // Get cleaner's accessible zones (through supervisor)
        final zones = await ZoneInventoryService.getCleanerZones(currentUser.uid);
        if (zones.isNotEmpty) {
          _currentZoneId = zones.first.zoneId;
        }
      }
    } catch (e) {
      print('Error setting current zone: $e');
    }
  }

  // Function to allow the supervisor to update stock levels
  Future<void> updateStock(String product, int quantity) async {
    if (_currentZoneId == null) return;

    try {
      // Find the item ID from product name
      final item = _inventoryItems.firstWhere(
        (item) => item.name == product,
        orElse: () => throw Exception('Product not found'),
      );

      await ZoneInventoryService.updateZoneInventory(_currentZoneId!, item.itemId, quantity);
      await _loadData(); // Reload data
      notifyListeners();
    } catch (e) {
      print('Error updating stock: $e');
      throw Exception('Failed to update stock: $e');
    }
  }

  // Function for cleaners to collect items
  Future<void> collectItem(String cleanerName, String product, int quantity) async {
    if (_currentZoneId == null) return;

    try {
      // Find the item ID from product name in inventory items
      final item = _inventoryItems.firstWhere(
        (item) => item.name == product,
        orElse: () => throw Exception('Product not found: $product'),
      );

      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      // Check if item exists in current zone inventory
      if (!storeInventory.containsKey(product)) {
        throw Exception('Product not available in your zone: $product');
      }

      // Check if enough quantity is available
      final availableQuantity = storeInventory[product]!['quantity'] as int;
      if (availableQuantity < quantity) {
        throw Exception('Insufficient quantity available. Available: $availableQuantity, Requested: $quantity');
      }

      await ZoneInventoryService.collectItem(
        _currentZoneId!,
        item.itemId,
        quantity,
        currentUser.uid,
        cleanerName,
      );

      // Reload data to get updated inventory and transactions
      await _loadData();
      notifyListeners();
    } catch (e) {
      print('Error collecting item: $e');
      throw Exception('Failed to collect item: $e');
    }
  }

  // Add inventory record (for backward compatibility)
  void addInventoryRecord(String cleanerName, String product, int quantity, String image) {
    // This method is kept for backward compatibility but now handled by collectItem
    print('addInventoryRecord called - use collectItem instead');
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadData();
    notifyListeners();
  }

  // Refresh transactions only (for supervisor page)
  Future<void> refreshTransactions() async {
    if (_currentZoneId != null) {
      _transactions = await ZoneInventoryService.getZoneTransactions(_currentZoneId!);
      notifyListeners();
    }
  }
}