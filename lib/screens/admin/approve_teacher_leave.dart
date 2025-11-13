// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:bca_c/services/teacher_leave.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
}

class AdminLeaveScreen extends StatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  _AdminLeaveScreenState createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen> {
  final LeaveService _leaveService = LeaveService();

  List<Map<String, dynamic>> leaveRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaveRequests();
  }

  // Fetch leave requests for the admin
  Future<void> fetchLeaveRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch all leave requests (from all teachers)
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('teacher_leaves').get();

      leaveRequests = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'teacherId': doc['teacherId'],
          'fromDate': doc['fromDate'],
          'toDate': doc['toDate'],
          'reason': doc['reason'],
          'status': doc['status'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching leave requests: $e');
      }
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

  // Approve leave request
  Future<void> approveLeave(String leaveId) async {
    try {
      await _leaveService.approveLeave(leaveId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave approved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      fetchLeaveRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve leave.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Reject leave request and update reason
  Future<void> rejectLeave(String leaveId, String newReason) async {
    try {
      await _leaveService.rejectLeave(leaveId, newReason);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave rejected and reason updated.'),
          backgroundColor: Colors.red,
        ),
      );
      fetchLeaveRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject leave.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update leave days
  Future<void> updateLeaveDays(String leaveId, String newFromDate, String newToDate) async {
    try {
      await _leaveService.updateLeaveDays(leaveId, newFromDate, newToDate);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave days updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      fetchLeaveRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update leave days.'),
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
                            "Leave Requests",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Manage teacher leave applications",
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
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                      : leaveRequests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_late_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No leave requests found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: leaveRequests.length,
                              itemBuilder: (context, index) {
                                final leave = leaveRequests[index];
                                return _buildLeaveCard(leave);
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

  // Widget for leave request card
  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    return GestureDetector(
      onTap: () => _showActionDialog(leave['id'], leave),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${leave['fromDate']} to ${leave['toDate']}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${leave['reason']}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: leave['status'] == 'Pending'
                      ? Colors.orange.shade100
                      : leave['status'] == 'Approved'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  leave['status'],
                  style: TextStyle(
                    color: leave['status'] == 'Pending'
                        ? Colors.orange
                        : leave['status'] == 'Approved'
                            ? Colors.green
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action dialog to approve, reject, or update leave details
  void _showActionDialog(String leaveId, Map<String, dynamic> leave) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Leave Request Actions"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leave['status'] == 'Pending') ...[
                ElevatedButton(
                  onPressed: () {
                    approveLeave(leaveId);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Approve Leave'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    _rejectLeaveDialog(leaveId);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Reject Leave'),
                ),
              ],
              ElevatedButton(
                onPressed: () {
                  _updateLeaveDaysDialog(leaveId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Update Leave Days'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog for rejecting leave and updating the reason
  void _rejectLeaveDialog(String leaveId) {
    final TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Reject Leave and Update Reason"),
          content: TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'New Reason for Rejection',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (_reasonController.text.isNotEmpty) {
                  await rejectLeave(leaveId, _reasonController.text);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reason cannot be empty!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Dialog for updating leave days
  void _updateLeaveDaysDialog(String leaveId) {
    final TextEditingController _fromDateController = TextEditingController();
    final TextEditingController _toDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Update Leave Days"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fromDateController,
                decoration: const InputDecoration(
                  labelText: 'From Date (YYYY-MM-DD)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _toDateController,
                decoration: const InputDecoration(
                  labelText: 'To Date (YYYY-MM-DD)',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (_fromDateController.text.isNotEmpty &&
                    _toDateController.text.isNotEmpty) {
                  await updateLeaveDays(leaveId, _fromDateController.text, _toDateController.text);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Both dates must be filled!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}