import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../Services/ShiftProvider.dart';
import '../../Services/supervisor_service.dart';
import '../../Services/task_assignment_service.dart';
import 'PostShifts.dart';

class AssignTasks extends StatefulWidget {
  const AssignTasks({super.key});

  @override
  State<AssignTasks> createState() => _AssignTasksState();
}

class _AssignTasksState extends State<AssignTasks> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? selectedCleaner;
  List<String> cleaners = []; // Will be loaded from Firebase
  DateTime? selectedDueDate;
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

  // Assign task to cleaner using Firebase
  Future<void> _assignTask() async {
    if (_titleController.text.isEmpty ||
        _locationController.text.isEmpty ||
        selectedCleaner == null ||
        _descriptionController.text.isEmpty ||
        selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Assign task using Firebase
      await TaskAssignmentService.assignTask(
        cleanerName: selectedCleaner!,
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        dueDate: selectedDueDate!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Show local notification
      _showNotification(selectedCleaner!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task assigned successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Clear inputs
      _titleController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _notesController.clear();
      setState(() {
        selectedCleaner = null;
        selectedDueDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to assign task: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Select due date for task
  Future<void> _selectDueDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Tasks"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Task title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Task Title",
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Location field
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Cleaner selection dropdown
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
              
              // Due date selection
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        selectedDueDate != null
                            ? 'Due Date: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'
                            : 'Select Due Date',
                        style: TextStyle(
                          color: selectedDueDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Task description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Task Description",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Additional notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: "Additional Notes (Optional)",
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Assign task button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _assignTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Assign Task",
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