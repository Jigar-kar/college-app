// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:bca_c/components/loader.dart';
import 'package:bca_c/models/student.dart';
import 'package:bca_c/screens/teacher/attendance_hestory_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';

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

class AttendanceManagement extends StatefulWidget {
  const AttendanceManagement({super.key});

  @override
  _AttendanceManagementState createState() => _AttendanceManagementState();
}

class _AttendanceManagementState extends State<AttendanceManagement> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, List<Student>> courseStudents = {};
  Map<String, bool> attendanceStatus = {};
  bool isLoading = true;
  String? teacherId;
  String selectedCourse = "All"; // Default filter
  String selectedSubject = ""; // Field to store selected subject
  DateTime selectedDate =
      DateTime.now(); // Field to store selected date for lecture
  List<String> subjects = []; // To store fetched subjects

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
    fetchStudents();
    fetchSubjects(); // Fetch subjects from Firebase
  }

  Future<void> fetchTeacherData() async {
    final user = _auth.currentUser;
    if (user != null) teacherId = user.uid;
  }

  Future<void> fetchStudents() async {
    try {
      setState(() => isLoading = true);

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String course = data['class'] ?? 'Unknown';
        Student student = Student.fromFirestore(data, doc.id);

        courseStudents.putIfAbsent(course, () => []).add(student);
        attendanceStatus[student.id] = true; // Default 'present'
      }

      courseStudents.forEach((_, students) {
        students.sort((a, b) => a.rollNo.compareTo(b.rollNo));
      });

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching students: $e');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchSubjects() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('subjects').get();
      List<String> fetchedSubjects =
          snapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        subjects = fetchedSubjects;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching subjects: $e');
      }
    }
  }

  void toggleAttendance(String studentId) {
    setState(() =>
        attendanceStatus[studentId] = !(attendanceStatus[studentId] ?? false));
  }

  // Method to prompt for subject selection
  Future<void> selectSubject() async {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subjects available.')),
      );
      return;
    }

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Subject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: subjects.map((subject) {
              return ListTile(
                title: Text(subject),
                onTap: () {
                  setState(() {
                    selectedSubject = subject;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Method to prompt for date selection
  Future<void> selectDate() async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (newDate != null) {
      setState(() {
        selectedDate = newDate;
      });
    }
  }

  Future<void> submitAttendance() async {
    if (selectedSubject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first.')),
      );
      return;
    }

    // Filter students by selected class
    List<Student> studentsToAttend;
    if (selectedCourse == "All") {
      studentsToAttend =
          courseStudents.values.expand((students) => students).toList();
    } else {
      studentsToAttend = courseStudents[selectedCourse] ?? [];
    }

    if (studentsToAttend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to submit attendance for.')),
      );
      return;
    }

    try {
      var batch = FirebaseFirestore.instance.batch();

      for (var student in studentsToAttend) {
        batch.set(
          FirebaseFirestore.instance.collection('attendance').doc(),
          {
            'studentId': student.id,
            'teacherId': teacherId,
            'status':
                attendanceStatus[student.id] == true ? 'present' : 'absent',
            'date': FieldValue.serverTimestamp(),
            'course': selectedCourse,
            'rollNo': student.rollNo,
            'subject': selectedSubject, // Include the subject
            'lectureDate': selectedDate, // Store the lecture date
          },
        );
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance submitted successfully!')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting attendance: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit attendance!')),
      );
    }
  }

  Widget _buildStudentCard(Student student) {
    bool isPresent = attendanceStatus[student.id] == true;

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
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () => toggleAttendance(student.id),
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (isPresent ? AppColors.success : AppColors.error)
                                  .withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            student.rollNo.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPresent
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isPresent ? 'Present' : 'Absent',
                              style: TextStyle(
                                fontSize: 14,
                                color: isPresent
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isPresent ? Icons.check_circle : Icons.remove_circle,
                        color: isPresent ? AppColors.success : AppColors.error,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Student> getFilteredStudents() {
    if (selectedCourse == "All") {
      return courseStudents.values.expand((students) => students).toList();
    }
    return courseStudents[selectedCourse] ?? [];
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Manage student attendance',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.history,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AttendanceHistoryPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Class Selection
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ["All", "FY", "SY", "TY"].map((course) {
                          bool isSelected = selectedCourse == course;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => selectedCourse = course),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  course,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subject and Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: selectSubject,
                            icon: const Icon(Icons.book),
                            label: Text(
                              selectedSubject.isEmpty
                                  ? 'Select Subject'
                                  : selectedSubject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: selectDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              "${selectedDate.toLocal()}".split(' ')[0],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  child: Column(
                    children: [
                      Expanded(
                        child: isLoading
                            ? const Center(child: Loader())
                            : getFilteredStudents().isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No students found',
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
                                    itemCount: getFilteredStudents().length,
                                    itemBuilder: (context, index) {
                                      return _buildStudentCard(
                                          getFilteredStudents()[index]);
                                    },
                                  ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: submitAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Submit Attendance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
