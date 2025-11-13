import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> storePaymentDetails({
    required double amount,
    required String transactionId,
    required String status,
    required String method,
    String? errorMessage,
    required String note,
  }) async {
    try {
      await _db.collection('payments').add({
        'amount': amount,
        'transactionId': transactionId,
        'status': status,
        'method': method,
        'errorMessage': errorMessage,
        'note': note,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print("Payment details stored successfully in Firestore");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error storing payment details in Firestore: $e");
      }
    }
  }
}
