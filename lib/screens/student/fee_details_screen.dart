import 'package:bca_c/components/loader.dart';
import 'package:bca_c/services/FeeService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
final firebaseAuth = FirebaseAuth.instance;

class FeeDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> feeData;

  const FeeDetailsScreen({
    super.key,
    required this.feeData,
  });

  @override
  State<FeeDetailsScreen> createState() => _FeeDetailsScreenState();
}

class _FeeDetailsScreenState extends State<FeeDetailsScreen> {
  final FeeService _feeService = FeeService();
  bool isLoading = true;
  final currentuser = firebaseAuth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Details'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: Loader())
          : _buildFeeDetailCard(widget.feeData),
    );
  }

  Widget _buildFeeDetailCard(Map<String, dynamic> feeDetail) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction ID: ${feeDetail['transactionId'] ?? 'N/A'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Student Name', feeDetail['studentName'] ?? 'N/A'),
            _buildDetailRow('Student ID', currentuser),
            _buildDetailRow('Class', feeDetail['class'] ?? 'N/A'),
            _buildDetailRow('Semester', feeDetail['semester'] ?? 'N/A'),
            _buildDetailRow('Amount', '₹${feeDetail['amount'] ?? 'N/A'}'),
            _buildDetailRow('Status', feeDetail['status'] ?? 'N/A'),
            _buildDetailRow('Month/Year', feeDetail['monthYear'] ?? 'N/A'),
            _buildDetailRow('Payment Method', feeDetail['paymentMethod'] ?? 'N/A'),
            _buildDetailRow('Payment Date', feeDetail['timestamp'] != null 
              ? DateFormat('MMM dd, yyyy hh:mm a').format(feeDetail['timestamp'].toDate())
              : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}