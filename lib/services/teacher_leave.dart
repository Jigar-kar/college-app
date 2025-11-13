import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch leave requests for the current teacher
  Future<List<Map<String, dynamic>>> fetchLeaveRequests() async {
    try {
      // Get current user's UID (Teacher's UID)
      String currentUserUid = _auth.currentUser?.uid ?? '';

      // Query Firestore to fetch leave requests for the current teacher
      QuerySnapshot snapshot = await _firestore
          .collection('teacher_leaves') // Teacher leave collection
          .where('teacherId', isEqualTo: currentUserUid) // Filter by teacherId (UID)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id, // Include the document ID for future reference
          'fromDate': doc['fromDate'],
          'toDate': doc['toDate'],
          'reason': doc['reason'],
          'status': doc['status'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Error fetching leave requests: $e');
    }
  }

  // Apply for leave and save it to Firestore
  Future<void> applyForLeave({
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    try {
      await _firestore.collection('teacher_leaves').add({
        'teacherId': _auth.currentUser?.uid,
        'fromDate': fromDate,
        'toDate': toDate,
        'reason': reason,
        'status': 'Pending', // Initial status is Pending
      });
    } catch (e) {
      throw Exception('Error applying for leave: $e');
    }
  }

  // Admin can approve leave
  Future<void> approveLeave(String leaveId) async {
    try {
      await _firestore.collection('teacher_leaves').doc(leaveId).update({
        'status': 'Approved',
      });
    } catch (e) {
      throw Exception('Error approving leave: $e');
    }
  }

  // Admin can reject leave and update the reason
  Future<void> rejectLeave(String leaveId, String newReason) async {
    try {
      await _firestore.collection('teacher_leaves').doc(leaveId).update({
        'status': 'Rejected',
        'reason': newReason, // Update the reason if rejected
      });
    } catch (e) {
      throw Exception('Error rejecting leave: $e');
    }
  }

  // Admin can update the leave days
  Future<void> updateLeaveDays(String leaveId, String newFromDate, String newToDate) async {
    try {
      await _firestore.collection('teacher_leaves').doc(leaveId).update({
        'fromDate': newFromDate,
        'toDate': newToDate,
      });
    } catch (e) {
      throw Exception('Error updating leave days: $e');
    }
  }

  // Admin can fetch all leave requests (for Admin Panel)
  Future<List<Map<String, dynamic>>> fetchAllLeaveRequests() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('teacher_leaves')
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'teacherId': doc['teacherId'],
          'fromDate': doc['fromDate'],
          'toDate': doc['toDate'],
          'reason': doc['reason'],
          'status': doc['status'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Error fetching all leave requests: $e');
    }
  }
}
