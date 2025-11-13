import 'package:bca_c/components/onbording.dart';
import 'package:bca_c/components/view_rankers.dart';
import 'package:bca_c/components/view_time_table.dart';
import 'package:bca_c/screens/student/leave.dart';
import 'package:bca_c/screens/student/notice.dart';
import 'package:bca_c/screens/student/student_photo_screen.dart';
import 'package:bca_c/screens/student/view_materials.dart';
import 'package:bca_c/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'about_us_screen.dart';
import 'attendance_screen.dart';
import 'fee_screen.dart';
import 'marks_screen.dart';
import 'student_info_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String attendancePercentage = '0%';
  double attendanceValue = 0.0;
  String enroll = 'N/A';
  String subjectsCount = '0';
  String studentName = 'Student';
  String studentPhotoUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final attendanceSnapshot = await _db
          .collection('attendance')
          .where('studentId', isEqualTo: _auth.currentUser!.uid)
          .get();

      final totalClasses = attendanceSnapshot.docs.length;
      final attendedClasses = attendanceSnapshot.docs
          .where((doc) => doc['status'] == 'present')
          .length;

      if (totalClasses > 0) {
        final attendance = (attendedClasses / totalClasses) * 100;
        attendancePercentage = '${attendance.toStringAsFixed(2)}%';
        attendanceValue = attendedClasses / totalClasses;
      }

      final studentSnapshot =
          await _db.collection('students').doc(_auth.currentUser!.uid).get();

      if (studentSnapshot.exists) {
        final studentData = studentSnapshot.data();
        studentName = studentData?['name'] ?? 'Unknown';
        enroll = studentData?['enrollmentNo'] ?? 'N/A';
        studentPhotoUrl = studentData?['photoUrl'] ?? '';
        subjectsCount = (studentData?['subjects'] as List?)?.length.toString() ?? '0';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching dashboard data: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnBoardingPage()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut(context);
              },
              child: const Text('Yes, Sign Out'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
    bool isSignOut = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isSignOut) {
          _showSignOutDialog(context);
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return page;
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );
        }
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6F86D6), Color(0xFF48C6EF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: studentPhotoUrl.isNotEmpty
                              ? NetworkImage(studentPhotoUrl)
                              : const AssetImage('assets/logo.png') as ImageProvider,
                          radius: 45,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $studentName!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Enrollment: $enroll\nSubjects: $subjectsCount',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: attendanceValue),
                          duration: const Duration(seconds: 3),
                          builder: (_, double value, __) {
                            return Column(
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  backgroundColor: const Color.fromARGB(97, 248, 227, 227),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    value < 0.8 ? Colors.red : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${(value * 100).toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildFeatureCard(
                          title: 'Profile',
                          icon: Icons.person,
                          color: Colors.deepPurple,
                          page: const StudentInfoScreen(),
                        ),
                        _buildFeatureCard(
                          title: 'Marks',
                          icon: Icons.grade,
                          color: Colors.indigo,
                          page: MarksScreen(rollNo: enroll),
                        ),
                        _buildFeatureCard(
                          title: 'Attendance',
                          icon: Icons.calendar_today,
                          color: Colors.green,
                          page: const AttendanceScreen(),
                        ),
                        _buildFeatureCard(
                          title: 'Fees',
                          icon: Icons.attach_money,
                          color: Colors.blue,
                          page: const FeeScreen(),
                        ),
                        _buildFeatureCard(
                          title: 'Time Table',
                          icon: Icons.view_timeline_outlined,
                          color: Colors.blue,
                          page: const TimetablePage(),
                        ),
                        _buildFeatureCard(
                          title: 'Rankers',
                          icon: Icons.view_timeline_outlined,
                          color: Colors.blue,
                          page: const RankersListScreen(),
                        ),
                        // _buildFeatureCard(
                        //   title: 'Faculty',
                        //   icon: Icons.school,
                        //   color: Colors.cyan,
                        //   page: const FacultyScreen(),
                        // ),
                        _buildFeatureCard(
                          title: 'Photos',
                          icon: Icons.photo_album,
                          color: Colors.orange,
                          page: const StudentPhotoScreen(),
                        ),
                        _buildFeatureCard(
                          title: 'Leave',
                          icon: Icons.leave_bags_at_home,
                          color: Colors.teal,
                          page: const LeaveScreen(),
                        ),
                        _buildFeatureCard(
                          title: 'About Us',
                          icon: Icons.info,
                          color: Colors.pinkAccent,
                          page: const AboutUsScreen(),
                        ),
                        
                        _buildFeatureCard(
                          title: 'Notice',
                          icon: Icons.newspaper,
                          color: const Color.fromARGB(255, 76, 64, 251),
                          page: const NoticesScreen(),
                        ),
                        _buildFeatureCard(
                          title: 'Study Materials',
                          icon: Icons.book,
                          color: const Color.fromARGB(255, 193, 29, 29),
                          page: const StudentPDFScreen(),
                        ),
                        _buildFeatureCard(
                          title: 'Sign Out',
                          icon: Icons.logout,
                          color: Colors.red,
                          page: const SizedBox(),
                          isSignOut: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
