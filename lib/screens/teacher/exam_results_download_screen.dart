import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA726);
}

class ExamResultsDownloadScreen extends StatefulWidget {
  final String teacherId;

  const ExamResultsDownloadScreen({
    super.key,
    required this.teacherId,
  });

  @override
  State<ExamResultsDownloadScreen> createState() =>
      _ExamResultsDownloadScreenState();
}

class _ExamResultsDownloadScreenState extends State<ExamResultsDownloadScreen> {
  final _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _exams = [];
  Set<String> _selectedExams = {};

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);

    try {
      final examSnapshot = await _db
          .collection('exams')
          .where('status', isEqualTo: 'Graded')
          .get();

      final exams = examSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'examDate': (data['examDate'] as Timestamp).toDate(),
        };
      }).toList();

      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading exams: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadSelectedResults() async {
    if (_selectedExams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one exam'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Results'];
      var currentRow = 0;

      // Add main title
      var mainTitleCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      mainTitleCell.value = 'Exam Results Summary';
      mainTitleCell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontSize: 14,
        backgroundColorHex: 'FF1A237E',
        fontColorHex: 'FFFFFFFF',
      );
      sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
      currentRow++;

      // Add headers
      final headers = [
        'Roll No',
        'Student Name',
        'Subject',
        'Marks',
        'Percentage'
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: 'FFE3F2FD',
        );
      }
      currentRow++;

      // Process each selected exam
      for (String examId in _selectedExams) {
        final exam = _exams.firstWhere((e) => e['id'] == examId);

        // Get results for this exam
        final resultsSnapshot = await _db
            .collection('examResults')
            .where('examId', isEqualTo: examId)
            .get();

        final results = resultsSnapshot.docs.map((doc) => doc.data()).toList()
          ..sort((a, b) =>
              (a['studentName'] ?? '').compareTo(b['studentName'] ?? ''));

        if (results.isEmpty) continue;

        // Add exam header
        var examHeaderCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        examHeaderCell.value = exam['examName'];
        examHeaderCell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Left,
          fontSize: 12,
          backgroundColorHex: 'FFF5F5F5',
        );
        sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
            CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
        currentRow++;

        // Add student results
        for (var result in results) {
          final marksObtained = num.parse(result['marksObtained'].toString());
          final totalMarks = num.parse(exam['totalMarks'].toString());
          final percentage = (marksObtained / totalMarks * 100);

          final rowData = [
            result['studentId'],
            result['studentName'],
            exam['subject'],
            '$marksObtained/${exam['totalMarks']}',
            '${percentage.toStringAsFixed(1)}%'
          ];

          for (var i = 0; i < rowData.length; i++) {
            var cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: i, rowIndex: currentRow));
            cell.value = rowData[i];

            // Style based on percentage for the percentage column
            CellStyle style;
            if (i == 4) {
              // Percentage column
              if (percentage >= 70) {
                style = CellStyle(
                  horizontalAlign: HorizontalAlign.Center,
                  backgroundColorHex: "FFE8F5E9", // Light green
                );
              } else if (percentage >= 50) {
                style = CellStyle(
                  horizontalAlign: HorizontalAlign.Center,
                  backgroundColorHex: "FFFFF3E0", // Light orange
                );
              } else {
                style = CellStyle(
                  horizontalAlign: HorizontalAlign.Center,
                  backgroundColorHex: "FFFFEBEE", // Light red
                );
              }
            } else {
              style = CellStyle(
                horizontalAlign:
                    i == 1 ? HorizontalAlign.Left : HorizontalAlign.Center,
              );
            }
            cell.cellStyle = style;
          }
          currentRow++;
        }

        // Add exam summary
        var summaryData = results
            .map((r) => num.parse(r['marksObtained'].toString()))
            .toList();
        var avgMarks = summaryData.reduce((a, b) => a + b) / results.length;
        var avgPercentage =
            (avgMarks / num.parse(exam['totalMarks'].toString())) * 100;

        // Update the Excel sheet to arrange data in columns instead of rows
        var summaryStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: 'FFE8EAF6',
        );

        // Set column headers
        var headers = ['Average', 'Marks', 'Percentage'];
        for (var i = 0; i < headers.length; i++) {
          var headerCell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
          headerCell.value = headers[i];
          headerCell.cellStyle = summaryStyle;
        }

        // Set values in columns
        var avgMarksCell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 1, rowIndex: currentRow + 1));
        avgMarksCell.value = avgMarks.toStringAsFixed(1);
        avgMarksCell.cellStyle = summaryStyle;

        var avgPercentCell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 2, rowIndex: currentRow + 1));
        avgPercentCell.value = '${avgPercentage.toStringAsFixed(1)}%';
        avgPercentCell.cellStyle = summaryStyle;

        currentRow += 2; // Add space before next exam
      }

      // Set column widths
      sheet.setColWidth(0, 15); // Roll No
      sheet.setColWidth(1, 30); // Student Name
      sheet.setColWidth(2, 20); // Subject
      sheet.setColWidth(3, 15); // Marks
      sheet.setColWidth(4, 15); // Percentage

      // Get directory and save file
      Directory directory;
      if (Platform.isWindows) {
        directory = Directory(p.join(Directory.current.path, 'downloads'));
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'exam_results_$timestamp.xlsx';
      final filePath = p.join(directory.path, filename);

      // Save file
      final bytes = excel.save();
      if (bytes == null) throw Exception('Failed to generate Excel file');

      File(filePath).writeAsBytesSync(bytes);

      // Share the file
      if (Platform.isWindows) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to ${directory.path}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Exam Results',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error exporting results: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Download Exam Results",
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedExams.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _downloadSelectedResults,
              backgroundColor: AppColors.accentColor,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: _exams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No graded exams found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Select exams to download',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    if (_selectedExams.length ==
                                        _exams.length) {
                                      _selectedExams.clear();
                                    } else {
                                      _selectedExams = _exams
                                          .map((e) => e['id'] as String)
                                          .toSet();
                                    }
                                  });
                                },
                                icon: Icon(
                                  _selectedExams.length == _exams.length
                                      ? Icons.deselect
                                      : Icons.select_all,
                                  color: AppColors.accentColor,
                                ),
                                label: Text(
                                  _selectedExams.length == _exams.length
                                      ? 'Deselect All'
                                      : 'Select All',
                                  style: const TextStyle(
                                    color: AppColors.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _exams.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final exam = _exams[index];
                              final isSelected =
                                  _selectedExams.contains(exam['id']);

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedExams.remove(exam['id']);
                                      } else {
                                        _selectedExams.add(exam['id']);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exam['examName'] ??
                                                    'Untitled Exam',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              _buildInfoRow(Icons.subject,
                                                  'Subject: ${exam['subject']}'),
                                              const SizedBox(height: 4),
                                              _buildInfoRow(Icons.class_,
                                                  'Class: ${exam['className']}'),
                                              const SizedBox(height: 4),
                                              _buildInfoRow(
                                                Icons.calendar_today,
                                                'Date: ${exam['examDate'].toString().split(' ')[0]}',
                                              ),
                                            ],
                                          ),
                                        ),
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedExams.add(exam['id']);
                                              } else {
                                                _selectedExams
                                                    .remove(exam['id']);
                                              }
                                            });
                                          },
                                          activeColor: AppColors.accentColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
