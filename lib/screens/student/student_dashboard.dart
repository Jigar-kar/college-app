import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:bca_c/components/dashboard_skeleton.dart';
import 'package:bca_c/components/onbording.dart';
import 'package:bca_c/components/view_rankers.dart';
import 'package:bca_c/components/view_time_table.dart';
import 'package:bca_c/screens/student/about_us_screen.dart';
import 'package:bca_c/screens/student/attendance_screen.dart';
import 'package:bca_c/screens/student/exam_result_screen.dart';
import 'package:bca_c/screens/student/faculty_screen.dart';
import 'package:bca_c/screens/student/fee_screen.dart';
import 'package:bca_c/screens/student/leave.dart';
import 'package:bca_c/screens/student/notice.dart';
import 'package:bca_c/screens/student/student_exam_screen.dart';
import 'package:bca_c/screens/student/student_info_screen.dart';
import 'package:bca_c/screens/student/student_photo_screen.dart';
import 'package:bca_c/screens/student/student_time_table.dart';
import 'package:bca_c/screens/student/view_materials.dart';
import 'package:bca_c/services/auth_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:http/http.dart' as http;

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color warningOrange = Color(0xFFF57C00);
  static const Color successGreen = Color(0xFF388E3C);
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  String attendancePercentage = '0%';
  double attendanceValue = 0.0;
  String enroll = 'N/A';
  String subjectsCount = '0';
  String studentName = 'Student';
  String studentPhotoUrl = '';
  String roll = '0';
  String class11 = '';
  Map<String, dynamic>? class1;
  bool isLoading = true;

  Map<String, dynamic>? recentMarks;
  Map<String, dynamic>? recentFeePayment;
  Map<String, dynamic>? currentClass;

  final List<Widget> pages = [
    const FeeScreen(),
    const TimetablePage(),
    const NoticesScreen(),
    const RankersListScreen(),
    const StudentInfoScreen(),
  ];

  bool _showAllActions = false;

  List<String> imageUrls = [];

  List<Map<String, dynamic>> allActions = [];
  List<Map<String, dynamic>> filteredActions = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _fetchSliderImages() async {
    try {
      // GitHub API to get files in the Slider directory
      const repoOwner = 'satuababa-bca-1';
      const repoName = 'Statuababa-Bca';
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/contents/Slider');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> files = json.decode(response.body);
        
        setState(() {
          imageUrls = files
              .map((file) => 'https://raw.githubusercontent.com/$repoOwner/$repoName/main/Slider/${file['name']}')
              .toList();
                      print(class11);

        });
      } else {
        debugPrint('Failed to fetch slider images: ${response.statusCode}');
        setState(() {
          imageUrls = [
          ];
        });
      }
    } catch (e) {
      debugPrint('Error fetching slider images: $e');
      setState(() {
        imageUrls = [
        ];
      });
    }
  }

  int _current = 0;

  @override
  void initState() {
    super.initState();
    _initializeActions();
    _fetchDashboardData();
    _fetchSliderImages();

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _drawerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _drawerController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeActions() {
    allActions = [
      {
        'icon': Icons.assessment_outlined,
        'label': 'Exams',
        'page': StudentExamScreen(
          studentId: FirebaseAuth.instance.currentUser!.uid,
          studentClass: class11,
        ),
      },
      {
        'icon': Icons.info,
        'label': 'About Us',
        'page': const AboutUsScreen(),
      },
      {
        'icon': Icons.assignment,
        'label': 'Exam Result',
        'page': ExamResultScreen(
          studentId: FirebaseAuth.instance.currentUser!.uid,
        ),
      },
      {
        'icon': Icons.person,
        'label': 'Profile',
        'page': const StudentInfoScreen(),
      },
      {
        'icon': Icons.photo_library,
        'label': 'Photos',
        'page': const StudentPhotoScreen(),
      },
      {
        'icon': Icons.school,
        'label': 'Faculty',
        'page': const FacultyScreen(),
      },
      {
        'icon': Icons.book,
        'label': 'Materials',
        'page': const StudentPDFScreen(),
      },
      {
        'icon': Icons.payment,
        'label': 'Fees',
        'page': const FeeScreen(),
      },
      {
        'icon': Icons.schedule,
        'label': 'Timetable',
        'page': const StudentTimetablePage(),
      },
      {
        'icon': Icons.notifications,
        'label': 'Notices',
        'page': const NoticesScreen(),
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Leave',
        'page': const LeaveScreen(),
      },
      {
        'icon': Icons.star,
        'label': 'Rankers',
        'page': const RankersListScreen(),
      },
      {
        'icon': Icons.logout,
        'label': 'Sign Out',
        'page': const OnBoardingPage(),
        'isSignOut': true,
      },
    ];
    filteredActions = [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentClass() async {
    try {
      final now = DateTime.now();
      final weekdays = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ];
      final currentDay =
          weekdays[now.weekday % 7]; // Get current day as a string
      final currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final timetableSnapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .where('day', isEqualTo: currentDay)
          .where('class',isEqualTo: class1)
          .get();

      if (timetableSnapshot.docs.isNotEmpty) {
        for (var doc in timetableSnapshot.docs) {
          final startTime = doc['startTime']; // e.g., "09:00"
          final endTime = doc['endTime']; // e.g., "10:30"
          if (currentTime.compareTo(startTime) >= 0 &&
              currentTime.compareTo(endTime) <= 0) {
            setState(() {
              currentClass = doc.data();
            });
            break;
          }
        }
      } else {
        setState(() {
          currentClass = null; // No ongoing class
        });
      }
    } catch (e) {
      debugPrint('Error fetching current class: $e');
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      isLoading = true;
      print("Class11: ${class11.toString()}"); // Debug print
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
        subjectsCount =
            (studentData?['subjects'] as List?)?.length.toString() ?? '0';
        roll = studentData?['rollNo'];
        class11 = studentData?['class'];
      }

      // Fetch recent marks
      final marksSnapshot = await _db
          .collection('examResults')
          .where('studentId', isEqualTo: _auth.currentUser!.uid)
          .where('status', isEqualTo: 'Approved')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (marksSnapshot.docs.isNotEmpty) {
        recentMarks = marksSnapshot.docs.first.data();
        print(recentMarks);
        print(class11);
      }

      // Fetch recent fee payment
      final feeSnapshot = await _db
          .collection('payments')
          .where('studentId', isEqualTo: _auth.currentUser!.uid)
          .limit(1)
          .get();

      if (feeSnapshot.docs.isNotEmpty) {
        recentFeePayment = feeSnapshot.docs.first.data();
      }

      // Fetch current class from timetable
      final now = DateTime.now();
      final currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      final weekdays = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ];
      final currentDay = weekdays[now.weekday % 7];
      print("Current Day: $currentDay"); // Debug print

      final timetableSnapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .where('day', isEqualTo: currentDay)
          .where('class', isEqualTo: class11)
          .get();

      print("Timetable Query Results: ${timetableSnapshot.docs.length}"); // Debug print

      if (timetableSnapshot.docs.isNotEmpty) {
        for (var doc in timetableSnapshot.docs) {
          final classData = doc.data();
          print("Class Data Found: $classData"); // Debug print

          if (isTimeInRange(
              currentTime, classData['startTime'], classData['endTime'])) {
            setState(() {
              currentClass = classData;
              print("Setting Current Class: $currentClass"); // Debug print
            });
            break;
          }
        }
      } else {
        setState(() {
          currentClass = null;
          print("No classes found for today"); // Debug print
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching dashboard data: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isTimeInRange(String current, String start, String end) {
    final currentParts = current.split(':').map(int.parse).toList();
    final startParts = start.split(':').map(int.parse).toList();
    final endParts = end.split(':').map(int.parse).toList();

    final currentMinutes = currentParts[0] * 60 + currentParts[1];
    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  Future<Map<String, String?>> fetchRecentNotice() async {
    try {
      // Query Firestore to fetch the most recent notice
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notices')
          .orderBy('timestamp',
              descending: true) // Assumes 'timestamp' field is available
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final noticeData = querySnapshot.docs.first.data();
        return {
          'title': noticeData['title'] as String?,
          'description': noticeData['description'] as String?,
        };
      } else {
        return {'title': 'No recent notices available.', 'details': ''};
      }
    } catch (e) {
      return {'title': 'Error fetching notice', 'details': '$e'};
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
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut(context);
              },
              child: const Text(
                'Yes, Sign Out',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.primaryColor.withOpacity(0.3),
                ],
              ),
            ),
            child: isLoading
                ? const DashboardSkeleton()
                : RefreshIndicator(
                    color: AppColors.accentColor,
                    onRefresh: _fetchDashboardData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // Profile Card with new design
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientEnd,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gradientStart
                                        .withOpacity(0.3),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      ClipOval(
                                        child: studentPhotoUrl.isNotEmpty
                                            ? Image.network(
                                                studentPhotoUrl,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              studentName,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              enroll,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 16,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getCurrentDate(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Add this after the profile card container
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: AppColors.primaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: const InputDecoration(
                                        hintText: 'Search actions...',
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value.toLowerCase();
                                          if (_searchQuery.isEmpty) {
                                            filteredActions = [];
                                            _showAllActions = false;
                                          } else {
                                            filteredActions = allActions
                                                .where((action) => action['label']
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains(_searchQuery))
                                                .toList();
                                            _showAllActions = true;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          filteredActions = [];
                                          _showAllActions = false;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Image Slider
                            _buildImageSlider(),

                            const SizedBox(height: 10),

                            // Quick Actions Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.cardBg,
                                    AppColors.cardBg.withOpacity(0.95),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gradientStart
                                        .withOpacity(0.05),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AnimatedTextKit(
                                        animatedTexts: [
                                          TypewriterAnimatedText(
                                            'Quick Actions',
                                            textStyle: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                              letterSpacing: 0.5,
                                            ),
                                            speed: const Duration(
                                                milliseconds: 100),
                                          ),
                                        ],
                                        totalRepeatCount: 1,
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          onTap: () {
                                            setState(() {
                                              _showAllActions =
                                                  !_showAllActions;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.gradientStart
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _showAllActions
                                                      ? 'Show Less'
                                                      : 'Show More',
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.gradientStart,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                AnimatedRotation(
                                                  turns:
                                                      _showAllActions ? 0.5 : 0,
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  child: const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    color:
                                                        AppColors.gradientStart,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  AnimationLimiter(
                                    child: GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: kIsWeb ? 6 : 3,
                                      mainAxisSpacing: 15,
                                      crossAxisSpacing: 15,
                                      childAspectRatio: 0.75,
                                      padding: const EdgeInsets.all(8),
                                      children: AnimationConfiguration
                                          .toStaggeredList(
                                        duration:
                                            const Duration(milliseconds: 375),
                                        childAnimationBuilder: (widget) =>
                                            SlideAnimation(
                                          verticalOffset: 50.0,
                                          child: FadeInAnimation(
                                            child: widget,
                                          ),
                                        ),
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const AttendanceScreen(),
                                                  ),
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.cardBg,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: AppColors
                                                        .gradientStart
                                                        .withOpacity(0.1),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .gradientStart
                                                          .withOpacity(0.1),
                                                      spreadRadius: 0,
                                                      blurRadius: 10,
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Flexible(
                                                      child: SizedBox(
                                                        width: 50,
                                                        height: 50,
                                                        child: Stack(
                                                          children: [
                                                            Center(
                                                              child:
                                                                  TweenAnimationBuilder(
                                                                duration:
                                                                    const Duration(
                                                                        seconds:
                                                                            2),
                                                                tween: Tween<
                                                                        double>(
                                                                    begin: 0,
                                                                    end:
                                                                        attendanceValue),
                                                                builder: (_,
                                                                    double value,
                                                                    __) {
                                                                  return CircularProgressIndicator(
                                                                    value: value,
                                                                    backgroundColor: AppColors
                                                                        .gradientStart
                                                                        .withOpacity(
                                                                            0.2),
                                                                    valueColor:
                                                                        AlwaysStoppedAnimation<
                                                                            Color>(
                                                                      value < 0.75
                                                                          ? Colors
                                                                              .red
                                                                          : value <
                                                                                  0.85
                                                                              ? Colors.orange
                                                                              : AppColors.accentColor,
                                                                  ),
                                                                    strokeWidth:
                                                                        5,
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            Center(
                                                              child: Text(
                                                                '${(attendanceValue * 100).toStringAsFixed(0)}%',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                  color: attendanceValue <
                                                                          0.70
                                                                      ? Colors.red
                                                                      : attendanceValue <
                                                                              0.80
                                                                          ? Colors
                                                                              .orange
                                                                          : AppColors
                                                                              .accentColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    const Flexible(
                                                      child: Text(
                                                        'Attendance',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          ...(_showAllActions
                                              ? _buildAllQuickActions()
                                              : _buildInitialQuickActions()),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!_showAllActions) ...[
                                    const SizedBox(height: 15),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.gradientStart
                                                  .withOpacity(0.15),
                                              AppColors.gradientEnd
                                                  .withOpacity(0.15),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.gradientStart
                                                .withOpacity(0.1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${10 - 2} more actions available',
                                              style: TextStyle(
                                                color: AppColors.gradientStart
                                                    .withOpacity(0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Icon(
                                              Icons.arrow_forward,
                                              size: 16,
                                              color: AppColors.gradientStart
                                                  .withOpacity(0.8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Replace the existing Current Status container with this
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Status',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  CarouselSlider(
                                    options: CarouselOptions(
                                      height: 150,
                                      aspectRatio: 16 / 9,
                                      viewportFraction: 0.9,
                                      initialPage: 0,
                                      enableInfiniteScroll: true,
                                      reverse: false,
                                      autoPlay: true,
                                      autoPlayInterval: const Duration(seconds: 3),
                                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                                      autoPlayCurve: Curves.fastOutSlowIn,
                                      enlargeCenterPage: true,
                                      scrollDirection: Axis.vertical,
                                    ),
                                    items: _buildStatusCards(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Notices Section with new design
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recent Notices',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                            height: 200,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [
                                                Color.fromARGB(118, 255, 0, 0),
                                                Color.fromARGB(118, 255, 0, 0),
                                              ]),
                                        borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: const Color.fromARGB(
                                                      149, 255, 0, 64),
                                                  style: BorderStyle.solid),
                                            ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(15.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                              'Latest Notice',
                                              style: TextStyle(
                                                      fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                            SizedBox(height: 10),
                                                  Text(
                                              'Check the notice board for latest updates.',
                                              style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    if (imageUrls.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'No images available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        aspectRatio: 16 / 9,
        viewportFraction: 0.9,
        initialPage: 0,
        enableInfiniteScroll: true,
        reverse: false,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: true,
        scrollDirection: Axis.horizontal,
        onPageChanged: (index, reason) {
          setState(() {
            _current = index;
          });
        },
      ),
      items: imageUrls.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint('Error loading image: $url');
                  },
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Widget page, {bool isSignOut = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isSignOut) {
            _showSignOutDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gradientStart.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.gradientStart,
                      AppColors.gradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 40),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return '';
      }

      return '${date.day} ${_getMonth(date.month)} ${date.year}';
    } catch (e) {
      return '';
    }
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildStatusCard(
      String title, String content, IconData icon, Color color,
      {bool isWide = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInitialQuickActions() {
    if (_searchQuery.isNotEmpty) {
      return filteredActions
          .map((action) => _buildQuickAction(
                action['icon'] as IconData,
                action['label'] as String,
                action['page'] as Widget,
                isSignOut: action['isSignOut'] ?? false,
              ))
          .toList();
    }
    return allActions
        .take(5)
        .map((action) => _buildQuickAction(
              action['icon'] as IconData,
              action['label'] as String,
              action['page'] as Widget,
              isSignOut: action['isSignOut'] ?? false,
            ))
        .toList();
  }

  List<Widget> _buildAllQuickActions() {
    if (_searchQuery.isNotEmpty) {
      return filteredActions
          .map((action) => _buildQuickAction(
                action['icon'] as IconData,
                action['label'] as String,
                action['page'] as Widget,
                isSignOut: action['isSignOut'] ?? false,
              ))
          .toList();
    }
    return allActions
        .map((action) => _buildQuickAction(
              action['icon'] as IconData,
              action['label'] as String,
              action['page'] as Widget,
              isSignOut: action['isSignOut'] ?? false,
            ))
        .toList();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  List<Widget> _buildStatusCards() {
    return [
      // Current Class Card
      _buildStatusCard(
        'Current Class',
        currentClass != null
            ? "${currentClass!['subject']}\n${currentClass!['startTime']} - ${currentClass!['endTime']}"
            : 'No ongoing class',
        Icons.class_,
        AppColors.gradientStart,
        isWide: true,
      ),
      // Recent Exam Card
      _buildStatusCard(
        'Recent Exam',
        recentMarks != null
            ? "Subject: ${recentMarks!['subject']}\nMarks: ${recentMarks!['marksObtained']}"
            : 'No recent exam results',
        Icons.assignment_turned_in,
        AppColors.successGreen,
        isWide: true,
      ),
      // Recent Fee Payment Card
      _buildStatusCard(
        'Recent Fee Payment',
        recentFeePayment != null
            ? '₹${recentFeePayment!['amount']}\n${_formatDate(recentFeePayment!['timestamp'])}'
            : 'No recent payments',
        Icons.payment,
        const Color(0xFF00B894),
        isWide: true,
      ),
    ];
  }
}
