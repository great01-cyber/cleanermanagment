import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SafetyRules extends StatefulWidget {
  const SafetyRules({super.key});

  @override
  State<SafetyRules> createState() => _ToDoListState();
}

class _ToDoListState extends State<SafetyRules> {
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Safety Session',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Housekeeping Practices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'For the safety and wellbeing of you, your colleagues, and building users, please follow these guidelines at all times.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // PPE and General Safety
            buildSectionTitle('1. PPE and General Safety'),
            buildBulletPoint('Always wear the correct PPE (Gloves, Masks, Safety Footwear).'),
            buildBulletPoint('Tie up long hair and remove lanyards when using machinery.'),
            buildBulletPoint('Use equipment only for its intended purpose.'),

            const SizedBox(height: 20),

            // Electrical Safety
            buildSectionTitle('2. Electrical Safety'),
            buildBulletPoint('Check if equipment is PAT tested before use.'),
            buildBulletPoint('Perform a visual safety check before plugging in.'),
            buildBulletPoint('Use hazard signs near trailing cables.'),
            buildBulletPoint('Unplug equipment when not in use.'),
            buildBulletPoint('Store electrical items in a locked cupboard away from liquids.'),

            const SizedBox(height: 20),

            // Fire Safety
            buildSectionTitle('3. Fire Safety'),
            buildBulletPoint('Keep your Online Fire Training up to date.'),
            buildBulletPoint('Do not create steam or dust near smoke detectors.'),
            buildBulletPoint('Only use electrical equipment provided by the University.'),
            buildBulletPoint('Report fire safety issues to the EFM Helpdesk: 0114 222 9000.'),

            const SizedBox(height: 20),

            // General Housekeeping
            buildSectionTitle('4. General Housekeeping'),
            buildBulletPoint('Dispose of dirty water in the sluice sink — not outside drains.'),
            buildBulletPoint('Report any slip, trip, or fall hazards.'),
            buildBulletPoint('Challenge unsafe behaviour or report it to your line manager.'),

            const SizedBox(height: 30),

            CheckboxListTile(
              title: const Text(
                'I Agree to follow the safety guidelines.',
                style: TextStyle(fontSize: 16),
              ),
              value: isAgreed,
              onChanged: (bool? value) {
                setState(() {
                  isAgreed = value ?? false;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isAgreed
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have agreed to the safety guidelines'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAgreed ? Colors.blue : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Center(
                child: Text(
                  'I Agree',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

