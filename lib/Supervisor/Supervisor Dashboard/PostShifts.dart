import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../Services/ShiftProvider.dart';
import '../../Services/supervisor_service.dart';
import '../../Services/task_assignment_service.dart';
import '../../Services/shift_assignment_service.dart';
import '../../Services/Notification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class PostShifts extends StatefulWidget {
  @override
  _PostShiftsPageState createState() => _PostShiftsPageState();
}

class _PostShiftsPageState extends State<PostShifts> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? selectedCleaner;
  List<String> cleaners = []; // Will be loaded from Firebase
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadCleaners(); // Load cleaners from Firebase
  }

  // Load assigned cleaners from Firebase
  Future<void> _loadCleaners() async {
    try {
      final cleanerNames = await SupervisorService.getCleanerNames();
      setState(() {
        cleaners = cleanerNames;
      });
    } catch (e) {
      print('Error loading cleaners: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load cleaners: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Function to show a local notification
  Future<void> _showNotification(String cleaner) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'shift_channel_id',
      'Shift Notifications',
      channelDescription: 'Notifies cleaners about assigned shifts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'New Shift Assigned',
      'A shift has been assigned to $cleaner',
      platformChannelSpecifics,
    );
  }

  // Post shift using Firebase integration
  Future<void> _postShift() async {
    // Validate all fields and show specific error messages
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date!")),
      );
      return;
    }
    
    if (_timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a time!")),
      );
      return;
    }
    
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a location!")),
      );
      return;
    }
    
    if (selectedCleaner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a cleaner!")),
      );
      return;
    }
    
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a shift description!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create shift title from date and time
      final shiftTitle = 'Shift on ${_dateController.text} at ${_timeController.text}';
      
      // Parse date and time for due date
      final dateParts = _dateController.text.split('-');
      final timeText = _timeController.text;
      
      // Parse time from format like "9:49 AM" or "21:30"
      int hour, minute;
      if (timeText.contains('AM') || timeText.contains('PM')) {
        // 12-hour format
        final timeParts = timeText.replaceAll(RegExp(r'[APM]'), '').trim().split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
        
        if (timeText.contains('PM') && hour != 12) {
          hour += 12;
        } else if (timeText.contains('AM') && hour == 12) {
          hour = 0;
        }
      } else {
        // 24-hour format
        final timeParts = timeText.split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }
      
      final dueDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        hour,
        minute,
      );

      // Assign shift using the new shift service
      await ShiftAssignmentService.assignShift(
        cleanerName: selectedCleaner!,
        title: shiftTitle,
        description: _descriptionController.text,
        location: _locationController.text,
        dueDate: dueDate,
        notes: 'Shift assignment',
      );

      // Add shift to provider for local state
      Provider.of<ShiftProvider>(context, listen: false).addShift(
        Shift(
          date: _dateController.text,
          time: _timeController.text,
          location: _locationController.text,
          cleaner: selectedCleaner!,
          description: _descriptionController.text,
        ),
      );

      // Show local notification
      _showNotification(selectedCleaner!);


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Shift assigned successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Clear inputs
      _dateController.clear();
      _timeController.clear();
      _locationController.clear();
      _descriptionController.clear();
      setState(() {
        selectedCleaner = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to assign shift: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Post Shifts")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Select Date",
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _timeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Select Time",
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                onTap: _selectTime,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  hintText: "Enter the location where the shift will take place",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCleaner,
                items: cleaners.map((String cleaner) {
                  return DropdownMenuItem(
                    value: cleaner,
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(cleaner),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => selectedCleaner = newValue),
                decoration: const InputDecoration(
                  labelText: "Assign to Cleaner",
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Shift Description",
                  hintText: "Describe what needs to be done during this shift",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postShift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Post Shift",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}