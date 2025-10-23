import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Services/Notification.dart';

class PostMessage extends StatefulWidget {
  @override
  _PostMessageState createState() => _PostMessageState();
}

class _PostMessageState extends State<PostMessage> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Post Message"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Enter your message'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String message = _controller.text;
                if (message.isNotEmpty) {
                  // Add the notification to the provider
                  Provider.of<NotificationProvider>(context, listen: false)
                      .addNotification(message);
                  Navigator.pop(context); // Close the post message screen
                }
              },
              child: Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }
}