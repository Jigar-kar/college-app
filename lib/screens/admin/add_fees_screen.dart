import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class AddFeesScreen extends StatefulWidget {
  const AddFeesScreen({super.key});

  @override
  State<AddFeesScreen> createState() => _AddFeesScreenState();
}

class _AddFeesScreenState extends State<AddFeesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterClass = 'All';
  final _feesController = TextEditingController();
  String _selectedClass = 'FY';
  String _selectedSemester = 'Sem-1';
  final List<String> _classes = ['FY', 'SY', 'TY'];
  final Map<String, List<String>> _semestersByClass = {
    'FY': ['Sem-1', 'Sem-2'],
    'SY': ['Sem-3', 'Sem-4'],
    'TY': ['Sem-5', 'Sem-6'],
  };
  bool _isLoading = false;

  Future<void> _saveFees() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Get all students of the selected class
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('class', isEqualTo: _selectedClass)
            .get();

        // Create a list of student data
        final List<Map<String, dynamic>> studentsList = studentsSnapshot.docs
            .map((doc) => {
                  'studentId': doc.id,
                  'name': doc['name'] ?? 'Unknown',
                  'class': doc['class'],
                  'status': 'pending'
                })
            .toList();

        // Get current month and year
        final now = DateTime.now();
        final monthYear = '${now.month}-${now.year}';

        // Save to fees collection with student list
        await FirebaseFirestore.instance.collection('fees').add({
          'class': _selectedClass,
          'semester': _selectedSemester,
          'amount': double.parse(_feesController.text),
          'month': monthYear,
          'timestamp': FieldValue.serverTimestamp(),
          'students': studentsList, // Store the list of students
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fees added successfully for ${studentsList.length} students!'
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear the form
        _feesController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Add Student Fees'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: InputDecoration(
                  labelText: 'Select Class',
                  labelStyle: const TextStyle(color: AppColors.textPrimary),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                items: _classes.map((String class_) {
                  return DropdownMenuItem(
                    value: class_,
                    child: Text(class_),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedClass = newValue!;
                    _selectedSemester = _semestersByClass[newValue]!.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Semester Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                decoration: InputDecoration(
                  labelText: 'Select Semester',
                  labelStyle: const TextStyle(color: AppColors.textPrimary),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                items: _semestersByClass[_selectedClass]!.map((String semester) {
                  return DropdownMenuItem(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSemester = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Fees Amount Input
              TextFormField(
                controller: _feesController,
                decoration: InputDecoration(
                  labelText: 'Fees Amount',
                  labelStyle: const TextStyle(color: AppColors.textPrimary),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(color: AppColors.textPrimary),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter fees amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: _saveFees,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save Fees'),
                ),
              ),

              // Search and Filter Section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Students',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _filterClass,
                    items: ['All', ..._classes].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _filterClass = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Student Fees Status Table
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('fees')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Process and aggregate student data
                    Map<String, Map<String, dynamic>> studentFeesMap = {};
                    
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final students = (data['students'] as List<dynamic>);
                      
                      for (var student in students) {
                        final studentId = student['studentId'];
                        if (!studentFeesMap.containsKey(studentId)) {
                          studentFeesMap[studentId] = {
                            'name': student['name'],
                            'class': student['class'],
                            'pendingAmount': 0.0,
                            'pendingFees': [],
                          };
                        }
                        
                        if (student['status'] == 'pending') {
                          studentFeesMap[studentId]!['pendingAmount'] += 
                              (data['amount'] as num).toDouble();
                          studentFeesMap[studentId]!['pendingFees'].add(
                            '${data['semester']} (₹${data['amount']})',
                          );
                        }
                      }
                    }

                    // Filter and search
                    var filteredStudents = studentFeesMap.entries.where((entry) {
                      final student = entry.value;
                      final matchesSearch = student['name'].toString().toLowerCase()
                          .contains(_searchQuery);
                      final matchesClass = _filterClass == 'All' || 
                          student['class'] == _filterClass;
                      return matchesSearch && matchesClass;
                    }).toList();

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Expanded(flex: 3, child: Text('Pending Fees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Total Pending', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = filteredStudents[index].value;
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          student['name'].toString(),
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(student['class'].toString()),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text((student['pendingFees'] as List).join('\n')),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '₹${student['pendingAmount'].toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: (student['pendingAmount'] as double) > 0
                                                ? Colors.red
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }

  @override
  void dispose() {
    _feesController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}