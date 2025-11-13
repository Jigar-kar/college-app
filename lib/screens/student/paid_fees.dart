import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:bca_c/components/loader.dart';
import 'package:bca_c/services/FeeService.dart';
import 'package:bca_c/services/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Add this import at the top with other imports


class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color paidColor = Color(0xFF4CAF50);
  static const Color pendingColor = Color(0xFFE53935);
  static const Color cardBg = Color(0xFFFAFAFA);
}

class paiFeeScreen extends StatefulWidget {
  const paiFeeScreen({super.key});

  @override
  State<paiFeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<paiFeeScreen> {
  final PaymentService _paymentService = PaymentService();
  final FeeService _feeService = FeeService();
  late Razorpay _razorpay;
  final String _selectedPaymentMethod = 'UPI';
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _semesterController = TextEditingController();
  String _currentMonthYear = '';
  Map<String, Map<String, int>> monthlyFeeCounts = {};
  bool isLoading = true;
  List<Map<String, dynamic>> feesList = [];
  late String currentUserId;
  late String studentName;
  late String studentClass;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadFees();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  String _formatMonth(String monthYear) {
    List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final parts = monthYear.split('-');
    final monthIndex = int.parse(parts[0]) - 1;
    return '${months[monthIndex]} ${parts[1]}';
  }

Future<void> updateFeeStatus({
  required String studentId,
  required String monthYear,
  required String status,
  required String paymentId,
}) async {
  try {
    // Get the fee document
    final QuerySnapshot feeSnapshot = await FirebaseFirestore.instance
        .collection('fees')
        .get();

    if (feeSnapshot.docs.isEmpty) {
      throw 'Fee record not found';
    }

    final feeDoc = feeSnapshot.docs.first;
    final List<dynamic> students = List.from(feeDoc.get('students'));

    // Find and update the student's status in the array
    final studentIndex = students.indexWhere(
      (student) => student['studentId'] == studentId
    );

    if (studentIndex == -1) {
      throw 'Student not found in fee record';
    }

    // Update the status for the specific student
    students[studentIndex]['status'] = status;
    students[studentIndex]['paymentId'] = paymentId;
    students[studentIndex]['paidAt'] = DateTime.now();

    // Update the document
    await FirebaseFirestore.instance
        .collection('fees')
        .doc(feeDoc.id)
        .update({
          'students': students,
          'lastUpdated': DateTime.now(),
        });

    print('Fee status updated successfully');
  } catch (e) {
    print('Error updating fee status: $e');
    throw 'Failed to update fee status: $e';
  }
}

Future<void> _loadFees() async {
  setState(() => isLoading = true);

  try {
    // First, fetch student details
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .doc(currentUserId)
        .get();

    if (!studentSnapshot.exists) {
      throw 'Student data not found';
    }

    final studentData = studentSnapshot.data()!;
    studentName = studentData['name'] ?? 'Unknown';
    studentClass = studentData['class'] ?? 'Unknown';

    // Fetch payments for the current student
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('studentId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'paid')
        .orderBy('timestamp', descending: true)
        .get();

    feesList = paymentsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'amount': data['amount'],
        'class': data['class'],
        'monthYear': data['monthYear'],
        'paymentMethod': data['paymentMethod'],
        'semester': data['semester'],
        'status': data['status'],
        'studentName': data['studentName'],
        'timestamp': data['timestamp'],
        'transactionId': data['transactionId'],
      };
    }).toList();

    setState(() {
      isLoading = false;
    });
  } catch (e, stackTrace) {
    print('Error loading fees: $e');
    print('Stack trace: $stackTrace');
    _showErrorDialog('Error loading fees: $e');
  }
}  void _showErrorDialog(String message) {
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

  void _showPaymentForm(String monthYear, Map<String, dynamic> feeData) {
  _currentMonthYear = monthYear;
  // Auto-fill the amount from the fee card
  _amountController.text = feeData['amount'].toString();
  _semesterController.text = ''; // Reset semester
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pay Fee Online',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _semesterController,
                decoration: InputDecoration(
                  labelText: 'Semester',
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter semester' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                enabled: false, // Make amount field read-only
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true, // Add fill color to show it's readonly
                  fillColor: Colors.grey[100],
                ),
                keyboardType: TextInputType.number,
              ),
            const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _startPayment();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Proceed to Pay',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _startPayment() {
  // Common options for both platforms
  var options = {
    'key': 'rzp_test_9Qm9UPfUdOlR0O',
    'amount': double.parse(_amountController.text) * 100,
    'name': 'SatuaBaba BCA College',
    'description': 'Fee Payment for ${_formatMonth(_currentMonthYear)}',
    'prefill': {
      'name': studentName,
      'contact': '', // Add student contact if available
      'email': FirebaseAuth.instance.currentUser?.email ?? '',
    },
    'notes': {
      'semester': _semesterController.text,
      'student_id': currentUserId,
      'class': studentClass,
    },
    'theme': {
      'color': '#1A237E',
    }
  };

  if (kIsWeb) {
    // Web-specific implementation
    _handleWebPayment(options);
  } else {
    // Mobile-specific implementation
    try {
      _razorpay.open(options);
    } catch (e) {
      _showErrorDialog('Error initializing payment: $e');
    }
  }
}

// Add this method for web payments
Future<void> _handleWebPayment(Map<String, dynamic> options) async {
  try {
    // Create payment handler for web
    final response = await FirebaseFirestore.instance
        .collection('razorpay_orders')
        .add({
          'amount': options['amount'],
          'currency': 'INR',
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        });

    final Uri url = Uri.https('api.razorpay.com', '/v1/checkout/embedded', {
      'key': options['key'],
      'amount': options['amount'].toString(),
      'currency': 'INR',
      'name': options['name'],
      'description': options['description'],
      'prefill': jsonEncode(options['prefill']),
      'notes': jsonEncode(options['notes']),
      'callback_url': 'http://localhost:50458/', // Replace with your callback URL
      'order_id': response.id,
    });

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        webOnlyWindowName: '_self', // Open in same window
      );
    } else {
      _showErrorDialog('Could not launch payment gateway');
    }
  } catch (e) {
    _showErrorDialog('Error processing web payment: $e');
  }
}

void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  try {
    final paymentData = {
      'monthYear': _currentMonthYear,
      'amount': double.parse(_amountController.text),
      'paymentMethod': _selectedPaymentMethod,
      'semester': _semesterController.text,
      'transactionId': response.paymentId!,
      'platform': kIsWeb ? 'web' : 'mobile',
      'timestamp': DateTime.now(),
      'studentId': currentUserId,
      'studentName': studentName,
      'class': studentClass,
    };

    // Update payment status in Firestore
    await FirebaseFirestore.instance
        .collection('payments')
        .doc(response.paymentId)
        .set(paymentData);

    // Update fee status
    await updateFeeStatus(
      studentId: currentUserId,
      monthYear: _currentMonthYear,
      status: 'paid',
      paymentId: response.paymentId!,
    );

    _showSuccessDialog(paymentData);
    _loadFees(); // Refresh the fee list
  } catch (e) {
    _showErrorDialog('Error processing payment: $e');
  }
}

  void _handlePaymentError(PaymentFailureResponse response) {
    _showErrorDialog('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External Wallet Selected: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void _showSuccessDialog(Map<String, dynamic> paymentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${paymentData['transactionId']}'),
            Text('Amount: ₹${paymentData['amount']}'),
            Text('Date: ${DateTime.now().toString().split('.')[0]}'),
            Text('Payment Method: ${paymentData['paymentMethod']}'),
            Text('Semester: ${paymentData['semester']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _generateReceipt(paymentData);
            },
            child: const Text('Download Receipt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReceipt(Map<String, dynamic> paymentData) async {
    final pdf = pw.Document();
    final DateFormat formatter = DateFormat('dd MMM yyyy, hh:mm a');

    try {
      // Load logo from assets
      final ByteData logoBytes = await rootBundle.load('assets/logo3.png');
      final Uint8List logoUint8List = logoBytes.buffer.asUint8List();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 2, color: PdfColors.black)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header: Logo + Title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(pw.MemoryImage(logoUint8List), width: 60, height: 60),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'SatuaBaba BCA College',
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Contact No: 9838994198, 9682292955', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Container(width: 60), // For alignment spacing
                  ],
                ),
                pw.SizedBox(height: 10),

                // Student Copy Label
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'STUDENT COPY',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.Divider(),

                // Receipt Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt No: ${paymentData['transactionId']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${formatter.format(paymentData['timestamp'])}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Student Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Student ID: ${paymentData['studentId'] ?? 'N/A'}'),
                          pw.Text('Semester: ${paymentData['semester'] ?? 'N/A'}'),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Received with thanks from Mr./Ms. ${paymentData['studentName'] ?? 'N/A'} a sum of ₹${paymentData['amount']} only via ${paymentData['paymentMethod'] ?? 'Online'}.',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Payment Breakdown Table
                pw.Table(
                  border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Particulars', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Amount (₹)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    _buildTableRow('Month/Year', _formatMonth(paymentData['monthYear'])),
                    _buildTableRow('Fee Amount', paymentData['amount'], isBold: true),
                  ],
                ),
                pw.SizedBox(height: 15),

                // Note
                pw.Text(
                  'All cheques/demand drafts are valid, subject to realization.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),

                // Footer - Non Refundable Note
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 1.5),
                    color: PdfColors.red50,
                  ),
                  child: pw.Text(
                    'Fee Once Paid is Non-Refundable',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                  ),
                ),
                pw.SizedBox(height: 5),

                pw.Text(
                  'Note: Students must retain this copy of receipt with them and must produce on demand.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 30),

                // Signature
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(height: 1, width: 100, color: PdfColors.black),
                        pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      // Save PDF to file
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/fee_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      OpenFile.open(file.path);
      print("PDF generated: ${file.path}");
    } catch (e) {
      print("Error generating PDF: $e");
      throw 'Failed to generate receipt: $e';
    }
  }

  pw.TableRow _buildTableRow(String label, dynamic value, {bool isBold = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(value != null ? value.toString() : 'N/A', style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }

  Widget _buildMonthlyFeeCard(Map<String, dynamic> feeData) {
    final DateTime timestamp = (feeData['timestamp'] as Timestamp).toDate();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatMonth(feeData['monthYear']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                Text(
                  '₹${feeData['amount']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Class: ${feeData['class']}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: ${feeData['transactionId']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paid on: ${DateFormat('MMM dd, yyyy hh:mm a').format(timestamp)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusChip('Paid', AppColors.paidColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _generateReceipt({
                      'transactionId': feeData['transactionId'],
                      'amount': feeData['amount'],
                      'paymentMethod': feeData['paymentMethod'],
                      'semester': feeData['semester'],
                      'monthYear': feeData['monthYear'],
                      'timestamp': timestamp,
                    });
                  },
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text('Download Receipt'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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
                      "Paid Fees",
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
                      : feesList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No fee records available',
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
                              itemCount: feesList.length,
                              itemBuilder: (context, index) {
                                return _buildMonthlyFeeCard(feesList[index]);
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

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    _semesterController.dispose();
    super.dispose();
  }
}
