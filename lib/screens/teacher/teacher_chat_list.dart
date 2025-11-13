// ignore_for_file: use_build_context_synchronously

import 'package:bca_c/screens/teacher/teacher_chat_screen.dart';
import 'package:bca_c/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherChatListScreen extends StatelessWidget {
  final String teacherId;

  const TeacherChatListScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .snapshots(), // Fetching all students
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var students = snapshot.data!.docs;
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              var student = students[index];
              return ListTile(
                title: Text(student['name']), // Display student's name
                onTap: () async {
                  // When a student is tapped, we create a chat room or fetch existing one
                  try {
                    String studentId = student.id;
                    String chatId = await ChatService()
                        .createOrGetChatRoom(studentId, teacherId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherChatScreen(
                          chatId: chatId,
                          teacherId: teacherId,
                          studentId: studentId,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating chat room: $e')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
