import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeeDashboard extends StatefulWidget {
  const FeeDashboard({super.key});

  @override
  _FeeDashboardState createState() => _FeeDashboardState();
}

class _FeeDashboardState extends State<FeeDashboard> {
  bool isLoading = true;
  double totalCollected = 0;
  double pendingPayments = 0;
  double totalRefunds = 0;
  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> feeCategories = [];
  List<Map<String, dynamic>> semesterFees = [];
  Map<String, int> statusDistribution = {
    'paid': 0,
    'pending': 0,
    'refunded': 0
  };
  String selectedClass = 'All';
  String selectedSemester = 'All';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load fees data
      final feesSnapshot = await FirebaseFirestore.instance
          .collection('fees')
          .orderBy('timestamp', descending: true)
          .get();

      semesterFees = feesSnapshot.docs.map((doc) {
        final data = doc.data();
        final students = (data['students'] as List<dynamic>);
        
        // Calculate status counts
        int paidCount = 0;
        int pendingCount = 0;
        
        for (var student in students) {
          if (student['status'] == 'paid') {
            paidCount++;
            totalCollected += data['amount'];
          } else if (student['status'] == 'pending') {
            pendingCount++;
            pendingPayments += data['amount'];
          }
        }

        return {
          'id': doc.id,
          'amount': data['amount'],
          'class': data['class'],
          'semester': data['semester'],
          'month': data['month'],
          'students': students,
          'paidCount': paidCount,
          'pendingCount': pendingCount,
          'totalStudents': students.length,
        };
      }).toList();

      // Update status distribution
      for (var fee in semesterFees) {
statusDistribution['paid'] = ((statusDistribution['paid'] ?? 0) + fee['paidCount']).toInt();
        statusDistribution['pending'] = ((statusDistribution['pending'] ?? 0) + fee['pendingCount']).toInt();
      }

      // Load payments for recent transactions
      final paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      recentTransactions = paymentSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'amount': data['amount'],
          'class': data['class'],
          'semester': data['semester'],
          'month': data['month'],
          'status': data['status'],
          'timestamp': data['timestamp'],
        };
      }).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
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
            colors: [Color(0xFF303F9F), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Fee Management Dashboard',
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
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatisticsCards(),
                              const SizedBox(height: 24),
                              _buildFeeCategories(),
                              const SizedBox(height: 24),
                              _buildRecentTransactions(),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/add-fees');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: selectedClass,
                items: ['All', 'FY', 'SY', 'TY'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedClass = newValue!;
                    _loadDashboardData();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: selectedSemester,
                items: ['All', 'Sem-1', 'Sem-2', 'Sem-3', 'Sem-4', 'Sem-5', 'Sem-6'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSemester = newValue!;
                    _loadDashboardData();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'Total Collections',
              '₹${NumberFormat('#,##,###.##').format(totalCollected)}',
              Colors.green,
            ),
            _buildStatCard(
              'Pending Payments',
              '₹${NumberFormat('#,##,###.##').format(pendingPayments)}',
              Colors.orange,
            ),
            _buildStatCard(
              'Payment Status',
              '${((statusDistribution['paid'] ?? 0) / (statusDistribution['paid'] ?? 0 + statusDistribution['pending']! ?? 0) * 100).toStringAsFixed(1)}%',
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Semester Fees',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: semesterFees.length,
          itemBuilder: (context, index) {
            final fee = semesterFees[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fee['class'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fee['semester'],
                        style: const TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Month: ${fee['month']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${NumberFormat('#,##,###').format(fee['amount'])}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Paid: ${fee['paidCount']}/${fee['totalStudents']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: fee['paidCount'] == fee['totalStudents'] ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTransactions.length,
          itemBuilder: (context, index) {
            final transaction = recentTransactions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Row(
                  children: [
                    Text(
                      transaction['class'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      transaction['semester'],
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Month: ${transaction['month']}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(transaction['amount'])}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction['status'],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/admin/transaction-details',
                    arguments: transaction['id'],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}