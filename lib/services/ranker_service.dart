import 'package:cloud_firestore/cloud_firestore.dart';

class RankerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getTopPerformer(String className, String year) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('students')
          .where('class', isEqualTo: className)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        return null;
      }

      final studentData = result.docs.first.data() as Map<String, dynamic>;
      return {
        'rollNo': studentData['rollNo'],
        'percentage': studentData['percentage'],
        'name': studentData['name'],
        'photoUrl': studentData['photoUrl'],
      };
    } catch (e) {
      throw "Failed to fetch top performer: $e";
    }
  }

  Future<void> addRanker({
    required String className,
    required String year,
    required String rollNo,
    required double percentage,
    required String rank,
  }) async {
    try {
      final studentDoc = await _firestore
          .collection('students')
          .where('rollNo', isEqualTo: rollNo)
          .get();

      if (studentDoc.docs.isEmpty) {
        throw "Student with roll number $rollNo not found!";
      }

      final studentData = studentDoc.docs.first.data();
      final String photoUrl = studentData['photoUrl'];
      final String name = studentData['name'];

      await _firestore.collection('rankers').add({
        'class': className,
        'year': year,
        'rollNo': rollNo,
        'percentage': percentage,
        'rank': rank,
        'photoUrl': photoUrl,
        'name': name,
        'addedAt': Timestamp.now(),
      });
    } catch (e) {
      throw "Failed to add ranker: $e";
    }
  }
}
