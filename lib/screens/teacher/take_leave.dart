// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bca_c/services/teacher_leave.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  _LeaveScreenState createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final LeaveService _leaveService = LeaveService(); // Instance of LeaveService

  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  List<Map<String, dynamic>> leaveRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaveRequests();
  }

  // Fetch leave requests from Firestore for the current teacher
  Future<void> fetchLeaveRequests() async {
    try {
      setState(() {
        isLoading = true;
      });

      leaveRequests = await _leaveService.fetchLeaveRequests();
      
      // Sort the leave requests in ascending order by 'fromDate'
      leaveRequests.sort((a, b) {
        DateTime fromDateA = DateTime.parse(a['fromDate']);
        DateTime fromDateB = DateTime.parse(b['fromDate']);
        return fromDateA.compareTo(fromDateB);
      });
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

  // Apply for leave and save it to Firestore
  Future<void> applyForLeave() async {
    if (_fromDateController.text.isEmpty ||
        _toDateController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _leaveService.applyForLeave(
        fromDate: _fromDateController.text,
        toDate: _toDateController.text,
        reason: _reasonController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the fields after submission
      _fromDateController.clear();
      _toDateController.clear();
      _reasonController.clear();

      fetchLeaveRequests(); // Refresh the leave request list
    } catch (e) {
      if (kDebugMode) {
        print('Error applying for leave: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to apply for leave. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Date picker for selecting dates
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Back Button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              // Header
              const Text(
                "Teacher Leave Management",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Apply Leave Section
              const Text(
                'Apply for Leave',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fromDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'From Date (YYYY-MM-DD)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onTap: () => _selectDate(context, _fromDateController),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _toDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'To Date (YYYY-MM-DD)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onTap: () => _selectDate(context, _toDateController),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: const Icon(Icons.comment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: applyForLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),

              // Leave History Section
              const Text(
                'Leave History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : leaveRequests.isEmpty
                      ? const Center(
                          child: Text('No leave requests found.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: leaveRequests.length,
                          itemBuilder: (context, index) {
                            final leave = leaveRequests[index];
                            return _buildLeaveCard(leave);
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for leave request card
  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: ListTile(
        title: Text('${leave['fromDate']} to ${leave['toDate']}'),
        subtitle: Text(leave['reason']),
        trailing: Text(
          leave['status'],
          style: TextStyle(
            color: leave['status'] == 'Pending' ? Colors.orange : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
