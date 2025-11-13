import 'dart:io';

import 'package:bca_c/components/loader.dart';
import 'package:bca_c/screens/student/fee_details_screen.dart';
import 'package:bca_c/screens/student/paid_fees.dart';
import 'package:bca_c/services/FeeService.dart';
import 'package:bca_c/services/payment_service.dart';
import 'package:bca_c/services/platform_payment_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color paidColor = Color(0xFF4CAF50);
  static const Color pendingColor = Color(0xFFE53935);
  static const Color cardBg = Color(0xFFFAFAFA);
}



class FeeScreen extends StatefulWidget {
  const FeeScreen({super.key});

  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  final PaymentService _paymentService = PaymentService();
  final FeeService _feeService = FeeService();
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
  late String sem;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadFees();
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
    print('Updating fee status for student: $studentId, month: $monthYear');

    final QuerySnapshot feeSnapshot = await FirebaseFirestore.instance
        .collection('fees')
        .where('students', arrayContains: {
          'studentId': studentId,
          'class': studentClass,
          'name': studentName,
          'status': 'pending'
        })
        .get();

    

    if (feeSnapshot.docs.isEmpty) {
      print('No matching fee record found');
      throw 'Fee record not found';
    }

    final feeDoc = feeSnapshot.docs.first;
    final List<dynamic> students = List.from(feeDoc.get('students'));

    final studentIndex = students.indexWhere(
      (student) => student['studentId'] == studentId
    );

    if (studentIndex == -1) {
      print('Student array data: $students');
      throw 'Student not found in fee record';
    }

    // Use regular DateTime instead of FieldValue.serverTimestamp()
    final now = DateTime.now().toIso8601String();

    final updatedStudent = {
      ...students[studentIndex] as Map<String, dynamic>,
      'status': status,
      'paymentId': paymentId,
      'paidAt': now,
    };

    students[studentIndex] = updatedStudent;

    await FirebaseFirestore.instance
        .collection('fees')
        .doc(feeDoc.id)
        .update({
          'students': students,
          'lastUpdated': FieldValue.serverTimestamp(), // This is fine as it's not in an array
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
    print('Loading fees for user: $currentUserId'); // Debug log

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
    
    print('Found student: $studentName, Class: $studentClass'); // Debug log
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Found student: $studentName, Class: $studentClass'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],  
      ), 
    );
    // Now fetch fees with dynamic student data
    final feesSnapshot = await FirebaseFirestore.instance
        .collection('fees')
        .where('students', arrayContainsAny: [
          {
            'studentId': currentUserId,
            'class': studentClass,
            'name': studentName, 
            'status': 'pending'
          }
        ])
        .get();

    print('Fetched ${feesSnapshot.docs.length} documents'); // Debug log

    feesList = feesSnapshot.docs.map((doc) {
      final data = doc.data();
      print('Document data: $data'); // Debug log
      
      // Find the student entry in the students array
      final List<dynamic> students = data['students'] as List;
      final studentData = students.firstWhere(
        (student) => student['studentId'] == currentUserId,
        orElse: () => null,
      );

      if (studentData == null) {
        print('Student data not found for user: $currentUserId');
        return null;
      }

      return {
        'id': doc.id,
        'amount': data['amount'],
        'class': data['class'],
        'month': data['month'],
        'studentName': studentData['name'],
        'studentClass': studentData['class'],
        'status': studentData['status'],
      };
    })
    .where((item) => item != null)
    .cast<Map<String, dynamic>>()
    .toList();

    print('Processed feesList: $feesList'); // Debug log

    setState(() {
      isLoading = false;
    });
  } catch (e, stackTrace) {
    print('Error loading fees: $e');
    print('Stack trace: $stackTrace');
    _showErrorDialog('Error loading fees: $e');
  } finally {
    setState(() => isLoading = false);
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
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _startPayment() async {
  final platformPaymentHandler = PlatformPaymentHandler();
  
  try {
    await platformPaymentHandler.startPayment(
      key: 'rzp_test_9Qm9UPfUdOlR0O',
      amount: double.parse(_amountController.text),
      name: 'SatuaBaba BCA College',
      description: 'Fee Payment for ${_formatMonth(_currentMonthYear)}',
      prefill: {
        'name': studentName,
        'contact': '', // Add student contact if available
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
      },
      notes: {
        'semester': _semesterController.text,
        'student_id': currentUserId,
        'class': studentClass,
      },
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  } catch (e) {
    _showErrorDialog('Error initializing payment: $e');
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
      'orderId': response.orderId,
      'signature': response.signature,
      'platform': 'mobile',
      'timestamp': DateTime.now(),
      'studentId': currentUserId,
      'studentName': studentName,
      'class': studentClass,
      'status': 'paid',
      'paymentResponse': response.data
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
          // TextButton(
          //   onPressed: () {
          //     Navigator.pop(context);
          //     _generateReceipt(paymentData);
          //   },
          //   child: const Text('Download Receipt'),
          // ),
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
    
    // Define font fallback for Rupee symbol
    final fontFallback = [
      pw.Font.ttf(await rootBundle.load('assets/fonts/static/NotoSans-Regular.ttf')),
      pw.Font.ttf(await rootBundle.load('assets/fonts/static/NotoSansSymbols-Regular.ttf'))
    ];

    // Configure theme with font fallback
    final theme = pw.ThemeData.withFont(
      base: fontFallback[0],
      fontFallback: fontFallback,
    );

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'SatuaBaba BCA College',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Payment Receipt', style: const pw.TextStyle(fontSize: 18)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('Transaction ID: ${paymentData['transactionId']}'),
            pw.Text('Amount: ₹${paymentData['amount']}'),
            pw.Text('Payment Date: ${DateTime.now().toString().split('.')[0]}'),
            pw.Text('Payment Method: ${paymentData['paymentMethod']}'),
            pw.Text('Semester: ${paymentData['semester']}'),
            pw.Text('Month: ${_formatMonth(_currentMonthYear)}'),
            pw.SizedBox(height: 20),
            pw.Text('Status: Paid', style: const pw.TextStyle(color: PdfColors.green)),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/fee_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    OpenFile.open(file.path);
  }

  Widget _buildMonthlyFeeCard(Map<String, dynamic> feeData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeeDetailsScreen(feeData: feeData),
            ),
          );
          if (result == true) {
            _loadFees();
          }
        },
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
                    _formatMonth(feeData['month']),
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
              _buildStatusChip(
                feeData['status'],
                feeData['status'] == 'paid' ? AppColors.paidColor : AppColors.pendingColor
              ),
              if (feeData['status'] == 'pending')
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      _showPaymentForm(feeData['month'], {'amount': feeData['amount']});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Pay Fee Online',style: TextStyle(color:Colors.white),),
                  ),
                ),
          
            ],
          
          ),
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
                      "Monthly Fee Details",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 46),
                    InkWell( 
                      onTap: () => Navigator.push(context,MaterialPageRoute(builder: (context)=>const paiFeeScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.money,
                          color: AppColors.primaryColor,
                        ),
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

class _razorpay {
  static void clear() {}
}
