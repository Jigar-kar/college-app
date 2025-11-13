import 'package:bca_c/components/loader.dart';
import 'package:bca_c/services/marks_service.dart';
import 'package:bca_c/services/teacher_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class MarksManagement extends StatefulWidget {
  const MarksManagement({super.key});

  @override
  _MarksManagementState createState() => _MarksManagementState();
}

class _MarksManagementState extends State<MarksManagement> {
  final MarksService _marksService = MarksService();
  final TeacherService _teacherService = TeacherService();

  bool isLoading = false;
  List<Map<String, dynamic>> students = [];
  String? teacherClass;
  String? selectedClass;
  List<String> classList = ['FY', 'SY', 'TY'];

  @override
  void initState() {
    super.initState();
    fetchTeacherClass();
  }

  Future<void> fetchTeacherClass() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        if (classList.isNotEmpty) {
          setState(() {
            selectedClass = classList.first;
          });
          await fetchStudents();
        } else {
          print('Teacher class not found in Firestore');
        }
      } catch (e) {
        print('Error fetching teacher class: $e');
      }
    }
  }

  Future<void> fetchStudents() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('status', isEqualTo: 'active')
          .get();

      List<Map<String, dynamic>> fetchedStudents = [];

      for (var doc in studentSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String studentClass = data['class'] ?? 'Unknown';
        int rollNo = int.tryParse(data['rollNo'].toString()) ?? 0;

        fetchedStudents.add({
          'rollNo': rollNo,
          'name': data['name'],
          'class': studentClass,
        });
      }

      fetchedStudents.sort((a, b) {
        return (a['rollNo'] as int).compareTo(b['rollNo'] as int);
      });

      setState(() {
        students = fetchedStudents;
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch students. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> getFilteredStudents() {
    if (selectedClass != null) {
      return students.where((student) {
        return student['class'] == selectedClass;
      }).toList();
    }
    return students;
  }

  Future<void> fetchSubjectsAndSubmitMarks(String rollNo) async {
    setState(() {
      isLoading = true;
    });

    try {
      Map<String, double> fetchedMarks =
          await _marksService.fetchSubjectsAndMarks(rollNo);

      if (fetchedMarks.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Enter Marks for Subjects'),
              content: SingleChildScrollView(
                child: Column(
                  children: fetchedMarks.keys.map((subject) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: subject,
                          hintText: 'Enter marks for $subject',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          double? marks = double.tryParse(value);
                          if (marks != null) {
                            fetchedMarks[subject] = marks;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await submitMarks(rollNo, fetchedMarks);
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No subjects found for this student.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch subjects. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submitMarks(
      String rollNo, Map<String, double> subjectMarks) async {
    try {
      if (subjectMarks.isNotEmpty) {
        await _marksService.submitMarks(rollNo, subjectMarks);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Marks submitted successfully! Total: ${subjectMarks.values.fold(0.0, (sum, marks) => sum + marks)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit marks. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
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
                                'Marks Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Manage student marks',
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
                    const SizedBox(height: 20),
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
                        children: classList.map((course) {
                          bool isSelected = selectedClass == course;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => selectedClass = course),
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
                      : getFilteredStudents().isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
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
                                var student = getFilteredStudents()[index];
                                String rollNo = student['rollNo'].toString();
                                String name = student['name'];
                                String studentClass = student['class'];

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
                                          margin:
                                              const EdgeInsets.only(bottom: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: InkWell(
                                            onTap: () =>
                                                fetchSubjectsAndSubmitMarks(
                                                    rollNo),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: AppColors
                                                          .primaryColor
                                                          .withOpacity(0.1),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        rollNo,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          name,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          'Class: $studentClass',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.edit,
                                                    size: 20,
                                                    color:
                                                        AppColors.primaryColor,
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
