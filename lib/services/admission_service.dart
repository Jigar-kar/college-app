import 'dart:convert';
import 'dart:io';

import 'package:bca_c/models/admission_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AdmissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String repoOwner = "satuababa-bca-1";
  static const String repoName = "Statuababa-Bca";
  static const String accessToken = "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";

  // Submit admission form
  Future<String> submitAdmission(
      AdmissionForm form, List<String> documentPaths) async {
    try {
      // Upload documents to GitHub
      List<String> documentUrls = [];
      for (String path in documentPaths) {
        final fileName = path.split('/').last;
        final githubPath = 'admissions/${form.email}/$fileName';
        final url = await _uploadFileToGitHub(File(path), githubPath);
        documentUrls.add(url);
      }

      // Create admission document in Firestore
      final docRef = await _firestore.collection('admissions').add({
        ...form.toJson(),
        'documentUrls': documentUrls,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit admission form: $e');
    }
  }

  Future<String> _uploadFileToGitHub(File file, String path) async {
    try {
      final fileBytes = await file.readAsBytes();
      final base64Content = base64Encode(fileBytes);

      final url =
          'https://api.github.com/repos/$repoOwner/$repoName/contents/$path';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Accept": "application/vnd.github.v3+json",
        },
        body: jsonEncode({
          "message": "Upload document for admission",
          "content": base64Content,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to upload file: ${response.statusCode}\n${response.body}');
      }

      final responseData = jsonDecode(response.body);
      return responseData['content']['download_url'];
    } catch (e) {
      throw Exception('Failed to upload file to GitHub: $e');
    }
  }

  // Get admission status
  Future<Map<String, dynamic>> getAdmissionStatus(String admissionId) async {
    try {
      final doc =
          await _firestore.collection('admissions').doc(admissionId).get();
      if (!doc.exists) {
        throw Exception('Admission not found');
      }
      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to get admission status: $e');
    }
  }

  // Update admission status (for admin)
  Future<void> updateAdmissionStatus(
      String admissionId, String status, String remarks) async {
    try {
      await _firestore.collection('admissions').doc(admissionId).update({
        'status': status,
        'remarks': remarks,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update admission status: $e');
    }
  }

  // Get all admissions (for admin)
  Future<List<Map<String, dynamic>>> getAllAdmissions() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('admissions').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      throw 'Failed to get admissions: $e';
    }
  }

  // Get admissions by status (for admin)
  Future<List<Map<String, dynamic>>> getAdmissionsByStatus(
      String status) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('admissions')
          .where('status', isEqualTo: status)
          .get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get admissions: $e');
    }
  }

  // Get user's admissions
  Future<List<Map<String, dynamic>>> getUserAdmissions(String email) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('admissions')
          .where('email', isEqualTo: email)
          .get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get user admissions: $e');
    }
  }

  // Create student from approved admission
  Future<void> createStudentFromAdmission(
      Map<String, dynamic> admission) async {
    try {
      // Create a new student document
      await _firestore.collection('students').add({
        'name': admission['name'],
        'email': admission['email'],
        'phone': admission['phone'],
        'address': admission['address'],
        'gender': admission['gender'],
        'dateOfBirth': admission['dateOfBirth'],
        'fatherName': admission['fatherName'],
        'motherName': admission['motherName'],
        'stream': admission['stream'],
        'category': admission['category'],
        'admissionId': admission['id'],
        'enrollmentDate': DateTime.now().toIso8601String(),
        'semester': 1,
        'status': 'active',
        'documents': admission['documentUrls'],
      });
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }
}
