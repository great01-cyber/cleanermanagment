import 'package:flutter/material.dart';
import '../Services/user_management_service.dart';
import '../Services/firebase_config.dart';

// Screen for creating new cleaner accounts
class AddCleanerScreen extends StatefulWidget {
  const AddCleanerScreen({super.key});

  @override
  State<AddCleanerScreen> createState() => _AddCleanerScreenState();
}

class _AddCleanerScreenState extends State<AddCleanerScreen> {
  final _formKey = GlobalKey<FormState>();           // Form validation key
  final _nameController = TextEditingController();   // Name input controller
  final _emailController = TextEditingController(); // Email input controller
  final _passwordController = TextEditingController(); // Password input controller
  final _confirmPasswordController = TextEditingController(); // Confirm password controller
  
  SupervisorModel? _selectedSupervisor; // Selected supervisor for assignment
  List<SupervisorModel> _supervisors = []; // Available supervisors list
  bool _isLoading = false;               // Loading state for form submission
  bool _obscurePassword = true;          // Password visibility toggle
  bool _obscureConfirmPassword = true;   // Confirm password visibility toggle

  @override
  void initState() {
    super.initState();
    _loadSupervisors(); // Load available supervisors
  }

  @override
  void dispose() {
    // Clean up text controllers
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Load all available supervisors for assignment
  Future<void> _loadSupervisors() async {
    try {
      final supervisors = await UserManagementService.getAllSupervisors();
      setState(() {
        _supervisors = supervisors;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load supervisors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create new cleaner account
  Future<void> _createCleaner() async {
    if (!_formKey.currentState!.validate()) return; // Validate form first
    if (_selectedSupervisor == null) {
      // Check if supervisor is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supervisor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading state
    });

    try {
      // Call service to create cleaner
      await UserManagementService.createCleaner(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        supervisorId: _selectedSupervisor!.uid,
        supervisorName: _selectedSupervisor!.name,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleaner created successfully and assigned to ${_selectedSupervisor!.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create cleaner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading state
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Cleaner'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cleaner Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the cleaner\'s name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Supervisor Assignment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_supervisors.isEmpty)
                        const Center(
                          child: Text(
                            'No supervisors available. Please create a supervisor first.',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      else
                        DropdownButtonFormField<SupervisorModel>(
                          value: _selectedSupervisor,
                          decoration: InputDecoration(
                            labelText: 'Assign to Supervisor',
                            prefixIcon: const Icon(Icons.supervisor_account),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        items: _supervisors.map((supervisor) {
                          return DropdownMenuItem(
                            value: supervisor,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _getZoneColor(supervisor.assignedZone),
                                  child: Text(
                                    supervisor.name.isNotEmpty ? supervisor.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        supervisor.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        supervisor.assignedZone.description,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSupervisor = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a supervisor';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Security',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm the password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _supervisors.isEmpty ? null : _createCleaner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Cleaner',
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

  Color _getZoneColor(Zone zone) {
    switch (zone) {
      case Zone.zoneA:
        return Colors.red;
      case Zone.zoneB:
        return Colors.blue;
      case Zone.zoneC:
        return Colors.green;
      case Zone.zoneD:
        return Colors.orange;
      case Zone.zoneE:
        return Colors.purple;
    }
  }
}
