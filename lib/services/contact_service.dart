import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> submitContactForm(Map<String, dynamic> formData) async {
    try {
      await _firestore.collection('contact_submissions').add({
        ...formData,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('Error submitting contact form: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getContactInfo() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('settings')
          .doc('contact_info')
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error fetching contact info: $e');
      return {};
    }
  }
}
