import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TeacherService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register a teacher with email and password
  Future<User?> registerTeacher(
    String email,
    String password,
    String name,
    String subject,
    String className,  
    String phoneNumber,
    String? photoUrl,
  ) async {
    try {
      // Create a new user in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Add user details to the 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': 'teacher',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Add teacher details to the 'teachers' collection
        await _firestore.collection('teachers').doc(user.uid).set({
          'name': name,
          'email': email,
          'subject': subject,
          'class': className,
          'phone': phoneNumber,
          'photoUrl': photoUrl,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          print('Teacher registered and added to both collections!');
        }

        return user;
      } else {
        throw Exception('User creation failed.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during teacher registration: $e');
      }
      return null;
    }
  }

  /// Fetch all subjects from the 'subjects' collection
  Future<List<String>> fetchSubjects() async {
    try {
      QuerySnapshot subjectSnapshot = await _firestore.collection('subjects').get();

      if (subjectSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No subjects found');
        }
        return [];
      }

      List<String> subjects = subjectSnapshot.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            if (data.containsKey('name')) {
              return data['name'].toString();
            } else {
              if (kDebugMode) {
                print('Missing subjectName field in document: ${doc.id}');
              }
              return '';
            }
          })
          .where((subject) => subject.isNotEmpty)
          .toList();

      return subjects;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching subjects: $e');
      }
      return [];
    }
  }

  /// Fetch all teacher classes from the 'teachers' collection
  Future<List<String>> fetchTeacherClasses() async {
    try {
      QuerySnapshot teacherSnapshot = await _firestore.collection('teachers').get();

      if (teacherSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No teachers found');
        }
        return [];
      }

      List<String> teacherClasses = teacherSnapshot.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            if (data.containsKey('class')) {
              return data['class'].toString();
            } else {
              if (kDebugMode) {
                print('Missing class field in document: ${doc.id}');
              }
              return '';
            }
          })
          .where((className) => className.isNotEmpty)
          .toList();

      return teacherClasses;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching teacher classes: $e');
      }
      return [];
    }
  }

  /// Fetch teacher details by ID from the 'teachers' collection
  Future<Map<String, dynamic>?> getTeacherById(String teacherId) async {
    try {
      DocumentSnapshot teacherDoc = await _firestore.collection('teachers').doc(teacherId).get();

      if (teacherDoc.exists) {
        return teacherDoc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error fetching teacher data: $e');
    }
  }

  Future<void> addTeacher(
    String name,
    String email,
    String subject,
    String className,
    String phoneNumber,
    String? photoUrl,
  ) async {
    try {
      await _firestore.collection('teachers').add({
        'name': name,
        'email': email,
        'subject': subject,
        'class': className,
        'phone': phoneNumber,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('Teacher added successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding teacher: $e');
      }
    }
  }
}
