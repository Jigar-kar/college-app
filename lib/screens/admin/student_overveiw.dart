import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'detail_screen.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
}

class StudentOverviewScreen extends StatefulWidget {
  const StudentOverviewScreen({super.key});

  @override
  _StudentOverviewScreenState createState() => _StudentOverviewScreenState();
}

class _StudentOverviewScreenState extends State<StudentOverviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Set<String> selectedStudents = {};
  bool isSelectionMode = false;
  String selectedClass = "All";
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  final List<String> classes = ["All", "FY", "SY", "TY"];

  // Add statistics variables
  int totalStudents = 0;
  int maleCount = 0;
  int femaleCount = 0;

  String hoveredStatItem = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    try {
      QuerySnapshot snapshot = await _firestore.collection('students').get();
      setState(() {
        students = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? 'No Name',
            'class': data['class'] ?? 'No Class',
            'gender': data['gender'] ?? 'Not Specified',
          };
        }).toList();
        _updateStatistics();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() => isLoading = false);
    }
  }

  void _updateStatistics() {
    final filteredStudents = getFilteredStudents();
    totalStudents = filteredStudents.length;
    maleCount = filteredStudents.where((student) => student['gender'] == 'Male').length;
    femaleCount = filteredStudents.where((student) => student['gender'] == 'Female').length;
  }

  List<Map<String, dynamic>> getFilteredStudents() {
    List<Map<String, dynamic>> filtered = selectedClass == "All" 
        ? students 
        : students.where((student) => student['class'] == selectedClass).toList();
    
    setState(() {
      totalStudents = filtered.length;
      maleCount = filtered.where((student) => student['gender'] == 'Male').length;
      femaleCount = filtered.where((student) => student['gender'] == 'Female').length;
    });
    
    return filtered;
  }

  Widget _buildClassFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            "Filter by Class:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedClass,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
                  items: classes.map((String class_) {
                    return DropdownMenuItem<String>(
                      value: class_,
                      child: Text(
                        class_,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedClass = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                icon: Icons.people,
                label: 'Total Students',
                value: totalStudents.toString(),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.male,
                label: 'Boys',
                value: maleCount.toString(),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.female,
                label: 'Girls',
                value: femaleCount.toString(),
              ),
            ],
          ),
          if (selectedClass != "All") ...[
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Class $selectedClass Statistics',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        hoveredStatItem = label;
      }),
      onExit: (_) => setState(() {
        hoveredStatItem = '';
      }),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: hoveredStatItem.isEmpty || hoveredStatItem == label ? 1.0 : 0.5,
        child: Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, String name, bool isStudent) {
    if (!isSelectionMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(name: name, isStudent: isStudent),
        ),
      );
    }
  }

  Future<void> _deleteSelectedStudents() async {
    if (selectedStudents.isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${selectedStudents.length} selected students? This action cannot be undone.',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _performDeletion();
              },
              child: const Text('Delete Selected'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Error preparing deletion: $e');
    }
  }

  Future<void> _performDeletion() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (String studentName in selectedStudents) {
        final studentQuery = await _firestore
            .collection('students')
            .where('name', isEqualTo: studentName)
            .get();

        if (studentQuery.docs.isNotEmpty) {
          final studentDoc = studentQuery.docs.first;
          final studentId = studentDoc.id;
          final studentData = studentDoc.data();
          final studentEmail = studentData['email'];

          final userQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: studentEmail)
              .get();

          if (userQuery.docs.isNotEmpty) {
            final userDoc = userQuery.docs.first;
            final userId = userDoc.id;

            try {
              // Delete from Authentication
              try {
                final currentUser = _auth.currentUser;
                if (currentUser != null && currentUser.email == studentEmail) {
                  await currentUser.delete();
                } else {
                  await _auth.signOut();
                  try {
                    final userCredential = await _auth.signInWithEmailAndPassword(
                      email: studentEmail,
                      password: studentData['password'] ?? '',
                    );
                    await userCredential.user?.delete();
                  } catch (signInError) {
                    print('Could not sign in to delete user: $signInError');
                  }
                }
              } catch (authError) {
                print('Authentication deletion error: $authError');
              }

              // Delete from Firestore
              await _firestore.collection('students').doc(studentId).delete();
              await _firestore.collection('users').doc(userId).delete();

              // Delete related exam results
              final resultsQuery = await _firestore
                  .collection('examResults')
                  .where('studentId', isEqualTo: studentId)
                  .get();

              for (var resultDoc in resultsQuery.docs) {
                await resultDoc.reference.delete();
              }
            } catch (e) {
              print('Error deleting student $studentName: $e');
            }
          }
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        setState(() {
          selectedStudents.clear();
          isSelectionMode = false;
        });
        _showSuccessDialog('Selected students deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error deleting students: $e');
      }
    } finally {
      try {
        await _auth.signOut();
      } catch (signOutError) {
        print('Error during sign out: $signOutError');
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
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

  Widget _buildStudentCard(
    BuildContext context,
    String studentName,
    VoidCallback onTap,
  ) {
    final isSelected = selectedStudents.contains(studentName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          onLongPress: () {
            setState(() {
              isSelectionMode = true;
              selectedStudents.add(studentName);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedStudents.add(studentName);
                          } else {
                            selectedStudents.remove(studentName);
                          }
                          if (selectedStudents.isEmpty) {
                            isSelectionMode = false;
                          }
                        });
                      },
                      activeColor: AppColors.primaryColor,
                    ),
                  ),
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!isSelectionMode)
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedStudents = {studentName};
                      });
                      _deleteSelectedStudents();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = getFilteredStudents();
    
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
                            "Overview of College Students",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'View and manage student details',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            isSelectionMode = false;
                            selectedStudents.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),
              _buildClassFilter(),
              _buildStatisticsCard(),
              if (isSelectionMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white.withOpacity(0.1),
                  child: Row(
                    children: [
                      Text(
                        '${selectedStudents.length} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(
                          'Delete Selected',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: _deleteSelectedStudents,
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
                      ? const Center(child: CircularProgressIndicator())
                      : filteredStudents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off,
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
                              padding: const EdgeInsets.all(24),
                              itemCount: filteredStudents.length,
                              itemBuilder: (context, index) {
                                return _buildStudentCard(
                                  context,
                                  filteredStudents[index]['name'],
                                  () => _navigateToDetails(
                                    context,
                                    filteredStudents[index]['name'],
                                    true,
                                  ),
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
