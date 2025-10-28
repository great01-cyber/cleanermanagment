import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Services/addnewtask.dart';
import '../../Services/dart_selector.dart';
// import '../../Services/task_card.dart'; // We are building the card directly now
import '../../Services/utils.dart';


class supervisorTodolist extends StatefulWidget {
  const supervisorTodolist({super.key});

  @override
  State<supervisorTodolist> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<supervisorTodolist> {
  @override
  Widget build(BuildContext) {
    return Scaffold(
      // --- Fancier AppBar ---
      appBar: AppBar(
        title: const Text(
          'Todo List',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey[50], // Light theme background
        foregroundColor: Colors.black87, // Dark text
        actions: [
          // --- Fancier Add Button ---
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewTask(),
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo, // A strong accent color
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[50], // Match AppBar background
      body: Column( // Removed the Center widget
        children: [
          const DateSelector(),

          // --- StreamBuilder with improved states ---
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("todolist")
                .where('creator',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              // --- Fancier Loading State ---
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded( // Use Expanded to center in remaining space
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // --- Fancier No Data State ---
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_text_search, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                        ),
                        Text(
                          'Add a new task to get started!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // --- Fancier List ---
              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {

                    // Get data from Firebase (keys are unchanged)
                    final taskData = snapshot.data!.docs[index].data();
                    final Color taskColor = hexToColor(taskData['color']);
                    final String title = taskData['title'];
                    final String description = taskData['description'];
                    final String scheduledDate = taskData['date'].toString();
                    final String? imageURL = taskData['imageURL'];

                    // --- The New Fancier Card Layout ---
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // 1. The Color Bar
                          Container(
                            width: 8,
                            height: 125, // Gives the card a consistent height
                            decoration: BoxDecoration(
                              color: taskColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                          ),

                          // 2. The Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // -- Title and Image Row --
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // -- Image --
                                      if (imageURL != null)
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: NetworkImage(imageURL),
                                          backgroundColor: Colors.grey[200],
                                        )
                                      else // Placeholder if no image
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey[200],
                                          child: Icon(Icons.person, size: 24, color: Colors.grey[400]),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // -- Description --
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),

                                  // -- Date and Time Row --
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.calendar, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        scheduledDate, // Using the original string
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(CupertinoIcons.clock, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '10:00AM', // Kept hard-coded time
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}