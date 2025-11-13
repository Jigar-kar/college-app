import 'package:bca_c/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'teacher_details.dart'; // Import the details screen

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
}

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _navigateToDetails(BuildContext context, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(name: name),
      ),
    );
  }

  Future<void> _deleteTeacher(String teacherName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Find teacher document
      final teacherQuery = await _firestore
          .collection('teachers')
          .where('name', isEqualTo: teacherName)
          .get();

      if (teacherQuery.docs.isEmpty) {
        Navigator.pop(context);
        _showErrorDialog('Teacher not found');
        return;
      }

      final teacherDoc = teacherQuery.docs.first;
      final teacherId = teacherDoc.id;
      final teacherData = teacherDoc.data();
      final teacherEmail = teacherData['email'];

      // Find user document
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: teacherEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        Navigator.pop(context);
        _showErrorDialog('User not found');
        return;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;

      // Comprehensive deletion strategy
      try {
        try {
          // Attempt to delete from Authentication
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.email == teacherEmail) {
            await currentUser.delete();
          } else {
            await _auth.signOut();
            
            try {
              final userCredential = await _auth.signInWithEmailAndPassword(
                email: teacherEmail,
                password: teacherData['password'] ?? '',
              );
              await userCredential.user?.delete();
            } catch (signInError) {
              print('Could not sign in to delete user: $signInError');
            }
          }
        } catch (authError) {
          print('Authentication deletion error: $authError');
        }

        // Delete Firestore documents
        await _firestore.collection('teachers').doc(teacherId).delete();
        await _firestore.collection('users').doc(userId).delete();

        // Delete related exam results or other collections if needed
        final examsQuery = await _firestore
            .collection('exams')
            .where('teacherId', isEqualTo: teacherId)
            .get();

        for (var examDoc in examsQuery.docs) {
          await examDoc.reference.delete();
        }

        // Refresh the screen
        Navigator.pop(context);
        setState(() {});

        // Show success dialog
        _showSuccessDialog('Teacher deleted successfully');

      } catch (comprehensiveDeletionError) {
        Navigator.pop(context);
        _showErrorDialog('Comprehensive deletion failed: $comprehensiveDeletionError');
        print('Comprehensive deletion error: $comprehensiveDeletionError');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Unexpected error: ${e.toString()}');
      print('Unexpected deletion error: $e');
    } finally {
      try {
        await _auth.signOut();
      } catch (signOutError) {
        print('Error during sign out: $signOutError');
      }
    }
  }

  void _showDeleteConfirmationDialog(String teacherName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirm Deletion', 
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87),
            children: [
              const TextSpan(text: 'Are you sure you want to permanently delete '),
              TextSpan(
                text: teacherName, 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              const TextSpan(text: '?\n\nThis will remove the teacher from all systems and cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteTeacher(teacherName);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(
    BuildContext context,
    String teacherName,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    teacherName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () => _showDeleteConfirmationDialog(teacherName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListSection({
    required BuildContext context,
    required Future<List<String>> future,
    required void Function(String name) onTap,
  }) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No teachers found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildTeacherCard(
                context,
                snapshot.data![index],
                () => onTap(snapshot.data![index]),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Overview of College Staff",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'View and manage staff details',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildListSection(
                    context: context,
                    future: UserService().getTeacherNames(),
                    onTap: (name) => _navigateToDetails(context, name),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
