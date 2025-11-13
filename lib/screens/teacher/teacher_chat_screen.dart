import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
}

class TeacherChatScreen extends StatefulWidget {
  final String teacherId;
  final String studentId;
  final String chatId;

  const TeacherChatScreen({
    required this.teacherId,
    required this.studentId,
    required this.chatId,
    super.key,
  });

  @override
  _TeacherChatScreenState createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  List<Map<String, dynamic>> _messages = [];
  final DatabaseReference _chatRef =
      FirebaseDatabase.instance.ref().child('chats');
  final String _studentName = '';
  final String _studentPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadStudentInfo();
    _setupMessageListener();
  }

  void _loadStudentInfo() async {
    // Load student info from Firestore
    // Add implementation here
  }

  void _setupMessageListener() {
    _chatRef.child(widget.chatId).onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        final newMessage =
            Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
          _messages.insert(0, newMessage);
          });
        _scrollToBottom();
      }
    });
  }

  void _loadMessages() async {
    final snapshot = await _chatRef.child(widget.chatId).get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map) {
        final messages = <Map<String, dynamic>>[];
        data.forEach((key, value) {
          if (value is Map) {
            messages.add(Map<String, dynamic>.from(value));
          }
        });
        setState(() {
          _messages = messages;
        });
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final messageData = {
        'senderId': widget.teacherId,
        'receiverId': widget.studentId,
        'message': _messageController.text.trim(),
        'timestamp': ServerValue.timestamp,
        'status': 'sent',
      };

      _chatRef.child(widget.chatId).push().set(messageData);
      _messageController.clear();
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
        0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: _studentPhotoUrl.isNotEmpty
                          ? NetworkImage(_studentPhotoUrl)
                          : null,
                      child: _studentPhotoUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                          Text(
                            _studentName.isNotEmpty ? _studentName : 'Student',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Online',
                        style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isSender =
                            message['senderId'] == widget.teacherId;
                        final timestamp = DateTime.fromMillisecondsSinceEpoch(
                            message['timestamp'] ?? 0);
                        final time = DateFormat.jm().format(timestamp);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: isSender
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isSender) ...[
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: _studentPhotoUrl.isNotEmpty
                                      ? NetworkImage(_studentPhotoUrl)
                                      : null,
                                  child: _studentPhotoUrl.isEmpty
                                      ? const Icon(Icons.person, size: 20)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSender
                                        ? AppColors.primaryColor
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isSender
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['message'],
                                        style: TextStyle(
                                          color: isSender
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                  Text(
                                        time,
                    style: TextStyle(
                                          fontSize: 10,
                                          color: isSender
                                              ? Colors.white70
                                              : Colors.black54,
                    ),
                  ),
                ],
              ),
                                ),
                              ),
                              if (isSender) ...[
                                const SizedBox(width: 8),
                const CircleAvatar(
                                  radius: 16,
                                  child: Icon(Icons.person, size: 20),
                ),
                              ],
            ],
          ),
        );
      },
                    ),
                  ),
                ),
              ),

              // Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
            child: Row(
              children: [
                Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isTyping = text.trim().isNotEmpty;
                      });
                    },
                  ),
                ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                      ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
