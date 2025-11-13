import 'package:bca_c/models/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch students for attendance management by course
  Future<Map<String, List<Student>>> fetchStudents() async {
    try {
      final Map<String, List<Student>> courseStudents = {};
      QuerySnapshot snapshot = await _db.collection('students').get();

      if (snapshot.docs.isEmpty) {
        print('No students found.');
        return courseStudents;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String course = data['course'] ?? 'Unknown';

        Student student = Student.fromFirestore(data, doc.id);

        // Add student to the corresponding course list
        if (courseStudents.containsKey(course)) {
          courseStudents[course]!.add(student);
        } else {
          courseStudents[course] = [student];
        }
      }

      return courseStudents;
    } catch (e) {
      print('Error fetching students: $e');
      throw Exception('Error fetching students.');
    }
  }

  // Submit attendance for students in a course
  Future<void> submitAttendance(Map<String, List<Student>> courseStudents,
      Map<String, bool> attendanceStatus) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        for (var entry in courseStudents.entries) {
          String course = entry.key;
          List<Student> students = entry.value;

          // Batch process attendance for students in a course
          var batch = _db.batch();
          for (var student in students) {
            DocumentReference attendanceRef =
                _db.collection('attendance').doc();
            batch.set(attendanceRef, {
              'studentId': student.id,
              'teacherId': user.uid,
              'status':
                  attendanceStatus[student.id] == true ? 'present' : 'absent',
              'date': FieldValue.serverTimestamp(),
              'course': course,
              'rollNo': student.rollNo,
            });
          }

          // Commit the batch operation for the course
          await batch.commit();
        }
      } catch (e) {
        print('Error submitting attendance: $e');
        throw Exception('Error submitting attendance.');
      }
    }
  }

  // Fetch attendance for a specific student
  Future<List<Map<String, dynamic>>> getAttendance() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Fetch attendance records for the current student
        QuerySnapshot snapshot = await _db
            .collection('attendance')
            .where('studentId', isEqualTo: user.uid)
            .get();

        // Process attendance records and fetch roll number
        List<Map<String, dynamic>> attendanceList =
            await Future.wait(snapshot.docs.map((doc) async {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Fetch roll number from the students collection
          DocumentSnapshot studentSnapshot =
              await _db.collection('students').doc(data['studentId']).get();
          data['rollNo'] =
              studentSnapshot.exists ? studentSnapshot['rollNo'] : 'N/A';

          return data;
        }));

        return attendanceList;
      } catch (e) {
        print('Error fetching attendance: $e');
        throw Exception('Error fetching attendance.');
      }
    }

    return []; // Return empty if user is not authenticated
  }

  // Get attendance records for a specific course
  Future<List<Map<String, dynamic>>> getCourseAttendance(
      String courseId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('attendance')
          .where('courseId', isEqualTo: courseId) // Assuming courseId exists
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching course attendance: $e');
      throw Exception('Error fetching course attendance.');
    }
  }

  // Update student details
  Future<void> updateStudentDetails({
    required String studentId,
    required String name,
    required String email,
    required String rollNo,
    required String enrollmentNo,
    required String className,
    required String course,
  }) async {
    try {
      await _db.collection('students').doc(studentId).set({
        'name': name,
        'email': email,
        'rollNo': rollNo,
        'enrollmentNo': enrollmentNo,
        'class': className,
        'course': course,
      });
    } catch (e) {
      print('Error updating student details: $e');
      throw Exception('Error updating student details.');
    }
  }

  // Fetch subjects
  Future<List<String>> getSubjects() async {
    try {
      QuerySnapshot snapshot = await _db.collection('subjects').get();
      return snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList(); // Assuming subjects are stored with a 'name' field
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }
}
