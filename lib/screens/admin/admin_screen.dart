import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:bca_c/components/onbording.dart';
import 'package:bca_c/screens/admin/accept_student_request.dart';
import 'package:bca_c/screens/admin/add_fees_screen.dart';
import 'package:bca_c/screens/admin/add_rankers.dart';
import 'package:bca_c/screens/admin/add_subject_screen.dart';
import 'package:bca_c/screens/admin/add_teacher.dart';
import 'package:bca_c/screens/admin/add_time_table.dart';
import 'package:bca_c/screens/admin/approve_teacher_leave.dart';
import 'package:bca_c/screens/admin/course_management.dart';
import 'package:bca_c/screens/admin/create_exam_screen.dart';
import 'package:bca_c/screens/admin/create_notice_screen.dart';
import 'package:bca_c/screens/admin/exam_result_approval_screen.dart';
import 'package:bca_c/screens/admin/fee_dashboard.dart';
import 'package:bca_c/screens/admin/manage_admissions_screen.dart';
import 'package:bca_c/screens/admin/overview_screen.dart';
import 'package:bca_c/screens/admin/post_notice.dart';
import 'package:bca_c/screens/admin/slider_image.dart';
import 'package:bca_c/screens/admin/student_overveiw.dart';
import 'package:bca_c/screens/admin/upload_materials.dart';
import 'package:bca_c/screens/admin/upload_photo_screen.dart';
import 'package:bca_c/screens/admin/veiw_photo.dart';
import 'package:bca_c/screens/shared/notices_list_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color errorred = Color.fromARGB(255, 255, 0, 0);
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _showAllActions = false;
  final int _selectedIndex = 0;
  bool isLoading = true;
  int _currentIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, int> _statistics = {
    'Pending Student Requests': 0,
    'Total Teachers': 0,
    'Active Courses': 0,
    'Pending Leaves': 0,
    'Upcoming Exams': 0,
    'Completed Exams': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    try {
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('status', isEqualTo: 'pending')
          .get();
      final teachersSnapshot = await _firestore
          .collection('teachers')
          .where('status', isEqualTo: 'active')
          .get();
      final coursesSnapshot = await _firestore.collection('courses').get();
      final leavesSnapshot = await _firestore
          .collection('teacher_leaves')
          .where('status', isEqualTo: 'Pending')
          .get();
      final upcomingExamsSnapshot = await _firestore
          .collection('exams')
          .where('status', isEqualTo: 'Pending')
          .get();
      final completedExamsSnapshot = await _firestore
          .collection('exams')
          .where('status', isEqualTo: 'completed')
          .get();
      final fullycompletedExamsSnapshot = await _firestore
          .collection('exams')
          .where('status', isEqualTo: 'Graded')
          .get(); // Graded
      if (mounted) {
        setState(() {
          _statistics = {
            'Students Request': studentsSnapshot.docs.length,
            'Total Teachers': teachersSnapshot.docs.length,
            'Active Courses': coursesSnapshot.docs.length,
            'Pending Leaves': leavesSnapshot.docs.length,
            'Upcoming Exams': upcomingExamsSnapshot.docs.length,
            'Completed Exams': completedExamsSnapshot.docs.length,
            'Fully Completed..': fullycompletedExamsSnapshot.docs.length,
          };
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching statistics: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshStatistics() async {
    setState(() {
      isLoading = true;
    });
    await _fetchStatistics();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshStatistics,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: AnimationLimiter(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 600),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            _buildProfileSection(),
                            const SizedBox(height: 25),
                            _buildStatisticsSection(),
                            const SizedBox(height: 25),
                            _buildQuickActionsSection()
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

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gradientStart.withOpacity(0.9),
            AppColors.gradientEnd.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/logo1.png'),
                  radius: 40,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Welcome, Admin!',
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          speed: const Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your platform efficiently',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
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
              vertical: 8,
              horizontal: 16,
            ),
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
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshStatistics,
                color: AppColors.gradientStart,
              ),
            ],
          ),
          const SizedBox(height: 20),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 200,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      aspectRatio: 16 / 9,
                      viewportFraction: 0.8,
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
                          _currentIndex = index;
                        });
                      },
                    ),
                    items: _statistics.entries.map((entry) {
                      final index = _statistics.entries.toList().indexOf(entry);
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentIndex == index ? 1.0 : 0.5,
                        child: AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildStatCard(entry.key, entry.value),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  IconData _getIconForStat(String title) {
    switch (title) {
      case 'Students Request':
        return Icons.person_add;
      case 'Total Teachers':
        return Icons.school;
      case 'Active Courses':
        return Icons.book;
      case 'Pending Leaves':
        return Icons.event_busy;
      case 'Upcoming Exams':
        return Icons.event;
      case 'Completed Exams':
        return Icons.check_circle;
      case 'Fully Completed..':
        return Icons.done_all;
      default:
        return Icons.analytics;
    }
  }

  List<Color> _getGradientForStat(String title) {
    switch (title) {
      case 'Students Request':
        return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
      case 'Total Teachers':
        return [const Color(0xFF2196F3), const Color(0xFF1565C0)];
      case 'Active Courses':
        return [const Color(0xFFF44336), const Color(0xFFC62828)];
      case 'Pending Leaves':
        return [const Color(0xFFFF9800), const Color(0xFFF57C00)];
      case 'Upcoming Exams':
        return [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)];
      case 'Completed Exams':
        return [const Color(0xFF00BCD4), const Color(0xFF0097A7)];
      case 'Fully Completed..':
        return [const Color(0xFF3F51B5), const Color(0xFF283593)];
      default:
        return [AppColors.gradientStart, AppColors.gradientEnd];
    }
  }

  Widget _buildStatCard(String title, int value) {
    final colors = _getGradientForStat(title);
    final icon = _getIconForStat(title);
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[0].withOpacity(0.9),
            colors[1].withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllActions = !_showAllActions;
                  });
                },
                child: Row(
                  children: [
                    Text(
                      _showAllActions ? 'Show Less' : 'Show More',
                      style: const TextStyle(
                        color: AppColors.gradientStart,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _showAllActions
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.gradientStart,
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
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 9 : 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.85,
            children: [
              ..._showAllActions
                  ? _buildAllAdminActions()
                  : _buildInitialAdminActions(),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInitialAdminActions() {
    return [
      _buildQuickAction(Icons.book, 'Manage Cources', const CourseManagement()),
      _buildQuickAction(Icons.person_add, 'Add Staff', const AddTeacher()),
      _buildQuickAction(
          Icons.attach_money, 'Manage Fees', const FeeDashboard()),
      _buildQuickAction(Icons.add, 'Add Subject', const AddSubjectScreen()),
      _buildQuickAction(Icons.list_rounded, 'Staff', const OverviewScreen()),
      _buildQuickAction(
          Icons.school, 'Students', const StudentOverviewScreen()),
    ];
  }

  List<Widget> _buildAllAdminActions() {
    return [
      ..._buildInitialAdminActions(),
      _buildQuickAction(
          Icons.school, 'Student Requests', const AcceptStudentRequestPage()),
      _buildQuickAction(
          Icons.more_time, 'Add TimeTable', const AddTimetablePage()),
      _buildQuickAction(
          Icons.photo_library, 'Add Photo', const UploadPhotoScreen()),
      _buildQuickAction(Icons.star, 'Add Rankers', const AdminRankerScreen()),
      _buildQuickAction(
          Icons.photo_album, 'Manage Photos', const ManagePhotosScreen()),
      _buildQuickAction(
          Icons.note_add, 'Add Notice', const AdminNoticeScreen()),
      _buildQuickAction(Icons.check, 'Approve Leave', const AdminLeaveScreen()),
      _buildQuickAction(
          Icons.upload, 'Upload Materials', const UploadMaterialScreen()),
      _buildQuickAction(
          Icons.person_add, 'Admissions', const ManageAdmissionsScreen()),
      _buildQuickAction(Icons.notification_add_outlined, 'Teacher Notice',
          const CreateNoticeScreen()),
      _buildQuickAction(
          Icons.notifications, 'Notice List', const NoticesListScreen()),
      _buildQuickAction(
          Icons.add_to_photos_rounded,
          'Add Exams',
          const CreateExamScreen(
            adminId: '1',
          )),
          _buildQuickAction(
          Icons.monetization_on_outlined,
          'Add Fees',
          const AddFeesScreen(
          )),
      _buildQuickAction(
          Icons.receipt, 'Exam Result', const ExamResultApprovalScreen()),
      _buildQuickAction(
          Icons.photo, 'Manage Slider', const AdminUploadPhotoScreen()),
      _buildQuickAction(Icons.logout, 'Sing Out', const SizedBox(),
          isSignOut: true),
    ];
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OnBoardingPage()),
                );
              },
              child: const Text('Yes, Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
