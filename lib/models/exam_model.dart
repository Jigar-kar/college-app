import 'package:cloud_firestore/cloud_firestore.dart';

class ExamModel {
  final String id;
  final String examName;
  final String subject;
  final String className;
  final DateTime examDate;
  final String duration;
  final num totalMarks;
  final String createdBy;
  final String status;
  final DateTime createdAt;
  final List<Map<String, dynamic>> questions;

  ExamModel({
    required this.id,
    required this.examName,
    required this.subject,
    required this.className,
    required this.examDate,
    required this.duration,
    required this.totalMarks,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.questions,
  });

  factory ExamModel.fromMap(String id, Map<String, dynamic> map) {
    return ExamModel(
      id: id,
      examName: map['examName'] ?? '',
      subject: map['subject'] ?? '',
      className: map['className'] ?? '',
      examDate: (map['examDate'] as Timestamp).toDate(),
      duration: map['duration'] ?? '',
      totalMarks: num.parse((map['totalMarks'] ?? 0).toString()),
      createdBy: map['createdBy'] ?? '',
      status: map['status'] ?? 'Scheduled',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      questions: List<Map<String, dynamic>>.from(map['questions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examName': examName,
      'subject': subject,
      'className': className,
      'examDate': Timestamp.fromDate(examDate),
      'duration': duration,
      'totalMarks': totalMarks,
      'createdBy': createdBy,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'questions': questions,
    };
  }
}
