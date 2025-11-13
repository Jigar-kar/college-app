
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // GitHub credentials for photo upload
  static const String githubAccessToken = "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"; // Replace with your token
  static const String githubRepoOwner = "satuababa-bca-1"; // Replace with your GitHub username
  static const String githubRepoName = "Statuababa-Bca"; // Replace with your repository name

  /// Helper function to upload photo to GitHub
  Future<String?> _uploadPhotoToGitHub(File photoFile, String userId) async {
    try {
      final fileName = "$userId.jpg";
      final path = "user_photos/$fileName";
      final imageBytes = await photoFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final url = "https://api.github.com/repos/$githubRepoOwner/$githubRepoName/contents/$path";
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

  /// Register a teacher while ensuring the same document ID in both `users` and `teachers` collections
  Future<void> addTeacher({
    required String name,
    required String email,
    required String subject,
    required String className,
    required String phoneNumber,
    File? photoFile, // Optional photoFile parameter
  }) async {
    try {
      // Generate a unique ID for the teacher document
      final teacherId = _auth.currentUser?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Upload photo if provided
      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _uploadPhotoToGitHub(photoFile, teacherId);
      }

      await _db.collection('users').doc(teacherId).set({
        'email': email,
        'role': 'teacher',
        'teacherId': teacherId,
      });

      await _db.collection('teachers').doc(teacherId).set({
        'name': name,
        'email': email,
        'subject': subject,
        'class': className,
        'phone': phoneNumber,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Teacher added successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding teacher: $e');
      }
    }
  }

  Future<User?> registerStudent({
    required String email,
    required String password,
    required String name,
    required String rollNo,
    required String enrollmentNo,
    required String mobileNo,
    required String className,
    required String course,
    required List<String> selectedSubjects,
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
          'class': className,
          'course': course,
          'subjects': selectedSubjects.map((subject) => {'subjectName': subject}).toList(),
          'photoUrl': photoUrl,
        });

        return result.user;
      }
      throw Exception('Student not created.');
    } catch (e) {
      print('Error registering student: $e');
      return null;
    }
  }

  /// Fetch the role of the currently signed-in user
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

  /// Send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
    } catch (e) {
      print('Error sending password reset email: $e');
    }
  }

  /// Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // You can add more methods as needed...
}
