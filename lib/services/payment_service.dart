import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> processPayment({
    required String monthYear,
    required double amount,
    required String paymentMethod,
    required String semester,
    required String transactionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get student details
      final studentDoc = await _firestore.collection('students').doc(user.uid).get();
      if (!studentDoc.exists) throw 'Student not found';
      
      final studentData = studentDoc.data()!;
      final payment = {
        'userId': user.uid,
        'studentId': user.uid,
        'studentName': studentData['name'] ?? 'Unknown',
        'monthYear': monthYear,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'semester': semester,
        'transactionId': transactionId,
        'status': 'paid',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('payments').add(payment);

      return {
        'success': true,
        'data': payment,
        'message': 'Payment processed successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Payment failed: $e',
        'data': null
      };
    }
  }
}