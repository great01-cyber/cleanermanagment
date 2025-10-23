import 'package:flutter/material.dart';

class SocialBoardPage extends StatefulWidget {
  const SocialBoardPage({super.key});

  @override
  State<SocialBoardPage> createState() => _SocialBoardPageState();
}

class _SocialBoardPageState extends State<SocialBoardPage> {
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'author': 'John Doe',
      'content': 'Great work on the cleaning today!',
      'timestamp': '2 hours ago',
      'likes': 5,
    },
    {
      'id': 2,
      'author': 'Jane Smith',
      'content': 'Remember to check the inventory before starting your shift.',
      'timestamp': '4 hours ago',
      'likes': 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Board'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
        children: [
                      CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text(
                          post['author'][0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
          Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['author'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              post['timestamp'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post['content'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up_outlined),
                        onPressed: () {
                          setState(() {
                            post['likes']++;
                          });
                        },
                      ),
                      Text('${post['likes']} likes'),
                    ],
                  ),
                ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPostDialog();
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddPostDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Post'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _posts.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'author': 'You',
                    'content': controller.text,
                    'timestamp': 'Just now',
                    'likes': 0,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}