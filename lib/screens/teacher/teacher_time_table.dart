import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
}

enum ClassStatus {
  upcoming,
  ongoing,
  completed
}

class TeacherTimetablePage extends StatefulWidget {
  const TeacherTimetablePage({super.key});

  @override
  _TeacherTimetablePageState createState() => _TeacherTimetablePageState();
}

class _TeacherTimetablePageState extends State<TeacherTimetablePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> timetableData = [];
  String teacherName = '';
  List<String> teacherSubjects = [];
  List<String> teacherClasses = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final teacherDoc = await _firestore.collection('teachers').doc(user.uid).get();
        if (teacherDoc.exists) {
          final data = teacherDoc.data() as Map<String, dynamic>;
          setState(() {
            teacherName = data['name'] ?? '';
            teacherSubjects = List<String>.from(data['subjects'] ?? []);
            if (data['class'] is String) {
              teacherClasses = [data['class']];
            } else if (data['class'] is List) {
              teacherClasses = List<String>.from(data['class']);
            } else {
              teacherClasses = [];
            }
          });
          fetchTimetableData();
        }
      }
    } catch (e) {
      print('Error loading teacher info: $e');
    }
  }

  ClassStatus getClassStatus(String startTime, String endTime) {
    final now = DateTime.now();
    
    final startComponents = startTime.split(':');
    int startHour = int.parse(startComponents[0]);
    final startMinuteParts = startComponents[1].split(' ');
    int startMinute = int.parse(startMinuteParts[0]);
    final startPeriod = startMinuteParts[1].toUpperCase(); // AM or PM
    
    if (startPeriod == 'PM' && startHour != 12) {
      startHour += 12;
    }
    if (startPeriod == 'AM' && startHour == 12) {
      startHour = 0;
    }

    final endComponents = endTime.split(':');
    int endHour = int.parse(endComponents[0]);
    final endMinuteParts = endComponents[1].split(' ');
    int endMinute = int.parse(endMinuteParts[0]);
    final endPeriod = endMinuteParts[1].toUpperCase(); // AM or PM
    
    // Adjust hours for PM
    if (endPeriod == 'PM' && endHour != 12) {
      endHour += 12;
    }
    // Adjust for 12 AM
    if (endPeriod == 'AM' && endHour == 12) {
      endHour = 0;
    }

    // Create DateTime objects for comparison
    final classStart = DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      startMinute
    );

    final classEnd = DateTime(
      now.year,
      now.month,
      now.day,
      endHour,
      endMinute
    );

    // Get current time without seconds for accurate comparison
    final currentTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute
    );

    // Compare times
    if (currentTime.isBefore(classStart)) {
      return ClassStatus.upcoming;
    } else if (currentTime.isAfter(classEnd) || currentTime.isAtSameMomentAs(classEnd)) {
      return ClassStatus.completed;
    } else {
      return ClassStatus.ongoing;
    }
  }

  Color getStatusColor(ClassStatus status) {
    switch (status) {
      case ClassStatus.upcoming:
        return AppColors.warning;
      case ClassStatus.ongoing:
        return AppColors.success;
      case ClassStatus.completed:
        return AppColors.error;
    }
  }

  String getStatusText(ClassStatus status) {
    switch (status) {
      case ClassStatus.upcoming:
        return 'Upcoming';
      case ClassStatus.ongoing:
        return 'Ongoing';
      case ClassStatus.completed:
        return 'Completed';
    }
  }

  Future<void> fetchTimetableData() async {
    try {
      setState(() => isLoading = true);

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

      final snapshot = await _firestore
          .collection('timetables')
          .where('day', isEqualTo: currentDay)
          .where('class', whereIn: teacherClasses)
          .orderBy('startTime')
          .get();

      final List<Map<String, dynamic>> data = [];

      for (var doc in snapshot.docs) {
        final classData = doc.data();
        final status = getClassStatus(
          classData['startTime'] as String, 
          classData['endTime'] as String
        );
        
        data.add({
          ...classData,
          'id': doc.id,
          'status': status,
        });
      }

      setState(() {
        timetableData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching timetable: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAttendance(String classId) async {
    // TODO: Implement attendance marking functionality
  }

  Widget _buildTimetableCard(Map<String, dynamic> classData) {
    final ClassStatus status = classData['status'] as ClassStatus;
    final Color statusColor = getStatusColor(status);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.2),
            ),
            child: Icon(
              _getSubjectIcon(classData['subject']),
              color: statusColor,
            ),
          ),
          title: Text(
            classData['subject'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '${classData['startTime']} - ${classData['endTime']}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      getStatusText(status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Class ${classData['class']}',
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('Mark Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: status == ClassStatus.ongoing 
                        ? () => _markAttendance(classData['id'])
                        : null,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.note_add),
                    label: const Text('Add Notes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Implement notes functionality
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.book;
      case 'computer':
        return Icons.computer;
      default:
        return Icons.subject;
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Schedule',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            teacherName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
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
                      ? const Center(child: CircularProgressIndicator())
                      : timetableData.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No classes scheduled for today',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : AnimationLimiter(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 16),
                                itemCount: timetableData.length,
                                itemBuilder: (context, index) {
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: _buildTimetableCard(
                                          timetableData[index],
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
}