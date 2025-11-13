import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color upcomingColor = Color(0xFF2196F3);
  static const Color runningColor = Color(0xFFFF9800);
  static const Color completedColor = Color(0xFF4CAF50);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
}

class StudentExamScreen extends StatefulWidget {
  final String studentId;
  final String studentClass;

  const StudentExamScreen({
    super.key,
    required this.studentId,
    required this.studentClass,
  });

  @override
  State<StudentExamScreen> createState() => _StudentExamScreenState();
}

class _StudentExamScreenState extends State<StudentExamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];
  String? _studentClass;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);

    try {
      // First fetch student's class from students collection
      final studentDoc = await _db.collection('students').doc(widget.studentId).get();
      
      if (!studentDoc.exists) {
        throw 'Student data not found';
      }

      final studentData = studentDoc.data()!;
      final studentClass = studentData['class'] as String?;

      if (studentClass == null) {
        throw 'Student class information not found';
      }

      print('Loading exams for class: $studentClass'); // Debug log

      // Fetch exams for the student's class
      final examSnapshot = await _db
          .collection('exams')
          .where('className', isEqualTo: studentClass)
          .orderBy('examDate', descending: true)
          .get();

      print('Raw exam data:'); // Debug log
      for (var doc in examSnapshot.docs) {
        print('Exam: ${doc.data()}');
      }

      print('Found ${examSnapshot.docs.length} exams'); // Debug log

      // Get exam results
      final resultSnapshot = await _db
          .collection('examResults')
          .where('studentId', isEqualTo: widget.studentId)
          .get();

      final resultMap = {
        for (var doc in resultSnapshot.docs)
          doc.data()['examId'] as String: doc.data()
      };

      final now = DateTime.now();
      final exams = examSnapshot.docs.map((doc) {
        final data = doc.data();
        final examDate = (data['examDate'] as Timestamp).toDate();
        final endDateTime = (data['endDateTime'] as Timestamp).toDate();
        final result = resultMap[doc.id];
        final storedStatus = data['status'] as String?;

        // Determine exam status based on stored status or calculate it
        String status;
        if (storedStatus?.toLowerCase() == 'graded' || result != null) {
          status = 'completed';
        } else if (now.isAfter(examDate) && now.isBefore(endDateTime)) {
          status = 'running';
        } else if (now.isBefore(examDate)) {
          status = 'upcoming';
        } else if (now.isAfter(endDateTime)) {
          status = 'completed';
        } else {
          status = 'upcoming';
        }

        return {
          'id': doc.id,
          'examName': data['examName'] ?? 'Untitled Exam',
          'subject': data['subject'] ?? 'No Subject',
          'examDate': examDate,
          'endDateTime': endDateTime,
          'startTime': data['startTime'] ?? 'Not set',
          'endTime': data['endTime'] ?? 'Not set',
          'totalMarks': data['totalMarks'] ?? 0,
          'className': data['className'],
          'status': status.toLowerCase(),
          'result': result,
          'createdAt': data['createdAt'] as Timestamp?,
          'createdBy': data['createdBy'],
        };
      }).toList();

      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading exams: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredExams(String status) {
    return _exams.where((exam) => exam['status'].toString().toLowerCase() == status.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.transparent,
        title: const Row(
          children: [
           
            SizedBox(width: 12),
            Text(
              'Examination Portal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.gradientStart,
                AppColors.gradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              onPressed: _loadExams,
            tooltip: 'Refresh Exams',
          ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 3,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.upcoming),
                  text: 'UPCOMING',
                ),
                Tab(
                  icon: Icon(Icons.play_circle_outline),
                  text: 'RUNNING',
                ),
                Tab(
                  icon: Icon(Icons.check_circle_outline),
                  text: 'COMPLETED',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          : Column(
              children: [
                _buildStatisticsCard(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExamList('upcoming'),
                      _buildExamList('running'),
                      _buildExamList('completed'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Color _getScoreColor(dynamic obtainedMarks, dynamic totalMarks) {
    try {
      final obtained = num.parse(obtainedMarks.toString());
      final total = num.parse(totalMarks.toString());
      
      if (total == 0) return Colors.grey;
      
      final percentage = (obtained / total) * 100;
      
      if (percentage >= 75) return Colors.green;
      if (percentage >= 50) return Colors.orange;
      return Colors.red;
    } catch (e) {
      print('Error calculating score color: $e');
      return Colors.grey;
    }
  }

  Widget _buildExamList(String status) {
    final exams = _getFilteredExams(status);

    if (exams.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _buildStatusIcon(status),
                size: 80,
                color: _getStatusColor(status),
              ),
              const SizedBox(height: 16),
              Text(
                'No ${status.toUpperCase()} Exams',
                style: const TextStyle(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for updates',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: exams.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final exam = exams[index];
        final examDate = exam['examDate'] as DateTime;
        final endDateTime = exam['endDateTime'] as DateTime;
        final result = exam['result'];
        final examStatus = exam['status'].toString().toLowerCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: _getStatusColor(examStatus),
                    width: 6,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exam['examName'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(examStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            examStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(examStatus),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exam['subject'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(examDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${exam['startTime']} - ${exam['endTime']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (result != null) ...[                      
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.dividerColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Result Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildResultMetric(
                                    'Total Marks',
                                    exam['totalMarks'].toString(),
                                    Icons.assignment_outlined,
                                  ),
                                  const SizedBox(width: 10,),
                                  _buildResultMetric(
                                    'Marks Obtained',
                                    result['marksObtained'].toString(),
                                    Icons.check_circle_outline,
                                  ),
                                  const SizedBox(width: 10,),
                                  _buildResultMetric(
                                    'Percentage',
                                    '${((result['marksObtained'] / exam['totalMarks']) * 100).toStringAsFixed(1)}%',
                                    Icons.percent_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              const Divider(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Score',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${result["marksObtained"]}/${exam["totalMarks"]}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${((result["marksObtained"] / exam["totalMarks"]) * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                      const SizedBox(height: 8),
                      const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.dividerColor),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.score,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Score: ${result["marksObtained"]}/${exam["totalMarks"]}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                    ],
                  ],
                ),
              ),
            
          ),
        )
        );
      },
    );
  }

  Widget _buildResultMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(value),
      ],
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Icons.upcoming;
      case 'running':
        return Icons.play_circle_filled;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  IconData _buildStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Icons.upcoming;
      case 'running':
        return Icons.play_circle_outline;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildStatisticsCard() {
    final upcomingExams = _getFilteredExams('upcoming');
    final runningExams = _getFilteredExams('running');
    final completedExams = _getFilteredExams('completed');
    
    final completedWithResults = completedExams.where((e) => e['result'] != null).toList();
    final averageScore = completedWithResults.isEmpty
        ? 0.0
        : completedWithResults
            .map((e) => (e['result']['marksObtained'] as num) / (e['totalMarks'] as num) * 100)
            .reduce((a, b) => a + b) / completedWithResults.length;

    Widget buildStatCard(String title, String value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exam Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildStatCard(
                  'Upcoming Exams',
                  upcomingExams.length.toString(),
                  AppColors.upcomingColor,
                ),
                const SizedBox(width: 12),
                buildStatCard(
                  'Running Exams',
                  runningExams.length.toString(),
                  AppColors.runningColor,
                ),
                const SizedBox(width: 12),
                buildStatCard(
                  'Completed Exams',
                  completedExams.length.toString(),
                  AppColors.completedColor,
                ),
                const SizedBox(width: 12),
                buildStatCard(
                  'Average Score',
                  '${averageScore.toStringAsFixed(1)}%',
                  AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForStatus(title),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return AppColors.upcomingColor;
      case 'running':
        return AppColors.runningColor;
      case 'completed':
        return AppColors.completedColor;
      default:
        return Colors.grey;
    }
  }

