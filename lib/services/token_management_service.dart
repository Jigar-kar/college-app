import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TokenManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Bulk process to identify and notify students without FCM tokens
  Future<Map<String, dynamic>> identifyStudentsWithoutTokens(String className) async {
    try {
      // Fetch students in the specified class from students collection
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('class', isEqualTo: className)
          .get();

      // Categorize students
      List<String> studentsWithoutTokens = [];
      List<String> studentsWithTokens = [];
      List<Map<String, dynamic>> studentDetails = [];

      for (var studentDoc in studentsSnapshot.docs) {
        // Fetch corresponding user document from users collection
        final userDoc = await _firestore
            .collection('users')
            .doc(studentDoc.id)
            .get();

        final userData = userDoc.exists ? userDoc.data() : {};
        final token = userData?['fcmToken'];

        if (token == null || token.isEmpty) {
          studentsWithoutTokens.add(studentDoc.id);
        } else {
          studentsWithTokens.add(studentDoc.id);
        }

        // Collect additional student details
        studentDetails.add({
          'id': studentDoc.id,
          'name': studentDoc.data()['name'] ?? 'Unknown',
          'email': userData?['email'] ?? 'No Email',
          'mobileNo': userData?['mobileNo'] ?? 'No Mobile',
          'hasToken': token != null && token.isNotEmpty,
        });
      }

      return {
        'studentsWithoutTokens': studentsWithoutTokens,
        'studentsWithTokens': studentsWithTokens,
        'studentDetails': studentDetails,
        'totalStudents': studentsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error identifying students without tokens: $e');
      return {
        'studentsWithoutTokens': [],
        'studentsWithTokens': [],
        'studentDetails': [],
        'totalStudents': 0,
      };
    }
  }

  // Send bulk reminder notifications
  Future<void> sendBulkTokenReminderNotifications(List<String> studentIds) async {
    try {
      // Fetch student tokens from users collection
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();

      for (var userDoc in usersSnapshot.docs) {
        final token = userDoc.data()['fcmToken'];
        if (token != null && token.isNotEmpty) {
          try {
            await _messaging.sendMessage(
              to: token,
              data: {
                'title': 'Important: Update Your Profile',
                'body': 'Please update your profile to receive important notifications. Go to Profile Settings.',
                'type': 'TOKEN_REMINDER',
              },
            );
          } catch (notificationError) {
            print('Failed to send notification to ${userDoc.id}: $notificationError');
          }
        }
      }
    } catch (e) {
      print('Error in bulk token reminder: $e');
    }
  }

  // Alternative communication method: Email/SMS reminder
  Future<void> sendAlternativeReminders(List<Map<String, dynamic>> studentDetails) async {
    try {
      // Store reminder records in Firestore
      final reminderBatch = _firestore.batch();

      for (var student in studentDetails) {
        if (student['email'] != 'No Email' || student['mobileNo'] != 'No Mobile') {
          final reminderDoc = _firestore.collection('token_reminders').doc();
          reminderBatch.set(reminderDoc, {
            'studentId': student['id'],
            'name': student['name'],
            'email': student['email'],
            'mobileNo': student['mobileNo'],
            'reminderSent': FieldValue.serverTimestamp(),
            'reminderType': ['email', 'sms'],
            'status': 'pending',
          });
        }
      }

      await reminderBatch.commit();
      print('Alternative reminder records created for ${studentDetails.length} students');
    } catch (e) {
      print('Error creating alternative reminder records: $e');
    }
  }

  // Comprehensive token management workflow
  Future<void> manageTokensForClass(String className) async {
    try {
      // Identify students without tokens
      final tokenStatus = await identifyStudentsWithoutTokens(className);

      // Extract student IDs without tokens
      final studentsWithoutTokens = tokenStatus['studentsWithoutTokens'];
      final studentDetails = tokenStatus['studentDetails'];

      if (studentsWithoutTokens.isNotEmpty) {
        // Send bulk FCM notifications to students with tokens
        await sendBulkTokenReminderNotifications(studentsWithoutTokens);

        // Create alternative communication records
        await sendAlternativeReminders(
          studentDetails.where((student) => 
            student['hasToken'] == false && 
            (student['email'] != 'No Email' || student['mobileNo'] != 'No Mobile')
          ).toList()
        );

        // Optional: Log the token management process
        await _firestore.collection('token_management_logs').add({
          'className': className,
          'totalStudents': tokenStatus['totalStudents'],
          'studentsWithoutTokens': studentsWithoutTokens.length,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Comprehensive token management failed: $e');
    }
  }
}
