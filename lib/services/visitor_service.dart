import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recordVisit({
    required String phoneNumber,
    required String purpose,
  }) async {
    await _firestore.collection('visitors').add({
      'phoneNumber': phoneNumber,
      'purpose': purpose,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getVisitorHistory(String phoneNumber) {
    return _firestore
        .collection('visitors')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
