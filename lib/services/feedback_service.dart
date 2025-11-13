import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFeedback({
    required String name,
    required String email,
    required String feedback,
    required double rating,
  }) async {
    try {
      await _firestore.collection('feedback').add({
        'name': name,
        'email': email,
        'feedback': feedback,
        'rating': rating,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to submit feedback: $e';
    }
  }

  Stream<QuerySnapshot> getFeedbacks() {
    return _firestore
        .collection('feedback')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  Future<double> getAverageRating() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('feedback').get();
      if (snapshot.docs.isEmpty) return 0;

      double totalRating = 0;
      for (var doc in snapshot.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'] as double;
      }
      return totalRating / snapshot.docs.length;
    } catch (e) {
      throw 'Failed to get average rating: $e';
    }
  }
}
