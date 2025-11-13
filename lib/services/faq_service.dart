import 'package:cloud_firestore/cloud_firestore.dart';

class FaqService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getFaqs() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('faqs')
          .orderBy('order')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'question': data['question'] ?? '',
          'answer': data['answer'] ?? '',
          'category': data['category'] ?? 'General',
          'order': data['order'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error fetching FAQs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFaqsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('faqs')
          .where('category', isEqualTo: category)
          .orderBy('order')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'question': data['question'] ?? '',
          'answer': data['answer'] ?? '',
          'category': data['category'] ?? 'General',
          'order': data['order'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error fetching FAQs by category: $e');
      return [];
    }
  }
}
