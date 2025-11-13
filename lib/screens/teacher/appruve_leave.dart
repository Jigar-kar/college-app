import 'package:bca_c/components/loader.dart';
import 'package:bca_c/screens/teacher/leave_hestory.dart';
import 'package:bca_c/services/teacher_service.dart'; // Import TeacherService
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color approvedColor = Color(0xFF4CAF50);
  static const Color rejectedColor = Color(0xFFE53935);
  static const Color pendingColor = Color(0xFF303F9F);
  static const Color cardBg = Color(0xFFFAFAFA);
}

class TeacherLeaveApprovalScreen extends StatefulWidget {
  const TeacherLeaveApprovalScreen({super.key});

  @override
  _TeacherLeaveApprovalScreenState createState() =>
      _TeacherLeaveApprovalScreenState();
}

class _TeacherLeaveApprovalScreenState
    extends State<TeacherLeaveApprovalScreen> {
  List<Map<String, dynamic>> leaveRequests = [];
  bool isLoading = true;
  String? teacherClass; // Store teacher's class as a String, not a List
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a map to store student names
  Map<String, String> studentNames = {};

  final TeacherService _teacherService = TeacherService(); // Teacher service

  @override
  void initState() {
    super.initState();
    fetchTeacherClass(); // Fetch the teacher's class
    fetchPendingLeaveRequests(); // Fetch leave requests
  }

  // Fetch the current teacher's class
  Future<void> fetchTeacherClass() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        teacherClass = (await _teacherService.fetchTeacherClasses()) as String?;

        setState(() {});
      } catch (e) {
        print('Error fetching teacher class: $e');
      }
    }
  }

  Future<void> _getStudentName(String studentId) async {
    try {
      if (studentNames.containsKey(studentId)) {
        return; // Return if we already have the name
      }

      final userDoc = await _db.collection('students').doc(studentId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          studentNames[studentId] = data['name'] ?? 'Unknown';
        });
      } else {
        setState(() {
          studentNames[studentId] = 'Unknown';
        });
      }
    } catch (e) {
      print('Error fetching student name: $e');
      setState(() {
        studentNames[studentId] = 'Unknown';
      });
    }
  }

  // Fetch pending leave requests from Firestore
  Future<void> fetchPendingLeaveRequests() async {
    try {
      setState(() {
        isLoading = true;
      });

      final querySnapshot = await FirebaseFirestore.instance
          .collection('leaves')
          .where('status', isEqualTo: 'Pending')
          .get();

      final List<Map<String, dynamic>> fetchedLeaves =
          querySnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Add the Firestore document ID to the data map
        return data;
      }).toList();

      // Filter leaves to match the teacher's class
      List<Map<String, dynamic>> filteredLeaves = fetchedLeaves
          .where((leave) => leave['studentClass'] == teacherClass)
          .toList();

      // Fetch student names for all leaves
      for (var leave in filteredLeaves) {
        String studentId = leave['studentId'] ?? '';
        if (studentId.isNotEmpty) {
          await _getStudentName(studentId);
        }
      }

      setState(() {
        leaveRequests =
            filteredLeaves; // Update the leave requests to only include the teacher's class
      });
    } catch (e) {
      print('Error fetching leave requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch leave requests. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update leave status (approve/reject) directly in Firestore
  Future<void> updateLeaveStatus(String leaveId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('leaves')
          .doc(leaveId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave marked as $status.'),
          backgroundColor: Colors.green,
        ),
      );

      fetchPendingLeaveRequests(); // Refresh leave requests to show updates
    } catch (e) {
      print('Error updating leave status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update leave status. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return DateTime.now();
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave Approvals',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Manage student leave requests',
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TeacherLeaveHistoryScreen(),
                          ),
                        );
                      },
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
                      : leaveRequests.isEmpty
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
                                    'No pending leave requests',
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
                              itemCount: leaveRequests.length,
                              itemBuilder: (context, index) {
                                return _buildLeaveCard(leaveRequests[index]);
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

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    DateTime fromDate = _parseDate(leave['fromDate']);
    DateTime toDate = _parseDate(leave['toDate']);
    String studentId = leave['studentId'] ?? '';
    String reason = leave['reason'] ?? 'No reason provided';
    String status = leave['status'] ?? 'Pending';
    String studentName = studentNames[studentId] ?? 'Loading...';

    Color statusColor;
    if (status == 'Approved') {
      statusColor = AppColors.approvedColor;
    } else if (status == 'Rejected') {
      statusColor = AppColors.rejectedColor;
    } else {
      statusColor = AppColors.pendingColor;
    }

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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      statusColor.withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            studentName.isNotEmpty ? studentName[0] : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            '${fromDate.toString().split(' ')[0]} to ${toDate.toString().split(' ')[0]}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reason,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (status == 'Pending')
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16,
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.approvedColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    updateLeaveStatus(leave['id'], 'Approved'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.rejectedColor,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    updateLeaveStatus(leave['id'], 'Rejected'),
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
        );
      },
    );
  }
}
