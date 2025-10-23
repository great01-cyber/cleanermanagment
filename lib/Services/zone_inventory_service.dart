import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_config.dart';
import 'user_management_service.dart';

// Data model for a zone
class ZoneModel {
  final String zoneId;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  ZoneModel({
    required this.zoneId,
    required this.name,
    required this.description,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'zoneId': zoneId,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ZoneModel.fromMap(Map<String, dynamic> map) {
    return ZoneModel(
      zoneId: map['zoneId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Data model for an inventory item
class InventoryItem {
  final String itemId;
  final String name;
  final String description;
  final String image;
  final String category;
  final String unit;
  final DateTime createdAt;

  InventoryItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.image,
    required this.category,
    required this.unit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'description': description,
      'image': image,
      'category': category,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      category: map['category'] ?? '',
      unit: map['unit'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}


// Data model for zone inventory (quantity of item in a zone)
class ZoneInventory {
  final String zoneId;
  final String itemId;
  final int quantity;
  final DateTime lastUpdated;
  final String updatedBy;

  ZoneInventory({
    required this.zoneId,
    required this.itemId,
    required this.quantity,
    required this.lastUpdated,
    required this.updatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'zoneId': zoneId,
      'itemId': itemId,
      'quantity': quantity,
      'lastUpdated': lastUpdated.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  factory ZoneInventory.fromMap(Map<String, dynamic> map) {
    return ZoneInventory(
      zoneId: map['zoneId'] ?? '',
      itemId: map['itemId'] ?? '',
      quantity: map['quantity'] ?? 0,
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
      updatedBy: map['updatedBy'] ?? '',
    );
  }
}

// Data model for inventory transactions
class InventoryTransaction {
  final String transactionId;
  final String zoneId;
  final String itemId;
  final String cleanerId;
  final String cleanerName;
  final int quantity;
  final String transactionType; // 'collection' or 'restock'
  final DateTime timestamp;
  final String? notes;

  InventoryTransaction({
    required this.transactionId,
    required this.zoneId,
    required this.itemId,
    required this.cleanerId,
    required this.cleanerName,
    required this.quantity,
    required this.transactionType,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'zoneId': zoneId,
      'itemId': itemId,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'quantity': quantity,
      'transactionType': transactionType,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    return InventoryTransaction(
      transactionId: map['transactionId'] ?? '',
      zoneId: map['zoneId'] ?? '',
      itemId: map['itemId'] ?? '',
      cleanerId: map['cleanerId'] ?? '',
      cleanerName: map['cleanerName'] ?? '',
      quantity: map['quantity'] ?? 0,
      transactionType: map['transactionType'] ?? 'collection',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'],
    );
  }
}

// Service for managing zone-based inventory
class ZoneInventoryService {
  static final FirebaseAuth _auth = FirebaseConfig.auth;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    try {
      final zonesSnapshot = await _firestore.collection('zones').limit(1).get();
      return zonesSnapshot.docs.isEmpty;
    } catch (e) {
      return true; // If error, assume migration needed
    }
  }

  // Migrate hardcoded zones to database
  static Future<void> migrateZones() async {
    try {
      final zones = [
        ZoneModel(
          zoneId: 'zoneA',
          name: 'Zone A',
          description: 'Building 1, Floors 1-5',
          createdAt: DateTime.now(),
        ),
        ZoneModel(
          zoneId: 'zoneB',
          name: 'Zone B',
          description: 'Building 2, Floors 1-3',
          createdAt: DateTime.now(),
        ),
        ZoneModel(
          zoneId: 'zoneC',
          name: 'Zone C',
          description: 'Building 3, Floors 1-4',
          createdAt: DateTime.now(),
        ),
        ZoneModel(
          zoneId: 'zoneD',
          name: 'Zone D',
          description: 'Outdoor Areas',
          createdAt: DateTime.now(),
        ),
        ZoneModel(
          zoneId: 'zoneE',
          name: 'Zone E',
          description: 'Common Areas',
          createdAt: DateTime.now(),
        ),
      ];

      final batch = _firestore.batch();
      for (final zone in zones) {
        final zoneRef = _firestore.collection('zones').doc(zone.zoneId);
        batch.set(zoneRef, zone.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to migrate zones: $e');
    }
  }

  // Migrate hardcoded inventory items to database
  static Future<void> migrateInventoryItems() async {
    try {
      final items = [
        InventoryItem(
          itemId: 'blue_paper_towel',
          name: 'Blue Paper Towel',
          description: 'Cleaning paper towel',
          image: 'assets/images/blue_paper_towel.png',
          category: 'paper_products',
          unit: 'rolls',
          createdAt: DateTime.now(),
        ),
        InventoryItem(
          itemId: 'red_mop',
          name: 'Red Mop',
          description: 'Red cleaning mop',
          image: 'assets/images/red_mop.PNG',
          category: 'cleaning_tools',
          unit: 'pieces',
          createdAt: DateTime.now(),
        ),
        InventoryItem(
          itemId: 'yellow_mop',
          name: 'Yellow Mop',
          description: 'Yellow cleaning mop',
          image: 'assets/images/yellow_mop.PNG',
          category: 'cleaning_tools',
          unit: 'pieces',
          createdAt: DateTime.now(),
        ),
        InventoryItem(
          itemId: 'blue_mop',
          name: 'Blue Mop',
          description: 'Blue cleaning mop',
          image: 'assets/images/blue_mop.PNG',
          category: 'cleaning_tools',
          unit: 'pieces',
          createdAt: DateTime.now(),
        ),
        InventoryItem(
          itemId: 'spray_bottle',
          name: 'Spray Bottle',
          description: 'Cleaning spray bottle',
          image: 'assets/images/spray_can.jpg',
          category: 'cleaning_tools',
          unit: 'pieces',
          createdAt: DateTime.now(),
        ),
        InventoryItem(
          itemId: 'white_tissue_paper',
          name: 'White Tissue Paper',
          description: 'White tissue paper',
          image: 'assets/images/white_tissue_pepper.jpg',
          category: 'paper_products',
          unit: 'boxes',
          createdAt: DateTime.now(),
        ),
      ];

      final batch = _firestore.batch();
      for (final item in items) {
        final itemRef = _firestore.collection('inventory_items').doc(item.itemId);
        batch.set(itemRef, item.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to migrate inventory items: $e');
    }
  }

  // Create zone inventory records (each zone gets all items with 0 quantity)
  static Future<void> createZoneInventoryRecords() async {
    try {
      final zones = ['zoneA', 'zoneB', 'zoneC', 'zoneD', 'zoneE'];
      final items = ['blue_paper_towel', 'red_mop', 'yellow_mop', 'blue_mop', 'spray_bottle', 'white_tissue_paper'];

      final batch = _firestore.batch();
      for (final zoneId in zones) {
        for (final itemId in items) {
          final recordRef = _firestore.collection('zone_inventory').doc('${zoneId}_$itemId');
          final record = ZoneInventory(
            zoneId: zoneId,
            itemId: itemId,
            quantity: 0,
            lastUpdated: DateTime.now(),
            updatedBy: 'system',
          );
          batch.set(recordRef, record.toMap());
        }
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create zone inventory records: $e');
    }
  }

  // Run complete migration
  static Future<void> runMigration() async {
    try {
      if (await isMigrationNeeded()) {
        await migrateZones();
        await migrateInventoryItems();
        await createZoneInventoryRecords();
        print('Zone inventory migration completed successfully');
      }
    } catch (e) {
      throw Exception('Migration failed: $e');
    }
  }

  // Get all zones
  static Future<List<ZoneModel>> getAllZones() async {
    try {
      final snapshot = await _firestore.collection('zones').get();
      return snapshot.docs.map((doc) => ZoneModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get zones: $e');
    }
  }

  // Get all inventory items
  static Future<List<InventoryItem>> getAllInventoryItems() async {
    try {
      final snapshot = await _firestore.collection('inventory_items').get();
      return snapshot.docs.map((doc) => InventoryItem.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get inventory items: $e');
    }
  }

  // Get all zone inventory
  static Future<List<ZoneInventory>> getAllZoneInventory() async {
    try {
      final snapshot = await _firestore.collection('zone_inventory').get();
      return snapshot.docs.map((doc) => ZoneInventory.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get zone inventory: $e');
    }
  }

  // Get all transactions
  static Future<List<InventoryTransaction>> getAllTransactions() async {
    try {
      final snapshot = await _firestore.collection('inventory_transactions').get();
      return snapshot.docs.map((doc) => InventoryTransaction.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  // Get zone inventory for a specific zone
  static Future<List<ZoneInventory>> getZoneInventory(String zoneId) async {
    try {
      final snapshot = await _firestore
          .collection('zone_inventory')
          .where('zoneId', isEqualTo: zoneId)
          .get();
      return snapshot.docs.map((doc) => ZoneInventory.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get zone inventory: $e');
    }
  }

  // Get zones assigned to a supervisor
  static Future<List<ZoneModel>> getSupervisorZones(String supervisorId) async {
    try {
      // Get supervisor data to find their assigned zone
      final supervisorDoc = await _firestore.collection('users').doc(supervisorId).get();
      if (!supervisorDoc.exists) {
        throw Exception('Supervisor not found');
      }
      
      final supervisorData = supervisorDoc.data()!;
      final assignedZone = supervisorData['assignedZone'] as String;
      
      // Get the zone details
      final zoneDoc = await _firestore.collection('zones').doc(assignedZone).get();
      if (!zoneDoc.exists) {
        throw Exception('Zone not found');
      }
      
      return [ZoneModel.fromMap(zoneDoc.data()!)];
    } catch (e) {
      throw Exception('Failed to get supervisor zones: $e');
    }
  }

  // Get zones accessible to a cleaner (through their supervisor)
  static Future<List<ZoneModel>> getCleanerZones(String cleanerId) async {
    try {
      // Get cleaner data to find their supervisor
      final cleanerDoc = await _firestore.collection('users').doc(cleanerId).get();
      if (!cleanerDoc.exists) {
        throw Exception('Cleaner not found');
      }
      
      final cleanerData = cleanerDoc.data()!;
      final supervisorId = cleanerData['supervisorId'] as String;
      
      // Get supervisor's zones
      return await getSupervisorZones(supervisorId);
    } catch (e) {
      throw Exception('Failed to get cleaner zones: $e');
    }
  }

  // Update zone inventory quantity
  static Future<void> updateZoneInventory(String zoneId, String itemId, int quantity) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final recordRef = _firestore.collection('zone_inventory').doc('${zoneId}_$itemId');
      await recordRef.update({
        'quantity': quantity,
        'lastUpdated': DateTime.now().toIso8601String(),
        'updatedBy': currentUser.uid,
      });
    } catch (e) {
      throw Exception('Failed to update zone inventory: $e');
    }
  }

  // Collect item from zone (cleaner takes item)
  static Future<void> collectItem(String zoneId, String itemId, int quantity, String cleanerId, String cleanerName) async {
    try {
      // Check if enough quantity available
      final recordRef = _firestore.collection('zone_inventory').doc('${zoneId}_$itemId');
      final recordDoc = await recordRef.get();
      
      if (!recordDoc.exists) {
        throw Exception('Item not found in zone');
      }
      
      final currentQuantity = recordDoc.data()!['quantity'] as int;
      if (currentQuantity < quantity) {
        throw Exception('Insufficient quantity available');
      }

      // Update quantity
      final newQuantity = currentQuantity - quantity;
      await recordRef.update({
        'quantity': newQuantity,
        'lastUpdated': DateTime.now().toIso8601String(),
        'updatedBy': cleanerId,
      });

      // Record transaction
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      final transaction = InventoryTransaction(
        transactionId: transactionId,
        zoneId: zoneId,
        itemId: itemId,
        cleanerId: cleanerId,
        cleanerName: cleanerName,
        quantity: quantity,
        transactionType: 'collection',
        timestamp: DateTime.now(),
      );

      await _firestore.collection('inventory_transactions').doc(transactionId).set(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to collect item: $e');
    }
  }

  // Get inventory transactions for a zone
  static Future<List<InventoryTransaction>> getZoneTransactions(String zoneId) async {
    try {
      final snapshot = await _firestore
          .collection('inventory_transactions')
          .where('zoneId', isEqualTo: zoneId)
          .get();
      
      final transactions = snapshot.docs.map((doc) => InventoryTransaction.fromMap(doc.data())).toList();
      
      // Sort by timestamp in descending order (newest first) on client side
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return transactions;
    } catch (e) {
      throw Exception('Failed to get zone transactions: $e');
    }
  }

  // ========== ZONE MANAGEMENT METHODS ==========

  // Create a new zone
  static Future<void> createZone({
    required String name,
    required String description,
  }) async {
    try {
      final zoneId = DateTime.now().millisecondsSinceEpoch.toString();
      final zone = ZoneModel(
        zoneId: zoneId,
        name: name,
        description: description,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('zones').doc(zoneId).set(zone.toMap());
    } catch (e) {
      throw Exception('Failed to create zone: $e');
    }
  }

  // Update a zone
  static Future<void> updateZone(
    String zoneId, {
    required String name,
    required String description,
  }) async {
    try {
      await _firestore.collection('zones').doc(zoneId).update({
        'name': name,
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to update zone: $e');
    }
  }

  // Update zone status
  static Future<void> updateZoneStatus(String zoneId, bool isActive) async {
    try {
      await _firestore.collection('zones').doc(zoneId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Failed to update zone status: $e');
    }
  }

  // Delete a zone
  static Future<void> deleteZone(String zoneId) async {
    try {
      await _firestore.collection('zones').doc(zoneId).delete();
    } catch (e) {
      throw Exception('Failed to delete zone: $e');
    }
  }


}
