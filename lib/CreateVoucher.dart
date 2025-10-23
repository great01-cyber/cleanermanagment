import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Cleaner/Cleaners.dart';
import 'meal_ticket_provider.dart';

class CreateVouchers extends StatefulWidget {
  @override
  _CreateVouchersState createState() => _CreateVouchersState();
  String? selectedCleaner; // Store selected cleaner

  final List<String> cleanersList = [
    "John Ujah",
    "Kofi Mensah",
    "James Oliver",
    "Joyce Peters",
    "Anna Bello",
    "Grace Thompson"
  ];
}

class _CreateVouchersState extends State<CreateVouchers> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _duration = 30; // Default duration in minutes

  void _createMealTicket() {
    String title = _titleController.text;
    String description = _descriptionController.text;

    if (title.isNotEmpty && description.isNotEmpty) {
      MealTicket mealTicket = MealTicket(
        title: title,
        description: description,
        durationInMinutes: _duration,
      );

      Provider.of<MealTicketProvider>(context, listen: false).addMealTicket(mealTicket);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meal Ticket Created Successfully!')),
      );

      // Navigate to See Tickets Automatically
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SeeTickets()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Supervisor Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Created By'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Where to get it'),
            ),
            SizedBox(height: 20),
            Text('Duration: $_duration minutes'),
            Slider(
              value: _duration.toDouble(),
              min: 1,
              max: 120,
              divisions: 120,
              label: "$_duration minutes",
              onChanged: (double value) {
                setState(() {
                  _duration = value.toInt();
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createMealTicket,
              child: Text('Create Meal Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}