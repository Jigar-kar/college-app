import 'package:cloud_firestore/cloud_firestore.dart';

class CourseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch the list of courses
  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      QuerySnapshot snapshot = await _db.collection('courses').orderBy('name').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id, // Include the document ID
        'name': doc['name'],
      }).toList();
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }

  // Add a new course
  Future<void> addCourse(String courseName) async {
    try {
      // Generate a course ID in the format CXXXX
      String courseId = 'C${(await _getNextCourseId()).toString().padLeft(4, '0')}';
      
      await _db.collection('courses').doc(courseId).set({
        'name': courseName,
      });
    } catch (e) {
      throw Exception('Error adding course: $e');
    }
  }

  // Helper method to get the next available course ID
  Future<int> _getNextCourseId() async {
    try {
      QuerySnapshot snapshot = await _db.collection('courses').get();
      int maxId = 0;

      for (var doc in snapshot.docs) {
        String id = doc.id;
        if (id.startsWith('C')) {
          int currentId = int.tryParse(id.substring(1)) ?? 0;
          maxId = currentId > maxId ? currentId : maxId;
        }
      }

      return maxId + 1; // Increment for the next ID
    } catch (e) {
      throw Exception('Error generating the next course ID: $e');
    }
  }

  // Delete a course by its ID
  Future<void> deleteCourse(String courseId) async {
    try {
      await _db.collection('courses').doc(courseId).delete();
    } catch (e) {
      throw Exception('Error deleting course: $e');
    }
  }

  // Update an existing course by its ID
  Future<void> updateCourse(String courseId, String courseName) async {
    try {
      await _db.collection('courses').doc(courseId).update({
        'name': courseName,
      });
    } catch (e) {
      throw Exception('Error updating course: $e');
    }
  }
}
