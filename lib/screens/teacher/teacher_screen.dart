// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, unused_element
import 'package:bca_c/components/onbording.dart';
import 'package:bca_c/screens/admin/student_overveiw.dart';
import 'package:bca_c/screens/shared/notices_list_screen.dart';
import 'package:bca_c/screens/teacher/appruve_leave.dart';
import 'package:bca_c/screens/teacher/attendance_management.dart';
import 'package:bca_c/screens/teacher/exam_list_screen.dart';
import 'package:bca_c/screens/teacher/exam_results_download_screen.dart';
import 'package:bca_c/screens/teacher/materials.dart';
import 'package:bca_c/screens/teacher/notices_screen.dart';
import 'package:bca_c/screens/teacher/take_leave.dart';
import 'package:bca_c/screens/teacher/teacher_chat_list.dart';
import 'package:bca_c/screens/teacher/teacher_profile.dart';
import 'package:bca_c/screens/teacher/teacher_time_table.dart';
import 'package:bca_c/services/auth_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF0288D1);
  static const Color purple = Color(0xFF6A1B9A);
  static const Color pink = Color(0xFFC2185B);
  static const Color teal = Color(0xFF00796B);
}

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen>
    with SingleTickerProviderStateMixin {
  String? _teacherPhotoUrl;
  String _teacherName = '';
  String _teacherId = '';
  List<String> _teachersub = [];
  String _teacherclass = '';

  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;
  int _current = 0;

  bool _showAllActions = false;
  int _activeStudentsCount = 0;
  int _todayClassesCount = 0;
  int _pendingApprovalsCount = 0;

  List<Map<String, dynamic>> notices = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherPhoto();
    _fetchDashboardStats();
    _fetchNotices();

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _drawerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _drawerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeacherPhoto() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(currentUser.uid)
            .get();

        if (teacherDoc.exists) {
          var data = teacherDoc.data() as Map<String, dynamic>;
          setState(() {
            _teacherPhotoUrl = data['photoUrl'];
            _teacherName = data['name'] ?? 'Teacher';
            _teacherId = data['teacherId'] ?? '';

            // Correctly handle subject as a list
            if (data['subject'] is List) {
              _teachersub = List<String>.from(data['subject']);
            } else if (data['subject'] is String) {
              _teachersub = [data['subject']];
            } else {
              _teachersub = [];
            }

            _teacherclass = data['class'] ?? 'Not Fetch';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching teacher photo: $e');
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final String cla = _teacherclass;

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('status', isEqualTo: 'active')
          .get();

      final leaveRequestsSnapshot = await FirebaseFirestore.instance
          .collection('leaves')
          .where('status', isEqualTo: 'pending')
          .get();

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
      final currentDay = weekdays[now.weekday % 7];
      final timetableSnapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .where('day', isEqualTo: currentDay)
          .where('subject', isEqualTo: _teachersub)
          .where('class')
          .get();

      setState(() {
        print('${now.day} Day');
        print('$_teacherclass class');
        _activeStudentsCount = studentsSnapshot.docs.length;
        _pendingApprovalsCount = leaveRequestsSnapshot.docs.length;
        _todayClassesCount = timetableSnapshot.docs.length;
      });
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
    }
  }

  Future<void> _fetchNotices() async {
    try {
      final QuerySnapshot noticesSnapshot = await FirebaseFirestore.instance
          .collection('admin_notices')
          .orderBy('postedDate', descending: true)
          .get();

      setState(() {
        notices = noticesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'title': data['title'] ?? 'No Title',
            'message': data['content'] ?? 'No Content',
            'priority': data['priority'] ?? 'low',
            'postedDate': data['postedDate'] as Timestamp,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching notices: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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

  Widget _buildQuickAction(IconData icon, String label, Widget page,
      {bool isSignOut = false}) {
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
          height: 100,
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
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon,
      Widget destination, Color color,
      {bool isSignOut = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (isSignOut) {
              await AuthService().signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OnBoardingPage()),
                  (route) => false,
                );
              }
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            child: RefreshIndicator(
              color: AppColors.accentColor,
              onRefresh: () async {
                await _fetchTeacherPhoto();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Profile Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
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
                              color: AppColors.gradientStart.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: 'teacherPhoto',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: _teacherPhotoUrl != null
                                          ? Image.network(
                                              _teacherPhotoUrl!,
                                              height: 80,
                                              width: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.account_circle,
                                                  size: 80,
                                                  color: Colors.white,
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.account_circle,
                                              size: 80,
                                              color: Colors.white,
                                            ),
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
                                        _teacherName,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Subject : ${_teachersub.join(', ')}',
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                                  255, 144, 214, 216)
                                              .withOpacity(0.9),
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'class : $_teacherclass',
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                                  255, 110, 212, 153)
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Announcements Carousel
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 140.0,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                          autoPlayInterval: const Duration(seconds: 5),
                          autoPlayAnimationDuration:
                              const Duration(milliseconds: 800),
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enableInfiniteScroll: true,
                          scrollDirection: Axis.horizontal,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _current = index;
                            });
                          },
                        ),
                        items: notices.isEmpty
                            ? [
                                Container(
                                  margin: const EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No notices available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ]
                            : notices.map((notice) {
                                Color priorityColor;
                                switch (notice['priority']) {
                                  case 'high':
                                    priorityColor = Colors.red;
                                    break;
                                  case 'medium':
                                    priorityColor = Colors.orange;
                                    break;
                                  default:
                                    priorityColor = Colors.green;
                                }

                                return Container(
                                  margin: const EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
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
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: priorityColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.campaign,
                                                color: priorityColor,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                notice['title'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: Text(
                                            notice['message'],
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: Text(
                                            notice['postedDate'].toString(),
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: notices.asMap().entries.map((entry) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor.withOpacity(
                                  _current == entry.key ? 0.9 : 0.2),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Status Cards Section
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
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 120,
                                    child: _buildStatusCard(
                                      'Active Students',
                                      _activeStudentsCount.toString(),
                                      Icons.people,
                                      AppColors.gradientStart,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 120,
                                    child: _buildStatusCard(
                                      'Today\'s Classes',
                                      _todayClassesCount.toString(),
                                      Icons.class_,
                                      AppColors.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 120,
                              child: _buildStatusCard(
                                'Pending Approvals',
                                _pendingApprovalsCount.toString(),
                                Icons.pending_actions,
                                const Color.fromARGB(255, 208, 78, 217),
                                isWide: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Quick Actions Section with Show More/Less
                      Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showAllActions = !_showAllActions;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    backgroundColor:
                                        AppColors.primaryColor.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _showAllActions
                                            ? 'Show Less'
                                            : 'Show More',
                                        style: const TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _showAllActions
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: AppColors.primaryColor,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: kIsWeb ? 9 : 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1,
                              children: _showAllActions
                                  ? _buildAllQuickActions()
                                  : _buildInitialQuickActions(),
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

  Widget _buildStatusCard(
      String title, String content, IconData icon, Color color,
      {bool isWide = false}) {
    return Container(
      width: isWide ? double.infinity : null,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            content,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInitialQuickActions() {
    return [
      _buildQuickAction(
          Icons.check_circle, 'Attendance', const AttendanceManagement()),
      _buildQuickAction(Icons.assignment_turned_in, 'Leave Approval',
          const TeacherLeaveApprovalScreen()),
      _buildQuickAction(
        Icons.assignment_add,
        'Exam List',
        ExamListScreen(
            teacherId: FirebaseAuth.instance.currentUser!.uid,
            subject: _teachersub,
            className: _teacherclass),
      ),
      _buildQuickAction(
          Icons.people, 'View Students', const StudentOverviewScreen()),
      _buildQuickAction(Icons.people, 'Take Leave', const LeaveScreen()),
      _buildQuickAction(Icons.notifications, 'Notices', const NoticesListScreen()),
      
    ];
  }

  List<Widget> _buildAllQuickActions() {
    return [
      _buildQuickAction(
          Icons.check_circle, 'Attendance', const AttendanceManagement()),
      _buildQuickAction(Icons.assignment_turned_in, 'Leave Approval',
          const TeacherLeaveApprovalScreen()),
      _buildQuickAction(
        Icons.assignment_add,
        'Exam List',
        ExamListScreen(
            teacherId: FirebaseAuth.instance.currentUser!.uid,
            subject: _teachersub,
            className: _teacherclass),
      ),
      _buildQuickAction(
          Icons.people, 'View Students', const StudentOverviewScreen()),
      _buildQuickAction(Icons.people, 'Take Leave', const LeaveScreen()),
      _buildQuickAction(Icons.notifications, 'Notices', const NoticesListScreen()),
      _buildQuickAction(
          Icons.calendar_today, 'Time Table', const TeacherTimetablePage()),
      _buildQuickAction(
        Icons.download_for_offline_rounded,
        'Exam Result Download',
        ExamResultsDownloadScreen(
            teacherId: FirebaseAuth.instance.currentUser!.uid),
      ),
      _buildQuickAction(
        Icons.person,
        'Profile',
        TeacherProfilePage(teacherId: FirebaseAuth.instance.currentUser!.uid),
      ),
      _buildQuickAction(Icons.book, 'Materials', const TeacherUploadScreen()),
      _buildQuickAction(
          Icons.notifications, 'Notices From Admin', const NoticesScreen()),
      _buildQuickAction(
          Icons.chat, 'Chat', TeacherChatListScreen(teacherId: _teacherId)),
      _buildQuickAction(
        Icons.logout,
        'Sign Out',
        const SizedBox(),
        isSignOut: true,
      ),
    ];
  }
}
