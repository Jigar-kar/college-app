// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';

import 'package:bca_c/screens/login_screen.dart';
import 'package:bca_c/services/auth_service.dart';
import 'package:bca_c/services/subject_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For formatting the birth date

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthService _auth = AuthService();
  final SubjectService _subjectService = SubjectService();
  final _formKey = GlobalKey<FormState>();

  // Variables for user inputs
  String email = '',
      password = '',
      confirmPassword = '',
      name = '',
      rollNo = '',
      enrollmentNo = '',
      mobileNo = '';
  String selectedClass = 'FY', selectedCourse = '', selectedGender = 'Male';
  List<String> courses = [];
  List<String> selectedSubjects = [];
  List<String> availableSubjects = [];
  List<String> gender = ['Male', 'Female'];

  bool isLoading = false;
  File? studentPhoto;
  DateTime? birthDate; // For student birth date
  String parentsContact = ''; // Parent's contact number

  bool _passwordsMatch = true;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  // Fetch courses from Firestore
  Future<void> fetchCourses() async {
    try {
      List<String> courseList = await _subjectService.fetchCourses();
      setState(() {
        courses = courseList;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching courses: $e');
      }
    }
  }

  // Fetch subjects for selected course and class
  Future<void> fetchSubjectsForCourse() async {
    if (selectedCourse.isEmpty || selectedClass.isEmpty) return;

    setState(() {
      availableSubjects = [];
      selectedSubjects = [];
    });

    try {
      List<String> subjectsList = await _subjectService
          .fetchSubjectsForCourseAndClass(selectedCourse, selectedClass);
      setState(() {
        availableSubjects = subjectsList;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching subjects: $e');
      }
    }
  }

  // Select a photo for the student
  Future<void> pickStudentPhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        studentPhoto = File(pickedFile.path);
      });
    }
  }

  // Remove selected photo
  void removeStudentPhoto() {
    setState(() {
      studentPhoto = null;
    });
  }

  // Pick birth date
  Future<void> selectBirthDate() async {
    DateTime? selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        birthDate = selected;
      });
    }
  }

  void _checkPasswords() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
    });
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: kIsWeb ? 300 : 24.0,
          vertical: kIsWeb ? 40.0 : 16.0,
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              "Hello!",
              style: TextStyle(
                fontSize: kIsWeb ? 28 : 24,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Create Your Account",
              style: TextStyle(
                fontSize: kIsWeb ? 48 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kIsWeb ? 200 : 19,
                ),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: _buildInputDecoration('Name', Icons.person),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter your name' : null,
                      onChanged: (val) => name = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _buildInputDecoration('Email', Icons.email),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter an email' : null,
                      onChanged: (val) => email = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _buildInputDecoration('Password', Icons.lock).copyWith(
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                      validator: (val) {
                        if (val!.isEmpty) {
                          return 'Password is required';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        if (!_passwordsMatch) {
                          return 'Passwords must match';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        password = val;
                        _checkPasswords();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: _buildInputDecoration('Confirm Password', Icons.lock).copyWith(
                        errorText: !_passwordsMatch && _confirmPasswordController.text.isNotEmpty
                            ? 'Passwords do not match'
                            : null,
                        errorStyle: const TextStyle(color: Colors.red),
                        suffixIcon: _confirmPasswordController.text.isNotEmpty
                            ? Icon(
                                _passwordsMatch ? Icons.check_circle : Icons.error,
                                color: _passwordsMatch ? Colors.green : Colors.red,
                              )
                            : null,
                      ),
                      validator: (val) {
                        if (val!.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        confirmPassword = val;
                        _checkPasswords();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _buildInputDecoration(
                          'Roll No', Icons.confirmation_number),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter roll number' : null,
                      onChanged: (val) => rollNo = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _buildInputDecoration(
                          'Enrollment No', Icons.assignment),
                      validator: (val) => val!.isEmpty
                          ? 'Please enter enrollment number'
                          : null,
                      onChanged: (val) => enrollmentNo = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration:
                          _buildInputDecoration('Mobile No', Icons.phone),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter mobile number' : null,
                      onChanged: (val) => mobileNo = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration:
                          _buildInputDecoration('Parents Contact', Icons.phone),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter parents contact' : null,
                      onChanged: (val) => parentsContact = val,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: selectBirthDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: _buildInputDecoration(
                              'Birth Date', Icons.calendar_today),
                          validator: (val) => birthDate == null
                              ? 'Birth date is required'
                              : null,
                          controller: TextEditingController(
                            text: birthDate == null
                                ? ''
                                : DateFormat('dd/MM/yyyy').format(birthDate!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration('Gender', Icons.person)
                            .copyWith(
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        value: selectedGender,
                        items: gender.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedGender = val!;
                          });
                        },
                        validator: (val) =>
                            val == null ? 'Please select a gender' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration('Class', Icons.class_)
                            .copyWith(
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        value: selectedClass,
                        items: ['FY', 'SY', 'TY'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedClass = val!;
                            availableSubjects = [];
                            selectedSubjects = [];
                          });
                          fetchSubjectsForCourse();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration:
                            _buildInputDecoration('Course', Icons.school)
                                .copyWith(
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        value: selectedCourse.isEmpty ? null : selectedCourse,
                        items: courses.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedCourse = val!;
                            availableSubjects = [];
                            selectedSubjects = [];
                          });
                          fetchSubjectsForCourse();
                        },
                        validator: (val) =>
                            val == null ? 'Please select a course' : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (selectedCourse.isNotEmpty &&
                        availableSubjects.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Subjects",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...availableSubjects.map((subject) {
                            return CheckboxListTile(
                              title: Text(subject),
                              value: selectedSubjects.contains(subject),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedSubjects.add(subject);
                                  } else {
                                    selectedSubjects.remove(subject);
                                  }
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    const SizedBox(height: 20),
                    if (studentPhoto != null) ...[
                      const Text(
                        'Selected Photo:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          studentPhoto!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: removeStudentPhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Remove Photo",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate() && _passwordsMatch) {  // Add _passwordsMatch check
                                if (!_passwordsMatch) {  // Add explicit password match check
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Passwords do not match'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                setState(() => isLoading = true);
                                try {
                                  dynamic result = await _auth.registerStudent(
                                    email: email,
                                    password: password,
                                    name: name,
                                    rollNo: rollNo,
                                    enrollmentNo: enrollmentNo,
                                    mobileNo: mobileNo,
                                    parentsContact: parentsContact,
                                    birthDate: birthDate,
                                    className: selectedClass,
                                    course: selectedCourse,
                                    selectedSubjects: selectedSubjects,
                                    photoFile: studentPhoto,
                                    gender: selectedGender,
                                    
                                  );
                                  setState(() => isLoading = false);
                                  if (result == null) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Registration failed. Please try again.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen()),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  setState(() => isLoading = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                // Show error if passwords don't match
                                if (!_passwordsMatch) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please ensure passwords match before registering'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 110, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                          children: const [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }
}
