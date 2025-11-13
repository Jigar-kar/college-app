import 'package:bca_c/models/exam_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'exam_result_details_screen.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
}

class ExamResultApprovalScreen extends StatefulWidget {
  const ExamResultApprovalScreen({super.key});

  @override
  _ExamResultApprovalScreenState createState() => _ExamResultApprovalScreenState();
}

class _ExamResultApprovalScreenState extends State<ExamResultApprovalScreen> {
  final _db = FirebaseFirestore.instance;
  String? _selectedExamId;
  String  eid = '';
  ExamModel? _selectedExam;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingResults();
  }

  Future<void> _fetchPendingResults() async {
    print('Fetching pending results');
    setState(() {
      _isLoading = true;
    });

    try {
      final resultsSnapshot = await _db
          .collection('examResults')
          .where('status', isEqualTo: 'Pending')
          .get();

      print('Number of pending results found: ${resultsSnapshot.docs.length}');

      final List<Map<String, dynamic>> pendingResults = [];
      
      for (var resultDoc in resultsSnapshot.docs) {
        final resultData = resultDoc.data();
        print('Result document data: $resultData');

        try {
          // Try to fetch the corresponding exam details
          final examDoc = await _db.collection('exams').doc(resultData['examId']).get();
          
          if (examDoc.exists) {
            final combinedData = {
              'id': resultDoc.id,
              ...resultData,
              ...examDoc.data() ?? {},
            };
            
            print('Combined result data: $combinedData');
            pendingResults.add(combinedData);
          } else {
            print('No corresponding exam found for result: ${resultDoc.id}');
          }
        } catch (e) {
          print('Error fetching exam details: $e');
        }
      }

      setState(() {
        _results = pendingResults;
        _isLoading = false;
        print('Updated results list: $_results');
        
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error in _fetchPendingResults: $e');
      _showErrorDialog('Error fetching results: ${e.toString()}');
    }
  }

  Future<void> _approveResult(String resultId) async {
    print('Attempting to approve result with ID: $resultId');
    
    try {
      // Log the initial state of the results list
      print('Initial results list: $_results');

      // First, check if the document exists
      final docRef = _db.collection('examResults').doc(resultId);
      final docSnapshot = await docRef.get();

      print('Document snapshot exists: ${docSnapshot.exists}');
      print('Document data: ${docSnapshot.data()}');

      if (!docSnapshot.exists) {
        print('Result document not found for ID: $resultId');
        _showErrorDialog('Result document not found. It may have been deleted or does not exist.');
        
        setState(() {
          _results.removeWhere((result) => result['id'] == resultId);
        });
        return;
      }

      await docRef.update({
        'status': 'Approved',
        'approvedAt': FieldValue.serverTimestamp()
      });

      print('Document updated successfully');

      await _fetchPendingResults();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result approved successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      print('Error in _approveResult: $e');
      _showErrorDialog('Error approving result: ${e.toString()}');
    }
  }

  Future<void> _rejectResult(String resultId) async {
    print('Attempting to reject result with ID: $resultId');
    
    try {
      // Log the initial state of the results list
      print('Initial results list: $_results');

      // First, check if the document exists
      final docRef = _db.collection('examResults').doc(resultId);
      final docSnapshot = await docRef.get();

      print('Document snapshot exists: ${docSnapshot.exists}');
      print('Document data: ${docSnapshot.data()}');

      if (!docSnapshot.exists) {
        // If the document doesn't exist, show an error
        print('Result document not found for ID: $resultId');
        _showErrorDialog('Result document not found. It may have been deleted or does not exist.');
        
        // Remove the item from local state to reflect the UI
        setState(() {
          _results.removeWhere((result) => result['id'] == resultId);
        });
        return;
      }

      // Update the document status
      await docRef.update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp()
      });

      print('Document updated successfully');

      // Refresh the results list to ensure we have the latest data
      await _fetchPendingResults();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result rejected'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      print('Error in _rejectResult: $e');
      _showErrorDialog('Error rejecting result: ${e.toString()}');
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';
    
    // If it's a Firestore Timestamp
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate().toLocal();
      return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
    }
    
    // If it's already a DateTime
    if (timestamp is DateTime) {
      return '${_formatDate(timestamp)} at ${_formatTime(timestamp)}';
    }
    
    // If it's a string, try to parse it
    try {
      DateTime parsedDate = DateTime.parse(timestamp.toString());
      return '${_formatDate(parsedDate)} at ${_formatTime(parsedDate)}';
    } catch (e) {
      return timestamp.toString();
    }
  }

  String _formatDate(DateTime date) {
    return '${_addZero(date.day)}/${_addZero(date.month)}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${_addZero(date.hour)}:${_addZero(date.minute)}';
  }

  String _addZero(int number) {
    return number.toString().padLeft(2, '0');
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
                            "Exam Results",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Approve or reject pending results",
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
                      : _results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.checklist,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No pending results to approve',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final result = _results[index];
                                return _buildResultCard(result);
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

  Widget _buildResultCard(Map<String, dynamic> result) {
    return GestureDetector(
      onTap: () {
        print('Tapped exam result with data: $result');
        
        // Ensure we have both ID and name
        final examId = result['id'] ?? result['examId'] ?? '';
        final examName = result['examName'] ?? 'Exam Details';

        print('Navigating to exam details - ID: $examId, Name: $examName');

        // Navigate to exam result details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamResultDetailsScreen(
              examId: examId,
              examName: examName,
            ),
          ),
        );
      },
      child: Container(
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
              Text(
                'Exam: ${result['examName']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Tap For More Information',
                style: TextStyle(
                  fontSize: 12,
                  color: Color.fromARGB(173, 84, 110, 122),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Class: ${result['className']}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Date: ${_formatTimestamp(result['examDate'])}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveResult(result['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rejectResult(result['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
