// ignore_for_file: unused_field, library_private_types_in_public_api

import 'package:bca_c/components/loader.dart';
import 'package:bca_c/services/marks_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color highMarksColor = Color(0xFF4CAF50);
  static const Color lowMarksColor = Color(0xFFE53935);
}

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key, required String rollNo});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  final MarksService _marksService = MarksService();
  Map<String, double> subjectMarks = {};
  bool isLoading = true;
  String? rollNo;
  double totalMarks = 0.0;
  double averagePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchRollNo();
  }

  Future<void> _fetchRollNo() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .doc(currentUser.uid)
            .get();

        if (studentSnapshot.exists) {
          setState(() {
            rollNo = studentSnapshot['rollNo'];
          });
          await _loadMarks(studentSnapshot['rollNo']);
        } else {
          _showErrorDialog('Student document not found.');
        }
      }
    } catch (e) {
      _showErrorDialog('Error fetching roll number: $e');
    }
  }

  Future<void> _loadMarks(String fetchedRollNo) async {
    setState(() => isLoading = true);

    try {
      QuerySnapshot marksSnapshot = await FirebaseFirestore.instance
          .collection('marks')
          .where('studentId', isEqualTo: fetchedRollNo)
          .get();

      if (marksSnapshot.docs.isNotEmpty) {
        DocumentSnapshot marksDocument = marksSnapshot.docs.first;
        Map<String, dynamic> marksData = marksDocument['marks'];
        totalMarks = marksDocument['totalMarks'];

        subjectMarks.clear();
        marksData.forEach((subject, marks) {
          subjectMarks[subject] = marks.toDouble();
        });

        if (subjectMarks.isNotEmpty) {
          double total = subjectMarks.values.reduce((a, b) => a + b);
          averagePercentage = (total / (subjectMarks.length * 100)) * 100;
        }
      } else {
        _showErrorDialog('No marks found for this student.');
      }
    } catch (e) {
      _showErrorDialog('Error loading marks: $e');
    } finally {
      setState(() => isLoading = false);
    }
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

  Widget _buildMarkCard(String subject, double marks) {
    Color statusColor =
        marks >= 60 ? AppColors.highMarksColor : AppColors.lowMarksColor;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor.withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${marks.toInt()}%',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  trailing: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween(begin: 0, end: marks / 100),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
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
                child: Column(
                  children: [
                    Row(
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
                        const Text(
                          "Academic Performance",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (!isLoading && subjectMarks.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overall Performance',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${averagePercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              tween:
                                  Tween(begin: 0, end: averagePercentage / 100),
                              builder: (context, value, _) =>
                                  CircularProgressIndicator(
                                value: value,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
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
                  child: isLoading
                      ? const Center(child: Loader())
                      : subjectMarks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assessment_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No marks available',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 16),
                              itemCount: subjectMarks.length,
                              itemBuilder: (context, index) {
                                String subject =
                                    subjectMarks.keys.elementAt(index);
                                double marks = subjectMarks[subject] ?? 0.0;
                                return _buildMarkCard(subject, marks);
                              },
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
