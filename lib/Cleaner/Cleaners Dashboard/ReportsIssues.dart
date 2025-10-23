import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../Services/report_service.dart';

class ReportsIssues extends StatefulWidget {
  const ReportsIssues({super.key});

  @override
  _ReportsIssuesState createState() => _ReportsIssuesState();
}

class _ReportsIssuesState extends State<ReportsIssues> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _doorNumberController = TextEditingController();
  bool _isFemaleToilet = false;
  bool _isMaleToilet = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String _selectedPriority = 'medium';

  // Pick an image from the gallery or camera
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery); // Or ImageSource.camera
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Submit the report to Firebase
  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || 
        _floorController.text.isEmpty || _doorNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String toiletType = _isFemaleToilet ? "Female Toilet" : _isMaleToilet ? "Male Toilet" : "None";
      
      await ReportService.submitReport(
        title: _titleController.text,
        description: _descriptionController.text,
        floor: _floorController.text,
        doorNumber: _doorNumberController.text,
        toiletType: toiletType,
        priority: _selectedPriority,
        image: _image,
      );

      // Clear the form after successful submission
      _titleController.clear();
      _descriptionController.clear();
      _floorController.clear();
      _doorNumberController.clear();
      setState(() {
        _isFemaleToilet = false;
        _isMaleToilet = false;
        _image = null;
        _selectedPriority = 'medium';
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report Issues"),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Issue Title:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter a brief title for the issue',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Text('Issue Description:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter a detailed description of the issue',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Text('Floor:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                controller: _floorController,
                decoration: InputDecoration(
                  hintText: 'Enter floor number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Text('Door Number:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                controller: _doorNumberController,
                decoration: InputDecoration(
                  hintText: 'Enter door number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Text('Toilet Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _isFemaleToilet,
                    onChanged: (value) {
                      setState(() {
                        _isFemaleToilet = value!;
                        _isMaleToilet = false;
                      });
                    },
                  ),
                  Text('Female Toilet'),
                  SizedBox(width: 20),
                  Checkbox(
                    value: _isMaleToilet,
                    onChanged: (value) {
                      setState(() {
                        _isMaleToilet = value!;
                        _isFemaleToilet = false;
                      });
                    },
                  ),
                  Text('Male Toilet'),
                ],
              ),
              SizedBox(height: 20),
              Text('Priority:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              Text('Upload Image (Optional):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Pick Image'),
                  ),
                  SizedBox(width: 10),
                  if (_image != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _image = null;
                        });
                      },
                      icon: Icon(Icons.delete),
                      label: Text('Remove'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                ],
              ),
              SizedBox(height: 10),
              _image == null
                  ? Text('No image selected.', style: TextStyle(color: Colors.grey))
                  : Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
                    ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Submitting...'),
                          ],
                        )
                      : Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
