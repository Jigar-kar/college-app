import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch user data (profile info) for the currently authenticated user
  Future<Map<String, dynamic>> getStudentInfo() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is authenticated');
      }

      DocumentSnapshot snapshot = await _db.collection('students').doc(user.uid).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  // Update profile information
  Future<void> updateProfile({
    required String name,
    required String email,
    required String rollNo,
    required String enrollmentNo,
    required String mobileNo,
    required String studentClass,
    required String course,
    required String birthDate,
    required String parentsContact,

    // Add other fields as needed for profile editing
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is authenticated');
      }

      await _db.collection('students').doc(user.uid).update({
        'name': name,
        'email': email,
        'rollNo': rollNo,
        'enrollmentNo': enrollmentNo,
        'mobileNo': mobileNo,
        'class': studentClass,
        'course': course,
        'birthDate': birthDate,
        'parentsContact': parentsContact,

        // Add other fields as needed for profile editing
      });
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Get user role
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot snapshot = await _db.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return data['role']?.toString() ?? 'Unknown';
      }
    }
    return 'Unknown';
  }

  // Get marks for the current student
  Future<List<Map<String, dynamic>>> getMarks(String studentId) async {
    User? user = _auth.currentUser;

    if (user != null) {
      QuerySnapshot snapshot = await _db
          .collection('marks')
          .where('studentId', isEqualTo: user.uid)
          .get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    }
    return [];
  }

  // Get attendance for the current student
  Future<List<Map<String, dynamic>>> getAttendance() async {
    User? user = _auth.currentUser;

    if (user != null) {
      QuerySnapshot snapshot = await _db
          .collection('attendance')
          .where('studentId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> attendanceList =
          await Future.wait(snapshot.docs.map((doc) async {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Fetch roll number from the students collection
        DocumentSnapshot studentSnapshot =
            await _db.collection('students').doc(data['studentId']).get();
        data['rollNo'] =
            studentSnapshot['rollNo']; // Add roll number to the attendance data
        return data;
      }));

      return attendanceList;
    }
    return [];
  }

  // Get fee details for the current student
  Future<List<Map<String, dynamic>>> getFees() async {
    User? user = _auth.currentUser;

    if (user != null) {
      // First, get the student's roll number from the 'students' collection
      DocumentSnapshot studentSnapshot = await _db
          .collection('students')
          .doc(user.uid) // Assuming the student's document ID is the same as the user UID
          .get();

      if (studentSnapshot.exists) {
        // Safely cast data to Map<String, dynamic>
        Map<String, dynamic>? studentData =
            studentSnapshot.data() as Map<String, dynamic>?;

        if (studentData != null && studentData.containsKey('rollNo')) {
          String rollNo = studentData['rollNo'];
          String class1 = studentData['class'];

          // Now, use the roll number to fetch fees
          QuerySnapshot feeSnapshot = await _db
              .collection('fees')
              .where('studentId', isEqualTo: rollNo)
              .where('class', isEqualTo: class1.toString())
              .get();

          return feeSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        }
      }
    }
    return [];
  }

  // Add fee for a student
  Future<void> addFee(String studentId, double amount, String status,String class1) async {
    await _db.collection('fees').add({
      'studentId': studentId,
      'amount': amount,
      'date': FieldValue
          .serverTimestamp(), // Optional: timestamp for when the fee was added
      'status': status, // Add status of fee payment
      'class' : class1,
    });
  }

  // Add a teacher
  Future<void> addTeacher(String name, String email, String subject, String className) async {
    try {
      await _db.collection('teachers').add({
        'name': name,
        'email': email,
        'subject': subject, // Include the subject field
        'created_at': FieldValue.serverTimestamp(), // Optional: timestamp for when the teacher was added
      });
    } catch (e) {
      print("Error adding teacher: $e");
    }
  }

  // Get all student names
  Future<List<String>> getStudentNames() async {
    try {
      QuerySnapshot snapshot = await _db.collection('students').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['name'] as String;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching student names: $e');
    }
  }

  // Get student names filtered by year
  Future<List<String>> getStudentNamesByYear(String year) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('students')
          .where('year', isEqualTo: year)
          .get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['name'] as String;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching student names by year: $e');
    }
  }

  // Get list of registered teachers
  Future<List<String>> getTeacherNames() async {
    try {
      QuerySnapshot snapshot = await _db.collection('teachers').get();
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print("Error fetching teacher names: $e");
      return [];
    }
  }

  // Get student information by name
  Future<Map<String, dynamic>> getStudentDetails(String studentName) async {
    QuerySnapshot snapshot = await _db
        .collection('students')
        .where('name', isEqualTo: studentName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data() as Map<String, dynamic>;
    }
    return {};
  }

  // Get teacher information by name
  Future<Map<String, dynamic>> getTeacherDetails(String teacherName) async {
    QuerySnapshot snapshot = await _db
        .collection('teachers')
        .where('name', isEqualTo: teacherName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data() as Map<String, dynamic>;
    }
    return {};
  }

  // Get list of subjects
  Future<List<Map<String, dynamic>>> getSubjects(String? uid) async {
    try {
      QuerySnapshot snapshot = await _db.collection('subjects').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching subjects: $e");
      return [];
    }
  }

  // Get marks for specific subject
  Future<List<Map<String, dynamic>>> getMarksForSubject(String subjectCode) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('marks')
          .where('subjectCode', isEqualTo: subjectCode)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching marks for subject: $e");
      return [];
    }
  }

}
