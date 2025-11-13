// ignore_for_file: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch faculty data
  Stream<QuerySnapshot> getFacultyData() {
    return _firestore.collection('teachers').snapshots();
  }
}
