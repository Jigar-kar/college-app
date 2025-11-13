import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin/exam_result_approval_screen.dart'; // Import for AppColors

class ExamResultDetailsScreen extends StatefulWidget {
  final String examId;
  final String examName;

  const ExamResultDetailsScreen({
    super.key, 
    required this.examId, 
    required this.examName
  });

  @override
  _ExamResultDetailsScreenState createState() => _ExamResultDetailsScreenState();
}

class _ExamResultDetailsScreenState extends State<ExamResultDetailsScreen> {
  final _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _studentResults = [];
  bool _isLoading = true;
  String? _actualExamId;

  @override
  void initState() {
    super.initState();
    print('Initializing ExamResultDetailsScreen');
    print('Received Exam ID: ${widget.examId}');
    print('Received Exam Name: ${widget.examName}');
    _fetchExamId();
  }

  Future<void> _fetchExamId() async {
    try {
      print('Starting _fetchExamId method');
      print('Received Exam ID: ${widget.examId}');
      print('Received Exam Name: ${widget.examName}');

      // Log all exams in the collection for debugging
      final allExamsQuery = await _db.collection('exams').get();
      print('Total number of exams in collection: ${allExamsQuery.docs.length}');
      for (var examDoc in allExamsQuery.docs) {
        print('Existing Exam - ID: ${examDoc.id}, Name: ${examDoc.data()['examName']}');
      }

      // Try to find the exam by ID first
      if (widget.examId.isNotEmpty) {
        final examDoc = await _db.collection('exams').doc(widget.examId).get();
        if (examDoc.exists) {
          _actualExamId = widget.examId;
          print('Found exam by direct ID: $_actualExamId');
          _fetchExamResults();
          return;
        } else {
          print('No exam found with direct ID: ${widget.examId}');
        }
      }

      // If ID lookup fails, try finding by name
      final examQuery = await _db
          .collection('exams')
          .where('examName', isEqualTo: widget.examName)
          .limit(1)
          .get();

      if (examQuery.docs.isNotEmpty) {
        _actualExamId = examQuery.docs.first.id;
        print('Found exam ID by name: $_actualExamId');
        print('Exam details: ${examQuery.docs.first.data()}');
        _fetchExamResults();
        return;
      }

      // If no exam found by either ID or name
      throw Exception('No matching exam found');
    } catch (e) {
      print('Critical error in _fetchExamId: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Cannot find exam details: ${e.toString()}');
    }
  }

  Future<void> _fetchExamResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching exam results for exam ID: $_actualExamId');

      if (_actualExamId == null) {
        throw Exception('No valid exam ID found');
      }

      // Log exam document details
      final examDoc = await _db.collection('exams').doc(_actualExamId).get();
      if (!examDoc.exists) {
        print('Exam document not found for ID: $_actualExamId');
        setState(() {
          _isLoading = false;
          _studentResults = [];
        });
        _showErrorDialog('Exam not found. Please check the exam details.');
        return;
      }
      final examData = examDoc.data();
      if (examData == null) {
        print('Exam data is null for ID: $_actualExamId');
        setState(() {
          _isLoading = false;
          _studentResults = [];
        });
        _showErrorDialog('Invalid exam data. Please check the exam details.');
        return;
      }
      print('Exam document data: $examData');

      // Log all examResults for debugging
      final allResultsQuery = await _db.collection('examResults').get();
      print('Total number of exam results: ${allResultsQuery.docs.length}');
      for (var resultDoc in allResultsQuery.docs) {
        print('Existing Result - ID: ${resultDoc.id}, Data: ${resultDoc.data()}');
      }

      // Fetch results with more flexible querying
      var resultsSnapshot = await _db
          .collection('examResults')
          .where('examId', isEqualTo: _actualExamId)
          .where('status', isNotEqualTo: null)
          .get();

      print('Number of exam results found: ${resultsSnapshot.docs.length}');

      final List<Map<String, dynamic>> studentResults = [];

      if (resultsSnapshot.docs.isEmpty) {
        // Try alternative query if direct examId lookup fails
        final alternativeResultsSnapshot = await _db
            .collection('examResults')
            .where('examName', isEqualTo: widget.examName)
            .get();
        
        print('Alternative results found: ${alternativeResultsSnapshot.docs.length}');
        
        if (alternativeResultsSnapshot.docs.isEmpty) {
          setState(() {
            _studentResults = [];
            _isLoading = false;
          });
          _showErrorDialog('No student results found for this exam.');
          return;
        }

        // Use alternative results
        resultsSnapshot = alternativeResultsSnapshot;
      }

      for (var resultDoc in resultsSnapshot.docs) {
        final resultData = resultDoc.data();
        print('Result document data: $resultData');

        if (resultData['studentId'] == null) {
          print('Skipping result due to missing studentId');
          continue;
        }

        try {
          final studentDoc = await _db
              .collection('students')
              .doc(resultData['studentId'])
              .get();

          print('Student document exists: ${studentDoc.exists}');
          
          if (studentDoc.exists) {
            final studentData = studentDoc.data() ?? {};
            print('Student document data: $studentData');

            final combinedData = {
              'resultId': resultDoc.id,
              ...resultData,
              'studentName': studentData['name'] ?? 'Unknown Student',
              'studentRollNo': studentData['rollNo'] ?? 'N/A',
            };

            studentResults.add(combinedData);
            print('Added student result: $combinedData');
          } else {
            print('Student document not found for ID: ${resultData['studentId']}');
          }
        } catch (studentFetchError) {
          print('Error fetching student details: $studentFetchError');
        }
      }

      // Sort results by student roll number
      studentResults.sort((a, b) => 
        (a['studentRollNo'] ?? '').compareTo(b['studentRollNo'] ?? ''));

      setState(() {
        _studentResults = studentResults;
        _isLoading = false;
        print('Final student results: $_studentResults');
      });
    } catch (e) {
      print('Critical error in _fetchExamResults: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error fetching exam results: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    print('Showing error dialog: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building ExamResultDetailsScreen for exam: ${widget.examName}');
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.examName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "Student Exam Results",
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                      : _studentResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.no_accounts,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No student results found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _fetchExamResults,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _studentResults.length,
                              itemBuilder: (context, index) {
                                final result = _studentResults[index];
                                return _buildStudentResultCard(result);
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

  Widget _buildStudentResultCard(Map<String, dynamic> result) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  result['studentName'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Roll No: ${result['studentRollNo']}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildResultDetail('Total Marks', result['totalMarks']?.toString() ?? 'N/A'),
            _buildResultDetail('Obtained Marks', result['marksObtained']?.toString() ?? 'N/A'),
            _buildResultDetail('Status', result['status'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
