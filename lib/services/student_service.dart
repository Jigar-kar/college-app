import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> fetchStudentName() async {
    User? user = _auth.currentUser; // Get the current logged-in user

    if (user == null) return null; // If no user is logged in

    DocumentSnapshot snapshot = await _firestore
        .collection('students') // Your Firestore collection
        .doc(user.uid) // Document ID (student ID)
        .get();

    if (snapshot.exists) {
      return snapshot['name']; // Assuming 'name' is the field in your document
    }
    return null;
  }
}
