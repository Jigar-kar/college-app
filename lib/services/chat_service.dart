import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatService {
  final DatabaseReference _chatsRef =
      FirebaseDatabase.instance.ref().child('chats');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or get an existing chat room between teacher and student
  Future<String> createOrGetChatRoom(String studentId, String teacherId) async {
    String chatId = _generateChatId(studentId, teacherId);

    // Check if chat exists in Firestore
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      // Get student and teacher data
      final studentDoc =
          await _firestore.collection('students').doc(studentId).get();
      final teacherDoc =
          await _firestore.collection('teachers').doc(teacherId).get();

      // Create chat room metadata in Firestore
      await _firestore.collection('chats').doc(chatId).set({
        'participants': {
          'student': {
            'id': studentId,
            'name': studentDoc.data()?['name'] ?? 'Student',
            'photoUrl': studentDoc.data()?['photoUrl'] ?? '',
          },
          'teacher': {
            'id': teacherId,
            'name': teacherDoc.data()?['name'] ?? 'Teacher',
            'photoUrl': teacherDoc.data()?['photoUrl'] ?? '',
          }
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Initialize chat in Realtime Database
      await _chatsRef.child(chatId).set({
        'metadata': {
          'chatId': chatId,
          'createdAt': ServerValue.timestamp,
        }
      });
    }

    return chatId;
  }

  /// Send a message
  Future<void> sendMessage(
      String chatId, String senderId, String receiverId, String message) async {
    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': ServerValue.timestamp,
      'status': 'sent',
      'type': 'text', // For future support of different message types
    };

    // Add message to Realtime Database
    await _chatsRef.child(chatId).child('messages').push().set(messageData);

    // Update last message in Firestore
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// Get chat metadata
  Stream<DocumentSnapshot> getChatMetadata(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }

  /// Listen for messages in real-time
  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    return _chatsRef
        .child(chatId)
        .child('messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> messages = [];

      data.forEach((key, value) {
        if (value is Map) {
          final message = Map<String, dynamic>.from(value);
          message['id'] = key;
          messages.add(message);
        }
      });

      messages
          .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      return messages;
    });
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    await _chatsRef
        .child(chatId)
        .child('messages')
        .child(messageId)
        .update({'status': 'read'});
  }

  /// Get unread message count
  Stream<int> getUnreadMessageCount(String chatId, String userId) {
    return _chatsRef
        .child(chatId)
        .child('messages')
        .orderByChild('status')
        .equalTo('sent')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return 0;

      final messages = event.snapshot.value as Map<dynamic, dynamic>;
      return messages.values.where((msg) => msg['receiverId'] == userId).length;
    });
  }

  /// Generate consistent chat ID
  String _generateChatId(String id1, String id2) {
    return id1.compareTo(id2) < 0 ? '$id1-$id2' : '$id2-$id1';
  }
}
