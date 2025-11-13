// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch available courses from Firebase Firestore
  Future<List<String>> fetchCourses() async {
    try {
      var courseSnapshot = await _firestore.collection('courses').get();
      List<String> courseList = [];
      for (var doc in courseSnapshot.docs) {
        courseList.add(doc['name']);
      }
      print('Courses fetched: $courseList');
      return courseList;
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  // Fetch available classes for a course
  Future<List<String>> fetchClassesForCourse(String courseName) async {
    try {
      var classSnapshot = await _firestore
          .collection('classes')
          .where('course', isEqualTo: courseName)
          .get();

      List<String> classList = [];
      for (var doc in classSnapshot.docs) {
        classList.add(doc['name']);
      }
      print('Classes for $courseName: $classList');
      return classList;
    } catch (e) {
      print('Error fetching classes for $courseName: $e');
      return [];
    }
  }

  // Fetch available subjects for a specific course and class
  Future<List<String>> fetchSubjectsForCourseAndClass(String courseName, String className) async {
    try {
      var subjectSnapshot = await _firestore
          .collection('subjects')
          .where('course', isEqualTo: courseName)
          .where('class', isEqualTo: className)
          .get();

      List<String> subjectList = [];
      for (var doc in subjectSnapshot.docs) {
        if (doc.exists && doc.data().containsKey('name')) {
          subjectList.add(doc['name']);
        } else {
          print('Subject document missing "name" field: ${doc.id}');
        }
      }
      print('Subjects for $courseName, $className: $subjectList');
      return subjectList;
    } catch (e) {
      print('Error fetching subjects for $courseName, $className: $e');
      return [];
    }
  }

  // Add a new subject to the selected course and class in Firebase Firestore
  Future<void> addSubject(
    String? selectedCourse,
    String? selectedClass,
    String subjectName,
    String subjectCode,
    String subjectDescription,
  ) async {
    if (selectedCourse == null || selectedCourse.isEmpty) {
      print('Please select a valid course');
      return;
    }
    if (selectedClass == null || selectedClass.isEmpty) {
      print('Please select a valid class');
      return;
    }

    try {
      // Add the new subject to the subjects collection
      DocumentReference subjectRef = await _firestore.collection('subjects').add({
        'course': selectedCourse,
        'class': selectedClass,
        'name': subjectName,
        'code': subjectCode,
        'description': subjectDescription,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('Subject added successfully');

      // Fetch the students enrolled in the selected course and class
      var studentSnapshot = await _firestore
          .collection('students')
          .where('course', isEqualTo: selectedCourse)
          .where('class', isEqualTo: selectedClass)
          .get();

      // Update the students with the new subject
      for (var studentDoc in studentSnapshot.docs) {
        await studentDoc.reference.update({
          'subjects': FieldValue.arrayUnion([subjectName])
        });
      }

      print('Students updated with new subject');
    } catch (e) {
      print('Error adding subject or updating students: $e');
    }
  }
}
