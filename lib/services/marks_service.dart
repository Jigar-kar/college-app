import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarksService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to get the current authenticated user
  User? get currentUser => _auth.currentUser;

  // Fetch marks for a particular student by studentId
  Future<List<Map<String, dynamic>>> getMarks(String studentId) async {
    try {
      final snapshot = await _db
          .collection('marks')
          .where('studentId', isEqualTo: studentId)
          .get();

      return snapshot.docs.map((doc) {
        var data = doc.data();
        return {
          'subject': data['subject'],
          'marks': data['marks'],
          'date': _formatTimestamp(data['date']),
          'teacherId': data['teacherId'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching marks for studentId $studentId: $e');
      throw Exception('Error fetching marks for studentId $studentId');
    }
  }

  // Helper function to format Firestore timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day} ${_monthName(dateTime.month)} ${dateTime.year} at ${_formatTime(dateTime)}";
  }

  // Helper function to get month name
  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Helper function to format time
  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 == 0 ? 12 : hour % 12;
    String minutes = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minutes $period";
  }

  // Fetch subjects and marks for a student by roll number
 // Fetch marks for a particular student by rollNo
  Future<Map<String, double>> fetchSubjectsAndMarks(String rollNo) async {
    try {
      // Step 1: Fetch student data using rollNo
      QuerySnapshot studentSnapshot = await _db
          .collection('students')
          .where('rollNo', isEqualTo: rollNo)
          .get();

      if (studentSnapshot.docs.isNotEmpty) {
        // Get student data
        String studentId = studentSnapshot.docs.first.id;
        String courseId = studentSnapshot.docs.first['course'];

        // Step 2: Fetch subjects based on the student's course
        QuerySnapshot subjectsSnapshot = await _db
            .collection('subjects')
            .where('course', isEqualTo: courseId)  // Filter subjects by course
            .get();

        Map<String, double> subjectMarks = {};

        // Step 3: Fetch marks for each subject
        for (var subjectDoc in subjectsSnapshot.docs) {
          String? subjectName = subjectDoc['name'];
          if (subjectName == null) {
            print('Warning: "subjectName" field is missing in subject document.');
            continue;  // Skip the subject if the field doesn't exist
          }

          // Query marks for the student and subject
          QuerySnapshot marksSnapshot = await _db
              .collection('marks')
              .where('studentId', isEqualTo: studentId)
              .where('subject', isEqualTo: subjectName)
              .get();

          if (marksSnapshot.docs.isNotEmpty) {
            double marks = marksSnapshot.docs.first['marks'] is num
                ? (marksSnapshot.docs.first['marks'] as num).toDouble()
                : 0.0;
            subjectMarks[subjectName] = marks;
          } else {
            // If no marks are found for the subject, add 0
            subjectMarks[subjectName] = 0.0;
          }
        }

        // Return the map with subject marks
        return subjectMarks;
      } else {
        // If no student is found with that rollNo, log the issue
        print("No student found with rollNo: $rollNo");
        return {};  // Return an empty map if no student is found
      }
    } catch (e) {
      print('Error fetching subjects and marks: $e');
      return {};  // Return an empty map on error
    }
  }
  
  // Fetch list of students
  Future<List<Map<String, dynamic>>> fetchStudents() async {
    try {
      QuerySnapshot snapshot = await _db.collection('students').get();
      
      return snapshot.docs
          .map((doc) => {
                'rollNo': doc['rollNo'],
                'name': doc['name'],
                // You can add more fields as necessary
              })
          .toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];  // Return an empty list in case of error
    }
  }

  // Submit marks for a student
  Future<void> submitMarks(String studentId, Map<String, double> subjectMarks) async {
    User? teacher = currentUser;

    if (teacher == null) {
      throw Exception('No teacher is logged in');
    }

    try {
      double totalMarks = subjectMarks.values.reduce((a, b) => a + b);

      await _db.collection('marks').add({
        'studentId': studentId,
        'marks': subjectMarks,
        'totalMarks': totalMarks,
        'teacherId': teacher.uid,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error submitting marks for studentId $studentId: $e');
      throw Exception('Failed to submit marks for studentId $studentId');
    }
  }

  // Add marks for a specific subject
  Future<void> addMarks({
    required String studentId,
    required String subject,
    required double marks,
    required String teacherId,
  }) async {
    if (marks < 0 || marks > 100) {
      throw Exception('Marks should be between 0 and 100');
    }

    try {
      await _db.collection('marks').add({
        'studentId': studentId,
        'subject': subject,
        'marks': marks,
        'teacherId': teacherId,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding marks for studentId $studentId, subject $subject: $e');
      throw Exception('Failed to add marks');
    }
  }

  // Calculate total marks from the list of marks
  double calculateTotal(List<Map<String, dynamic>> marksList) {
    return marksList.fold(
      0.0,
      (total, mark) => total + (mark['marks'] as num).toDouble(),
    );
  }

  // Calculate percentage based on total marks and number of subjects
  double calculatePercentage(double total, int totalSubjects) {
    if (totalSubjects <= 0) {
      throw Exception('Total subjects cannot be zero or negative');
    }
    return (total / (totalSubjects * 100)) * 100;
  }
}
