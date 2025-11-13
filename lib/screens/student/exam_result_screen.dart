import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

import '../../models/exam_model.dart';

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

class ExamResultScreen extends StatefulWidget {
  final String studentId;

  const ExamResultScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  final _db = FirebaseFirestore.instance;

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
                      'Exam Results',
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
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('examResults')
                        .where('studentId', isEqualTo: widget.studentId)
                        .where('status', isEqualTo: 'Approved')
                        .snapshots(),
                    builder: (context, resultSnapshot) {
                      if (resultSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${resultSnapshot.error}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }

                      if (resultSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final results = resultSnapshot.data?.docs ?? [];

                      if (results.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Group results by examId and subject
                      Map<String, Map<String, QueryDocumentSnapshot>>
                          groupedResults = {};
                      for (var doc in results) {
                        final examId = doc['examId'] as String;
                        final subject = doc['subject'] as String? ?? 'Unknown';
                        if (!groupedResults.containsKey(examId)) {
                          groupedResults[examId] = {};
                        }
                        groupedResults[examId]![subject] = doc;
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedResults.length,
                        itemBuilder: (context, index) {
                          final examId = groupedResults.keys.elementAt(index);
                          final subjectResults = groupedResults[examId]!;

                          return FutureBuilder<DocumentSnapshot>(
                            future: _db.collection('exams').doc(examId).get(),
                            builder: (context, examSnapshot) {
                              if (!examSnapshot.hasData) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                );
                              }

                              final examData = examSnapshot.data!.data();
                              if (examData == null) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(''),
                                  ),
                                );
                              }

                              final exam = ExamModel.fromMap(
                                examSnapshot.data!.id,
                                examData as Map<String, dynamic>,
                              );

                              // Calculate total marks and percentage across all subjects
                              int totalMarksObtained = 0;
                              int totalMaxMarks = 0;
                              Map<String, Map<String, dynamic>> subjectDetails =
                                  {};

                              subjectResults.forEach((subject, doc) {
                                final resultData =
                                    doc.data() as Map<String, dynamic>;
                                final subjectMarks =
                                    resultData['marksObtained'] as int;
                                final subjectMaxMarks =
                                    resultData['totalMarks'] as int? ??
                                        exam.totalMarks;

                                totalMarksObtained += subjectMarks;
                                totalMaxMarks =
                                    (subjectMaxMarks * subjectResults.length)
                                        .toInt();

                                subjectDetails[subject] = {
                                  'marksObtained': subjectMarks,
                                  'totalMarks': subjectMaxMarks,
                                  'percentage':
                                      (subjectMarks / subjectMaxMarks) * 100,
                                };
                              });

                              final overallPercentage =
                                  (totalMarksObtained / totalMaxMarks) * 100;
                              final overallGrade =
                                  _calculateGrade(overallPercentage);

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
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            // Show detailed result dialog
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(
                                                  exam.examName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.primaryColor,
                                                  ),
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Subject-wise Results:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ...subjectDetails.entries
                                                        .map((entry) {
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const SizedBox(
                                                              height: 16),
                                                          Text(
                                                            entry.key,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .primaryColor,
                                                            ),
                                                          ),
                                                          _buildDetailRow(
                                                              'Marks',
                                                              '${entry.value['marksObtained']}/${entry.value['totalMarks']}'),
                                                          _buildDetailRow(
                                                              'Percentage',
                                                              '${entry.value['percentage'].toStringAsFixed(2)}%'),
                                                          const SizedBox(
                                                              height: 8),
                                                        ],
                                                      );
                                                    }),
                                                    const Divider(),
                                                    const Text(
                                                      'Overall Result:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _buildDetailRow(
                                                        'Total Marks',
                                                        '$totalMarksObtained/$totalMaxMarks'),
                                                    _buildDetailRow(
                                                        'Overall Percentage',
                                                        '${overallPercentage.toStringAsFixed(2)}%'),
                                                    _buildDetailRow(
                                                        'Overall Grade',
                                                        overallGrade),
                                                    const SizedBox(height: 16),
                                                    ElevatedButton.icon(
                                                      icon: const Icon(
                                                          Icons.download,
                                                          color: Colors.white),
                                                      label: const Text(
                                                          'Download PDF',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppColors
                                                                .primaryColor,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 8),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          _generateAndDownloadPDF(
                                                        exam.examName,
                                                        subjectDetails,
                                                        totalMarksObtained,
                                                        totalMaxMarks,
                                                        overallPercentage,
                                                        overallGrade,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: Card(
                                            elevation: 0,
                                            margin: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const SizedBox(
                                                          height: 16),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .primaryColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: const Icon(
                                                          Icons.assignment,
                                                          color: AppColors
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const SizedBox(
                                                                height: 16),
                                                            Text(
                                                              exam.examName,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: AppColors
                                                                    .textPrimary,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                              'Tap for more info',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .textSecondary
                                                                    .withOpacity(
                                                                        0.7),
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        overallGrade,
                                                        style: TextStyle(
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: _getGradeColor(
                                                              overallGrade),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      ElevatedButton.icon(
                                                        icon: const Icon(
                                                            Icons.download,
                                                            color:
                                                                Colors.white),
                                                        label: const Text(
                                                            'Download PDF',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              AppColors
                                                                  .primaryColor,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 8),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            _generateAndDownloadPDF(
                                                          exam.examName,
                                                          subjectDetails,
                                                          totalMarksObtained,
                                                          totalMaxMarks,
                                                          overallPercentage,
                                                          overallGrade,
                                                        ),
                                                      ),
                                                      
                                                      _buildInfoItem(
                                                        Icons.class_,
                                                        'Class',
                                                        exam.className,
                                                      ),
                                                      _buildInfoItem(
                                                        Icons.calendar_today,
                                                        'Date',
                                                        _formatDate(
                                                            exam.examDate),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.cardBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        
                                                        _buildScoreItem(
                                                          'Marks',
                                                          '$totalMarksObtained/$totalMaxMarks',
                                                        ),
                                                        Container(
                                                          width: 1,
                                                          height: 40,
                                                          color: Colors.grey
                                                              .withOpacity(0.2),
                                                        ),
                                                        _buildScoreItem(
                                                          'Percentage',
                                                          '${overallPercentage.toStringAsFixed(1)}%',
                                                        ),
                                                      ],
                                                    ),
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
                            },
                          );
                        },
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return AppColors.success;
      case 'A':
        return const Color(0xFF66BB6A);
      case 'B+':
        return AppColors.accentColor;
      case 'B':
        return const Color(0xFF26A69A);
      case 'C':
        return const Color(0xFFFFA726);
      case 'D':
        return const Color(0xFFEF5350);
      default:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _generateAndDownloadPDF(
    String examName,
    Map<String, Map<String, dynamic>> subjectDetails,
    int totalMarksObtained,
    int totalMaxMarks,
    double overallPercentage,
    String overallGrade,
  ) async {
    final pdf = pw.Document();

    // Add page with professional layout
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with college name and logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'BCA College',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Examination Result',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Exam Details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Exam: $examName',
                        style: const pw.TextStyle(fontSize: 16)),
                    pw.Text('Date: ${_formatDate(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Subject-wise Results Table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Subject',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Marks Obtained',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Marks',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Percentage',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Subject Rows
                  ...subjectDetails.entries.map(
                    (entry) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(entry.key),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child:
                              pw.Text(entry.value['marksObtained'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(entry.value['totalMarks'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '${entry.value['percentage'].toStringAsFixed(2)}%'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Overall Result
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Marks: $totalMarksObtained/$totalMaxMarks',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Overall Percentage: ${overallPercentage.toStringAsFixed(2)}%',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Grade: $overallGrade',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated on: ${_formatDate(DateTime.now())}'),
                  pw.Text('Authorized Signature'),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save and download PDF based on platform
    if (kIsWeb) {
      // For web platform
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = '${examName.replaceAll(' ', '_')}_result.pdf';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // For Android platform
      final output = await getTemporaryDirectory();
      final file =
          File('${output.path}/${examName.replaceAll(' ', '_')}_result.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Exam Result PDF');
    }
  }
}
