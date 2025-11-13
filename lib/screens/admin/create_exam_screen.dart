import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color error = Colors.red;
  static const Color success = Colors.green;
}

class CreateExamScreen extends StatefulWidget {
  final String adminId;

  const CreateExamScreen({
    super.key,
    required this.adminId,
  });

  @override
  _CreateExamScreenState createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;

  final _examNameController = TextEditingController();
  final _totalMarksController =
      TextEditingController(text: '100'); // Default value
  String? _selectedClass;
  final List<Map<String, dynamic>> _selectedSubjects = [];
  List<String> _subjects = [];
  bool _isLoading = false;

  final List<String> _classes = ['FY', 'SY', 'TY'];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final snapshot = await _db.collection('subjects').get();
      final Set<String> uniqueSubjects = {}; // Using a Set to avoid duplicates
      for (var doc in snapshot.docs) {
        String name = doc['name'] as String;
        uniqueSubjects.add(name);
      }
      setState(() {
        _subjects = uniqueSubjects.toList()..sort(); // Convert to sorted list
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e')),
        );
      }
    }
  }

  Future<void> _addSubject() async {
    String? selectedSubject;
    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;
    final totalMarks = num.parse(_totalMarksController.text);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_circle,
                            color: AppColors.primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          'Add Subject',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        labelStyle:
                            const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.book,
                            color: AppColors.primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: selectedSubject,
                      items: _subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          labelStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today,
                              color: AppColors.primaryColor),
                        ),
                        child: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : selectedDate!
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  selectedStartTime = time;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Time',
                                labelStyle: const TextStyle(
                                    color: AppColors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.access_time,
                                    color: AppColors.primaryColor),
                              ),
                              child: Text(
                                selectedStartTime == null
                                    ? 'Select Time'
                                    : selectedStartTime!.format(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  selectedEndTime = time;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Time',
                                labelStyle: const TextStyle(
                                    color: AppColors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.access_time,
                                    color: AppColors.primaryColor),
                              ),
                              child: Text(
                                selectedEndTime == null
                                    ? 'Select Time'
                                    : selectedEndTime!.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedSubject != null &&
                                  selectedDate != null &&
                                  selectedStartTime != null &&
                                  selectedEndTime != null
                              ? () {
                                  _selectedSubjects.add({
                                    'subject': selectedSubject!,
                                    'date': selectedDate!,
                                    'startTime':
                                        selectedStartTime!.format(context),
                                    'endTime': selectedEndTime!.format(context),
                                    'totalMarks': totalMarks,
                                  });
                                  Navigator.pop(context);
                                  setState(() {});
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Add Subject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => setState(() {}));
  }

  Future<void> _createExam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one subject')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create a new exam for each selected subject
      for (final subject in _selectedSubjects) {
        // Convert end time string to DateTime
        final examDate = subject['date'] as DateTime;
        final endTimeStr = subject['endTime'] as String;
        final endTimeParts = endTimeStr.split(':');
        final endDateTime = DateTime(
          examDate.year,
          examDate.month,
          examDate.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1].split(' ')[0]),
        );

        final examData = {
          'examName': _examNameController.text,
          'subject': subject['subject'],
          'className': _selectedClass,
          'examDate': subject['date'],
          'startTime': subject['startTime'],
          'endTime': subject['endTime'],
          'endDateTime': endDateTime,
          'totalMarks': subject['totalMarks'],
          'createdBy': widget.adminId,
          'status':
              DateTime.now().isAfter(endDateTime) ? 'Completed' : 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _db.collection('exams').add(examData);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                            "Create Exam",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Schedule a new examination",
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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Exam Name Input
                            _buildInputContainer(
                              child: TextFormField(
                                controller: _examNameController,
                                decoration: const InputDecoration(
                                  labelText: "Exam Name",
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter exam name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInputContainer(
                              child: TextFormField(
                                controller: _totalMarksController,
                                decoration: const InputDecoration(
                                  labelText: "Total Marks",
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter total marks';
                                  }
                                  final marks = num.tryParse(value);
                                  if (marks == null || marks <= 0) {
                                    return 'Please enter a valid number greater than 0';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Class Input
                            _buildInputContainer(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: "Class",
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                ),
                                value: _selectedClass,
                                items: _classes
                                    .map((className) => DropdownMenuItem(
                                          value: className,
                                          child: Text(className),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedClass = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a class';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Add Subject Button
                            ElevatedButton(
                              onPressed: _addSubject,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Add Subject",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Selected Subjects
                            if (_selectedSubjects.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.grey[600]),
                                    const SizedBox(width: 12),
                                    Text(
                                      'No subjects selected',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _selectedSubjects.length,
                                itemBuilder: (context, index) {
                                  final subject = _selectedSubjects[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: AppColors.primaryColor,
                                        child: Icon(Icons.book,
                                            color: Colors.white),
                                      ),
                                      title: Text(
                                        subject['subject'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Date: ${subject['date'].toLocal().toString().split(' ')[0]}\n'
                                        'Time: ${subject['startTime']} - ${subject['endTime']}\n'
                                        'Total Marks: ${subject['totalMarks']}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: AppColors.error),
                                        onPressed: () {
                                          setState(() {
                                            _selectedSubjects.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 24),

                            // Create Exam Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _createExam,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle),
                                        SizedBox(width: 8),
                                        Text(
                                          'Create Exam',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: child,
      ),
    );
  }
}
