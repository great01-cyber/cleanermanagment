import 'package:flutter/material.dart';

class OrderSuppliesPage extends StatefulWidget {
  @override
  _OrderSuppliesPageState createState() => _OrderSuppliesPageState();
}

class _OrderSuppliesPageState extends State<OrderSuppliesPage> {
  Map<String, Map<String, dynamic>> items = {
    "Blue Paper Towel": {"quantity": 0, "image": "assets/images/blue_paper_towel.png", "order": 0},
    "Red Mop": {"quantity": 0, "image": "assets/images/red_mop.PNG", "order": 0},
    "Yellow Mop": {"quantity": 0, "image": "assets/images/yellow_mop.PNG", "order": 0},
    "Blue Mop": {"quantity": 0, "image": "assets/images/blue_mop.PNG", "order": 0},
    "Spray Bottle": {"quantity": 0, "image": "assets/images/spray_can.jpg", "order": 0},
    "White Tissue Paper": {"quantity": 0, "image": "assets/images/white_tissue_pepper.jpg", "order": 0},
  };

  void updateOrder(String item, int change) {
    setState(() {
      items[item]?['order'] = (items[item]?['order'] + change).clamp(0, 99);
    });
  }

  void placeOrder() {
    Map<String, int> orderedItems = {};
    items.forEach((key, value) {
      if (value['order'] > 0) {
        orderedItems[key] = value['order'];
      }
    });

    if (orderedItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Order Placed"),
            content: Text("Your order has been placed successfully!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Supplies"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: items.entries.map((entry) {
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: Image.asset(entry.value['image'], width: 50, height: 50),
                    title: Text(entry.key),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () => updateOrder(entry.key, -1),
                        ),
                        Text(entry.value['order'].toString(), style: TextStyle(fontSize: 18)),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          onPressed: () => updateOrder(entry.key, 1),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: placeOrder,
              child: Text("Place Order", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}