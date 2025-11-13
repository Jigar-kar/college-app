import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String content;
  final String postedBy;
  final DateTime postedDate;
  final String priority;
  final bool isActive;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.postedBy,
    required this.postedDate,
    required this.priority,
    this.isActive = true,
  });

  factory Notice.fromMap(Map<String, dynamic> map, String id) {
    return Notice(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      postedBy: map['postedBy'] ?? '',
      postedDate: (map['postedDate'] as Timestamp).toDate(),
      priority: map['priority'] ?? 'medium',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'postedBy': postedBy,
      'postedDate': Timestamp.fromDate(postedDate),
      'priority': priority,
      'isActive': isActive,
    };
  }
}
