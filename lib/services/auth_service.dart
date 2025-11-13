import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String githubAccessToken =
      "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";
  static const String githubRepoOwner = "satuababa-bca-1";
  static const String githubRepoName = "Statuababa-Bca";

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // First check in students collection
        final studentDoc = await _db
            .collection('students')
            .doc(userCredential.user!.uid)
            .get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final status = studentData['status'] as String?;

          if (status == 'active') {
            return userCredential.user;
          } else {
            await _auth.signOut();
            throw Exception(
                'Your student account is not active. Please contact administrator.');
          }
        }

        // If not found in students, check in teachers collection
        final teacherDoc = await _db
            .collection('teachers')
            .doc(userCredential.user!.uid)
            .get();
        if (teacherDoc.exists) {
          final teacherData = teacherDoc.data() as Map<String, dynamic>;
          final status = teacherData['status'] as String?;

          if (status == 'active') {
            return userCredential.user;
          } else {
            await _auth.signOut();
            throw Exception(
                'Your teacher account is not active. Please contact administrator.');
          }
        }

        // If not found in either collection but is admin
        if (email == 'admin') {
          return userCredential.user;
        }

        // If user not found in any collection
        await _auth.signOut();
        throw Exception(
            'User profile not found. Please contact administrator.');
      }
      return null;
    } catch (e) {
      print('Error signing in: $e');
      rethrow; // Rethrow to handle specific error messages in UI
    }
  }

  Future<User?> registerWithEmailAndPassword(
      String email, String password, String role) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _db.collection('users').doc(result.user!.uid).set({
          'email': email,
          'role': role,
        });
        return result.user;
      }
      throw Exception('User not created.');
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  Future<String?> _uploadPhotoToGitHub(File photoFile, String userId) async {
    try {
      final fileName = "$userId.jpg";
      final path = "user_photos/$fileName";
      final imageBytes = await photoFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final url =
          "https://api.github.com/repos/$githubRepoOwner/$githubRepoName/contents/$path";
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $githubAccessToken",
          "Accept": "application/vnd.github.v3+json",
        },
        body: jsonEncode({
          "message": "Upload photo for $userId",
          "content": base64Image,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['content']['download_url'];
      } else {
        print("Failed to upload photo: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error uploading photo to GitHub: $e");
      return null;
    }
  }

  Future<User?> registerStudent({
    required String email,
    required String password,
    required String name,
    required String rollNo,
    required String enrollmentNo,
    required String mobileNo,
    required String parentsContact,
    required DateTime? birthDate,
    required String className,
    required String course,
    required List<String> selectedSubjects,
    required String gender,
    File? photoFile,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        String? photoUrl;
        if (photoFile != null) {
          photoUrl = await _uploadPhotoToGitHub(photoFile, result.user!.uid);
        }

        await _db.collection('users').doc(result.user!.uid).set({
          'email': email,
          'role': 'student',
        });

        await _db.collection('students').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'rollNo': rollNo,
          'enrollmentNo': enrollmentNo,
          'mobileNo': mobileNo,
          'parentsContact': parentsContact,
          'birthDate': birthDate,
          'class': className,
          'course': course,
          'subjects': selectedSubjects
              .map((subject) => {'subjectName': subject})
              .toList(),
          'photoUrl': photoUrl,
          'status': 'pending',
          'gender': gender,
        });

        return result.user;
      }
      throw Exception('Student not created.');
    } catch (e) {
      print('Error registering student: $e');
      return null;
    }
  }

  Future<String> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _db.collection('users').doc(user.uid).get();
        return snapshot['role'] ?? '';
      }
      return '';
    } catch (e) {
      print('Error fetching user role: $e');
      return '';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
    } catch (e) {
      print('Error sending password reset email: $e');
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }


}
