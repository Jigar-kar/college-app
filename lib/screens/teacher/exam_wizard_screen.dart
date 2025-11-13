import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/exam_model.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
}

class ExamWizardScreen extends StatefulWidget {
  final ExamModel? exam;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> results;
  final String teacherId;

  const ExamWizardScreen({
    super.key,
    this.exam,
    required this.students,
    required this.results,
    required this.teacherId,
  });

  @override
  State<ExamWizardScreen> createState() => _ExamWizardScreenState();
}

class _ExamWizardScreenState extends State<ExamWizardScreen> {
  final _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _marksController = TextEditingController();
  final _searchController = TextEditingController();
  
  int _currentIndex = 0;
  bool _isLoading = false;
  final Map<String, num> _marksMap = {};

  @override
  void initState() {
    super.initState();
    _loadExistingMarks();
  }

  @override
  void dispose() {
    _marksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadExistingMarks() {
    for (var result in widget.results) {
      _marksMap[result['studentId']] = result['marksObtained'];
    }
    _updateMarksController();
  }

  void _updateMarksController() {
    if (widget.students.isEmpty) {
      _marksController.text = '';
      return;
    }
    final studentId = widget.students[_currentIndex]['id'];
    _marksController.text = _marksMap[studentId]?.toString() ?? '';
  }

  Future<void> _saveCurrentMarks() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final student = widget.students[_currentIndex];
      final marks = num.parse(_marksController.text);
      _marksMap[student['id']] = marks;

      // Find existing result document
      final QuerySnapshot existingResults = await _db
          .collection('examResults')
          .where('examId', isEqualTo: widget.exam?.id)
          .where('studentId', isEqualTo: student['id'])
          .get();

      if (existingResults.docs.isNotEmpty) {
        // Update existing result
        await _db.collection('examResults').doc(existingResults.docs.first.id).update({
          'marksObtained': marks,
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'Pending',
        });
      } else {
        // Create new result
        if (widget.exam == null) {
          throw Exception('Exam data is missing');
        }

        await _db.collection('examResults').add({
          'examId': widget.exam!.id,
          'studentId': student['id'],
          'studentName': student['name'],
          'marksObtained': marks,
          'className': student['class'],
          'subject': widget.exam!.subject,
          'examName': widget.exam!.examName,
          'teacherId': widget.teacherId,
          'totalMarks': widget.exam!.totalMarks,
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update exam status to Completed
      await _db.collection('exams').doc(widget.exam!.id).update({
        'status': 'Completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving marks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _moveNext() async {
    if (_currentIndex < widget.students.length - 1) {
      try {
        await _saveCurrentMarks();
        setState(() {
          _currentIndex++;
          _updateMarksController();
        });
      } catch (e) {
        // Error already shown in _saveCurrentMarks
      }
    }
  }

  Future<void> _movePrevious() async {
    if (_currentIndex > 0) {
      try {
        await _saveCurrentMarks();
        setState(() {
          _currentIndex--;
          _updateMarksController();
        });
      } catch (e) {
        // Error already shown in _saveCurrentMarks
      }
    }
  }

  Future<void> _finishMarksEntry() async {
    setState(() => _isLoading = true);

    try {
      await _saveCurrentMarks();

      // Update exam status to completed
      if (widget.exam != null) {
        await _db.collection('exams').doc(widget.exam!.id).update({
          'status': 'Graded',
          'totalStudents': widget.students.length,
          'submittedResults': widget.students.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam completed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing exam: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _searchStudent(String rollNo) {
    if (rollNo.isEmpty) return;
    
    final searchTerm = rollNo.toLowerCase().trim();
    final index = widget.students.indexWhere((student) {
      final studentRoll = student['rollNo']?.toString().toLowerCase().trim() ?? '';
      return studentRoll == searchTerm;
    });
    
    if (index != -1) {
      setState(() {
        _currentIndex = index;
        _updateMarksController();
      });
      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student found!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student not found with this roll number'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.students[_currentIndex];
    final bool canAddMarks = widget.exam?.status.toLowerCase() == 'completed';
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.exam?.examName ?? 'Exam'} - Add Marks',
          style: const TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: !canAddMarks
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_clock,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Marks can only be added after exam completion',
                    style: TextStyle(
                      fontSize: isWeb ? 24 : 18,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Current Status: ${widget.exam?.status ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: isWeb ? 18 : 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? screenSize.width * 0.1 : 16.0,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search by Roll No',
                                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.primaryColor),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onSubmitted: _searchStudent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () => _searchStudent(_searchController.text),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Search'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Progress Indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: (_currentIndex + 1) / widget.students.length,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Student ${_currentIndex + 1} of ${widget.students.length}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: isWeb ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Student Information Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Colors.white, AppColors.cardBg],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: AppColors.primaryColor),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Student Information',
                                    style: TextStyle(
                                      fontSize: isWeb ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              InfoRow(
                                label: 'Name',
                                value: student['name'] ?? 'Unknown',
                                isWeb: isWeb,
                              ),
                              const SizedBox(height: 8),
                              InfoRow(
                                label: 'Class',
                                value: student['class'] ?? 'Unknown',
                                isWeb: isWeb,
                              ),
                              const SizedBox(height: 8),
                              InfoRow(
                                label: 'Roll No',
                                value: student['rollNo'] ?? 'Unknown',
                                isWeb: isWeb,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Marks Entry Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Colors.white, AppColors.cardBg],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.edit, color: AppColors.primaryColor),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Enter Marks',
                                    style: TextStyle(
                                      fontSize: isWeb ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _marksController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: isWeb ? 18 : 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Marks',
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: isWeb ? 16 : 14,
                                  ),
                                  hintText: 'Enter marks out of ${widget.exam?.totalMarks}',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.primaryColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.accentColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.grade, color: AppColors.primaryColor),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter marks';
                                  }
                                  final marks = num.tryParse(value);
                                  if (marks == null) {
                                    return 'Please enter a valid number';
                                  }
                                  if (marks < 0) {
                                    return 'Marks cannot be negative';
                                  }
                                  if (marks > (widget.exam?.totalMarks ?? 0)) {
                                    return 'Marks cannot exceed total marks';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Navigation Buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentIndex > 0)
                              ElevatedButton.icon(
                                onPressed: _movePrevious,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Previous'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: AppColors.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            if (_currentIndex < widget.students.length - 1)
                              ElevatedButton.icon(
                                onPressed: _moveNext,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Next'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: AppColors.accentColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _finishMarksEntry,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(_isLoading ? 'Saving...' : 'Finish'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWeb;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: isWeb ? 16 : 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isWeb ? 16 : 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
