// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaveService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch leave requests for the currently logged-in student
Future<List<Map<String, dynamic>>> fetchLeaveRequests() async {
  try {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");

    final leavesSnapshot = await _db
        .collection('leaves')
        .where('studentId', isEqualTo: userId)
        .orderBy('fromDate', descending: false)
        .get();

    final List<Map<String, dynamic>> parsedLeaves = [];

    for (var doc in leavesSnapshot.docs) {
      try {
        // Pass studentId directly to the parsing function
        final leaveRequest = _parseLeaveRequest(doc, userId);
        parsedLeaves.add(leaveRequest);
      } catch (e) {
        print("Error parsing document ${doc.id}: $e");
      }
    }

    return parsedLeaves;
  } catch (e) {
    print('Error fetching leave requests: $e');
    throw Exception("Failed to fetch leave requests");
  }
}

  /// Fetch leave history for teachers (all leave requests with 'Approved' or 'Rejected' status)
  Future<List<Map<String, dynamic>>> fetchLeaveHistory(BuildContext context) async {
    try {
      final leavesSnapshot = await _db
          .collection('leaves')
          .where('status', whereIn: ['Approved', 'Rejected']) // Fetch only approved/rejected leaves
          .get();

      print('Fetched ${leavesSnapshot.docs.length} leave requests'); // Log document count

      final List<Map<String, dynamic>> parsedHistory = [];

      for (var doc in leavesSnapshot.docs) {
        try {
          // Fetch the student's name using studentId
          final studentName = await _getStudentName(doc['studentId']);
          final leaveHistory = _parseLeaveRequest(doc, studentName);
          parsedHistory.add(leaveHistory);
        } catch (e) {
          print("Error parsing document ${doc.id}: $e");
        }
      }

      return parsedHistory;
    } catch (e) {
      print('Error fetching leave history: $e');  // More detailed error logging
      throw Exception("Failed to fetch leave history");
    }
  }

  /// Fetch student name from the 'users' collection based on studentId.
  Future<String> _getStudentName(String studentId) async {
    try {
      final userDoc = await _db.collection('students').doc(studentId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['name'] ?? 'Unknown'; // Return student name if available
      }
      return 'Unknown'; // Default to 'Unknown' if user doesn't exist
    } catch (e) {
      print('Error fetching student name: $e');
      return 'Unknown'; // Default if there's an error
    }
  }

  /// Apply for a leave with specified details.
  Future<void> applyForLeave(DateTime fromDate, DateTime toDate, String reason) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      await _db.collection('leaves').add({
        'studentId': userId,
        'fromDate': Timestamp.fromDate(fromDate),
        'toDate': Timestamp.fromDate(toDate),
        'reason': reason,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error applying for leave: $e');
      throw Exception("Error applying for leave");
    }
  }

  /// Update the status of a leave request.
  Future<void> updateLeaveStatus(String leaveId, String status) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      await _db.collection('leaves').doc(leaveId).update({
        'status': status,
        'teacherId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating leave status: $e');
      throw Exception("Error updating leave status");
    }
  }

  /// Parse leave request data into a structured format, including student name.
  Map<String, dynamic> _parseLeaveRequest(DocumentSnapshot doc, String studentName) {
    final data = doc.data() as Map<String, dynamic>;

    final String studentId = data['studentId'] ?? 'Unknown'; // Default to 'Unknown' if null
    final String reason = data['reason'] ?? 'No reason provided'; // Default reason
    final String status = data['status'] ?? 'Pending'; // Default status

    final DateTime fromDate = _parseDate(data['fromDate']);
    final DateTime toDate = _parseDate(data['toDate']);
    final DateTime createdAt = _parseDate(data['createdAt']);

    return {
      'id': doc.id,
      'studentId': studentId,
      'studentName': studentName, // Add student name to the data
      'fromDate': fromDate,
      'toDate': toDate,
      'reason': reason,
      'status': status,
      'createdAt': createdAt,
    };
  }

  /// Safely parse Firestore Timestamp to DateTime.
  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is DateTime) {
      return date;
    } else {
      return DateTime.now(); // Fallback to current date/time
    }
  }
}
