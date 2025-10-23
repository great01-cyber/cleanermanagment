import 'package:flutter/material.dart';
import '../Services/email_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();
  final _fromEmailController = TextEditingController();
  final _fromNameController = TextEditingController();
  final _adminEmailController = TextEditingController();

  bool _useTLS = true;
  bool _isLoading = false;
  bool _isTesting = false;
  EmailConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _fromEmailController.dispose();
    _fromNameController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await EmailService.getEmailConfig();
      if (config != null) {
        setState(() {
          _currentConfig = config;
          _smtpHostController.text = config.smtpHost;
          _smtpPortController.text = config.smtpPort.toString();
          _smtpUsernameController.text = config.smtpUsername;
          _smtpPasswordController.text = config.smtpPassword;
          _fromEmailController.text = config.fromEmail;
          _fromNameController.text = config.fromName;
          _adminEmailController.text = config.adminEmail;
          _useTLS = config.useTLS;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load configuration: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final config = EmailConfig(
        smtpHost: _smtpHostController.text.trim(),
        smtpPort: int.parse(_smtpPortController.text.trim()),
        smtpUsername: _smtpUsernameController.text.trim(),
        smtpPassword: _smtpPasswordController.text.trim(),
        useTLS: _useTLS,
        fromEmail: _fromEmailController.text.trim(),
        fromName: _fromNameController.text.trim(),
        adminEmail: _adminEmailController.text.trim(),
      );

      await EmailService.saveEmailConfig(config);
      
      setState(() {
        _currentConfig = config;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email configuration saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save configuration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
    });

    try {
      final config = EmailConfig(
        smtpHost: _smtpHostController.text.trim(),
        smtpPort: int.parse(_smtpPortController.text.trim()),
        smtpUsername: _smtpUsernameController.text.trim(),
        smtpPassword: _smtpPasswordController.text.trim(),
        useTLS: _useTLS,
        fromEmail: _fromEmailController.text.trim(),
        fromName: _fromNameController.text.trim(),
        adminEmail: _adminEmailController.text.trim(),
      );

      final success = await EmailService.testEmailConfig(config);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test email sent successfully! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test email. Please check your configuration.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email Configuration Section
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.email, color: Colors.deepPurple),
                                SizedBox(width: 8),
                                Text(
                                  'Email Configuration',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Configure SMTP settings to receive email notifications when issue reports are submitted.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 20),
                            
                            // SMTP Host
                            TextFormField(
                              controller: _smtpHostController,
                              decoration: InputDecoration(
                                labelText: 'SMTP Host',
                                hintText: 'smtp.gmail.com',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.dns),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter SMTP host';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // SMTP Port
                            TextFormField(
                              controller: _smtpPortController,
                              decoration: InputDecoration(
                                labelText: 'SMTP Port',
                                hintText: '587',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter SMTP port';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid port number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // SMTP Username
                            TextFormField(
                              controller: _smtpUsernameController,
                              decoration: InputDecoration(
                                labelText: 'SMTP Username',
                                hintText: 'your-email@gmail.com',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter SMTP username';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // SMTP Password
                            TextFormField(
                              controller: _smtpPasswordController,
                              decoration: InputDecoration(
                                labelText: 'SMTP Password',
                                hintText: 'Your email password or app password',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter SMTP password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // Use TLS Checkbox
                            CheckboxListTile(
                              title: Text('Use TLS (Recommended)'),
                              subtitle: Text('Enable TLS encryption for secure email transmission'),
                              value: _useTLS,
                              onChanged: (value) {
                                setState(() {
                                  _useTLS = value ?? true;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            SizedBox(height: 16),
                            
                            // From Email
                            TextFormField(
                              controller: _fromEmailController,
                              decoration: InputDecoration(
                                labelText: 'From Email',
                                hintText: 'noreply@yourcompany.com',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter from email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // From Name
                            TextFormField(
                              controller: _fromNameController,
                              decoration: InputDecoration(
                                labelText: 'From Name',
                                hintText: 'Cleaner App System',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter from name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            
                            // Admin Email
                            TextFormField(
                              controller: _adminEmailController,
                              decoration: InputDecoration(
                                labelText: 'Admin Email',
                                hintText: 'admin@yourcompany.com',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.admin_panel_settings),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter admin email';
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
                    
                    SizedBox(height: 20),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isTesting ? null : _testConfiguration,
                            icon: _isTesting 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(Icons.send),
                            label: Text(_isTesting ? 'Testing...' : 'Test Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveConfiguration,
                            icon: _isLoading 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(Icons.save),
                            label: Text(_isLoading ? 'Saving...' : 'Save Configuration'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Help Section
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.help, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Setup Help',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'For Gmail users:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('• Host: smtp.gmail.com'),
                            Text('• Port: 587'),
                            Text('• Use TLS: Yes'),
                            Text('• Use App Password (not your regular password)'),
                            SizedBox(height: 8),
                            Text(
                              'For Outlook users:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('• Host: smtp-mail.outlook.com'),
                            Text('• Port: 587'),
                            Text('• Use TLS: Yes'),
                            SizedBox(height: 8),
                            Text(
                              'Note: Make sure to enable "Less secure app access" or use App Passwords for Gmail.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
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
