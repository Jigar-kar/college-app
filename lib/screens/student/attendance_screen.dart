// ignore_for_file: library_private_types_in_public_api

import 'package:bca_c/components/loader.dart'; // Ensure to import your loader
import 'package:bca_c/screens/student/month_attendance_detail_screen.dart'; // Import the new screen
import 'package:bca_c/services/attendance_service.dart'; // Ensure this path is correct
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color presentColor = Color(0xFF4CAF50);
  static const Color absentColor = Color(0xFFE53935);
  static const Color cardBg = Color(0xFFFAFAFA);
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  Map<String, Map<String, int>> monthlyAttendanceCounts =
      {}; // Map to store attendance counts by month
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  String _formatMonth(String monthYear) {
    List<String> months = [
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

    final parts = monthYear.split('-');
    final monthIndex = int.parse(parts[0]) - 1;
    return '${months[monthIndex]} ${parts[1]}';
  }

  // Load attendance data from Firebase
  Future<void> _loadAttendance() async {
    setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> data =
          await _attendanceService.getAttendance();

      // Group attendance by month and count present/absent students
      for (var entry in data) {
        DateTime date = (entry['date'] as Timestamp).toDate().toLocal();

        // Get the month and year to group by month
        String monthYear = '${date.month}-${date.year}';

        if (!monthlyAttendanceCounts.containsKey(monthYear)) {
          monthlyAttendanceCounts[monthYear] = {
            "present": 0,
            "absent": 0
          }; // Initialize present/absent counts for the month
        }

        // Count present/absent
        if (entry['status'] == 'present') {
          monthlyAttendanceCounts[monthYear]!['present'] =
              monthlyAttendanceCounts[monthYear]!['present']! + 1;
        } else {
          monthlyAttendanceCounts[monthYear]!['absent'] =
              monthlyAttendanceCounts[monthYear]!['absent']! + 1;
        }
      }
    } catch (e) {
      _showErrorDialog('Error loading attendance: $e');
    } finally {
      setState(() => isLoading = false);
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
                    const Text(
                      "Monthly Attendance",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                      : monthlyAttendanceCounts.isEmpty
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
                                    'No attendance records available',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 16),
                              itemCount: monthlyAttendanceCounts.length,
                              itemBuilder: (context, index) {
                                String monthYear = monthlyAttendanceCounts.keys
                                    .elementAt(index);
                                return _buildMonthlyAttendanceCard(
                                  monthYear,
                                  monthlyAttendanceCounts[monthYear]!,
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

  // Widget to display attendance for each month
  Widget _buildMonthlyAttendanceCard(
      String monthYear, Map<String, int> counts) {
    final total = counts['present']! + counts['absent']!;
    final percentage = (counts['present']! / total) * 100;

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
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor.withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MonthAttendanceDetailScreen(
                        monthYear: monthYear,
                        selectedSubject: "All",
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatMonth(monthYear),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              tween: Tween(begin: 0, end: percentage / 100),
                              builder: (context, value, _) =>
                                  CircularProgressIndicator(
                                value: value,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAttendanceStatus(
                              'Present',
                              counts['present']!,
                              AppColors.presentColor,
                            ),
                            _buildAttendanceStatus(
                              'Absent',
                              counts['absent']!,
                              AppColors.absentColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStatus(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
