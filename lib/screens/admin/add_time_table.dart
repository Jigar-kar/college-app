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
}

class AddTimetablePage extends StatefulWidget {
  const AddTimetablePage({super.key});

  @override
  _AddTimetablePageState createState() => _AddTimetablePageState();
}

class _AddTimetablePageState extends State<AddTimetablePage> {
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _breakStartTimeController = TextEditingController();
  final _breakEndTimeController = TextEditingController();
  final _sportsStartTimeController = TextEditingController();
  final _sportsEndTimeController = TextEditingController();
  
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedDay;
  String? selectedTeacher;
  List<Map<String, dynamic>> availableTeachers = [];

  List<String> classOptions = ['FY', 'SY', 'TY'];
  List<String> subjects = ['Math', 'Science', 'English', 'Break', 'Sports'];
  bool _isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      await fetchSubjects();
    } catch (e) {
      _showErrorDialog('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<void> fetchSubjects() async {
    final subjectSnapshot = await _firestore.collection('subjects').where('class',isEqualTo: _selectedClass).get();
    setState(() {
      subjects = subjectSnapshot.docs.map((doc) => doc['name'] as String).toList();
      subjects.addAll(['Break', 'Sports']);
    });
  }

  Future<void> addTimetable() async {
    if (_selectedClass == null ||
        _selectedSubject == null ||
        _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select class, subject, and day'),
        ),
      );
      return;
    }

    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;
    final breakStartTime = _breakStartTimeController.text;
    final breakEndTime = _breakEndTimeController.text;
    final sportsStartTime = _sportsStartTimeController.text;
    final sportsEndTime = _sportsEndTimeController.text;

    Map<String, dynamic> timetableData = {
      'class': _selectedClass,
      'subject': _selectedSubject,
      'day': _selectedDay,
      'startTime': startTime,
      'endTime': endTime,
    };

    if (_selectedSubject == 'Break') {
      timetableData['startTime'] = breakStartTime;
      timetableData['endTime'] = breakEndTime;
    } else if (_selectedSubject == 'Sports') {
      timetableData['startTime'] = sportsStartTime;
      timetableData['endTime'] = sportsEndTime;
    }

    // Add timetable with updated status logic
    await _firestore.collection('timetables').add(timetableData);

    _startTimeController.clear();
    _endTimeController.clear();
    _breakStartTimeController.clear();
    _breakEndTimeController.clear();
    _sportsStartTimeController.clear();
    _sportsEndTimeController.clear();
    setState(() {
      _selectedClass = null;
      _selectedSubject = null;
      _selectedDay = null;
      selectedTeacher = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timetable added successfully')),
    );
  }
  Future<void> _selectStartTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = picked.format(context);
      _startTimeController.text = formattedTime;
    }
  }

  Future<void> _selectBreakStartTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = picked.format(context);
      _breakStartTimeController.text = formattedTime;
    }
  }

  Future<void> _selectBreakEndTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = picked.format(context);
      _breakEndTimeController.text = formattedTime;
    }
  }

  Future<void> _selectSportsStartTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = picked.format(context);
      _sportsStartTimeController.text = formattedTime;
    }
  }

  Future<void> _selectSportsEndTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = picked.format(context);
      _sportsEndTimeController.text = formattedTime;
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = picked.format(context);
      _endTimeController.text = formattedTime;
    }
  }

  void selectDay(String day) {
  setState(() {
    _selectedDay = day;
  });
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
                      child: Text(
                        "Add Timetable",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Class Dropdown
                                _buildDropdown(
                                  label: 'Select Class',
                                  value: _selectedClass,
                                  items: classOptions,
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

                                const SizedBox(height: 20),

                                // Subject Dropdown
                                _buildDropdown(
                                  label: 'Select Subject',
                                  value: _selectedSubject,
                                  items: subjects,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSubject = value;
                                      selectedTeacher = null;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a subject';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                if (_selectedSubject == 'Break') ...[                                  
                                  _buildTimeInput(
                                    'Break Start Time',
                                    _breakStartTimeController,
                                    _selectBreakStartTime,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTimeInput(
                                    'Break End Time',
                                    _breakEndTimeController,
                                    _selectBreakEndTime,
                                  ),
                                ] else if (_selectedSubject == 'Sports') ...[                                  
                                  _buildTimeInput(
                                    'Sports Start Time',
                                    _sportsStartTimeController,
                                    _selectSportsStartTime,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTimeInput(
                                    'Sports End Time',
                                    _sportsEndTimeController,
                                    _selectSportsEndTime,
                                  ),
                                ] else ...[                                  
                                  _buildTimeInput(
                                    'Start Time',
                                    _startTimeController,
                                    _selectStartTime,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTimeInput(
                                    'End Time',
                                    _endTimeController,
                                    _selectEndTime,
                                  ),
                                ],

                                const SizedBox(height: 20),

                                _buildDaySelection(),

                                const SizedBox(height: 30),

                                // Add Timetable Button
                                ElevatedButton(
                                  onPressed: addTimetable,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add Timetable',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
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
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: AppColors.textSecondary,
            ),
            border: InputBorder.none,
          ),
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildTimeInput(
    String label,
    TextEditingController controller,
    Future<void> Function(BuildContext) onTap,
  ) {
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
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: AppColors.textSecondary,
            ),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.access_time,
                color: AppColors.primaryColor,
              ),
              onPressed: () => onTap(context),
            ),
            border: InputBorder.none,
          ),
          readOnly: true,
          onTap: () => onTap(context),
        ),
      ),
    );
  }

  Widget _buildDaySelection() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Day',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: days.map((day) {
                return ChoiceChip(
                  label: Text(day),
                  selected: _selectedDay == day,
                  onSelected: (bool selected) {
                    selectDay(selected ? day : '');
                  },
                  selectedColor: AppColors.primaryColor.withOpacity(0.2),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedDay == day
                        ? AppColors.primaryColor
                        : AppColors.textPrimary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: _selectedDay == day
                          ? AppColors.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
