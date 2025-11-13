// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:bca_c/components/loader.dart';
import 'package:bca_c/services/subject_service.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color presentColor = Color(0xFF4CAF50);
  static const Color absentColor = Color(0xFFE53935);
  static const Color cardBg = Color(0xFFFAFAFA);
}

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  _AddSubjectScreenState createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _subjectCodeController = TextEditingController();
  final TextEditingController _subjectDescriptionController = TextEditingController();

  String? _selectedCourse;
  String? _selectedClass;
  List<String> _courses = [];
  final List<String> _classes = ['FY', 'SY', 'TY'];
  bool isLoading = false;

  final SubjectService _subjectService = SubjectService();

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  void _fetchCourses() async {
    try {
      List<String> courseList = await _subjectService.fetchCourses();
      setState(() {
        _courses = courseList;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching courses: $e'),
          backgroundColor: AppColors.absentColor,
        ),
      );
    }
  }

  void _addSubject() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      try {
        await _subjectService.addSubject(
          _selectedCourse,
          _selectedClass,
          _subjectNameController.text,
          _subjectCodeController.text,
          _subjectDescriptionController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject added successfully'),
            backgroundColor: AppColors.presentColor,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding subject: $e'),
            backgroundColor: AppColors.absentColor,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
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
                    const Text(
                      "Add New Subject",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDropdownCard(
                              title: 'Course',
                              value: _selectedCourse,
                              items: _courses,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCourse = value;
                                  _selectedClass = null; // Reset class selection when course changes
                                });
                              },
                              icon: Icons.school,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a course';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownCard(
                              title: 'Class',
                              value: _selectedClass,
                              items: _classes,
                              onChanged: (value) {
                                setState(() {
                                  _selectedClass = value;
                                });
                              },
                              icon: Icons.class_,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a class';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldCard(
                              controller: _subjectNameController,
                              title: 'Subject Name',
                              icon: Icons.book,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the subject name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldCard(
                              controller: _subjectCodeController,
                              title: 'Subject Code',
                              icon: Icons.code,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the subject code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldCard(
                              controller: _subjectDescriptionController,
                              title: 'Subject Description',
                              icon: Icons.description,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the subject description';
                                }
                                return null;
                              },
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: isLoading ? null : _addSubject,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.presentColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: isLoading
                                  ? const Loader()
                                  : const Text(
                                      "Add Subject",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
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

  Widget _buildDropdownCard({
    required String title,
    required dynamic value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required IconData icon,
    required String? Function(String?)? validator,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: value,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                hint: Text(title),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                dropdownColor: Colors.white,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
                validator: validator,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({
    required TextEditingController controller,
    required String title,
    required IconData icon,
    required String? Function(String?)? validator,
    int maxLines = 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: title,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: maxLines,
                validator: validator,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
