import 'dart:io';

import 'package:bca_c/components/loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  Map<String, List<Map<String, dynamic>>> studentAttendanceHistory = {};
  Map<String, String> studentNames = {};
  Map<String, int> presentDaysCount = {};
  bool isLoading = true;
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    fetchAttendanceHistory();
  }

  Future<void> fetchAttendanceHistory() async {
    try {
      setState(() => isLoading = true);

      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('attendance').get();
      Map<String, List<Map<String, dynamic>>> attendanceMap = {};
      Map<String, String> namesMap = {};
      Map<String, int> presentDaysMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String studentId = data['studentId'];
        String status = data['status'];

        if (!namesMap.containsKey(studentId)) {
          DocumentSnapshot studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(studentId)
              .get();
          if (studentDoc.exists) {
            namesMap[studentId] = studentDoc['name'] ?? 'Unknown';
          }
        }

        if (attendanceMap.containsKey(studentId)) {
          attendanceMap[studentId]!.add(data);
        } else {
          attendanceMap[studentId] = [data];
        }

        if (status.toLowerCase() == 'present') {
          presentDaysMap[studentId] = (presentDaysMap[studentId] ?? 0) + 1;
        }
      }

      setState(() {
        studentAttendanceHistory = attendanceMap;
        studentNames = namesMap;
        presentDaysCount = presentDaysMap;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching attendance history: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> exportToExcel() async {
    try {
      setState(() => isLoading = true);

      // Create Excel file
      var excel = Excel.createExcel();
      var sheet = excel['Attendance Records'];

      // Get all unique dates and sort them
      Set<String> allDates = {};
      Map<String, List<Map<String, dynamic>>> dateWiseRecords = {};

      // First, collect all dates and organize records by date
      studentAttendanceHistory.forEach((_, records) {
        for (var record in records) {
          if (record['date'] != null) {
            final timestamp = record['date'] as Timestamp;
            final dateStr = DateFormat('dd-MM-yyyy').format(timestamp.toDate());
            allDates.add(dateStr);

            if (!dateWiseRecords.containsKey(dateStr)) {
              dateWiseRecords[dateStr] = [];
            }
            dateWiseRecords[dateStr]!.add(record);
          }
        }
      });
      var sortedDates = allDates.toList()..sort();

      // Add headers with style
      // First row: Month and Year
      var currentRow = 0;
      var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      cell.value = 'Attendance Report';
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      currentRow++;

      // Second row: Headers
      var headers = [
        'Roll No',
        'Student Name',
        ...sortedDates,
        'Total',
        'Percentage'
      ];
      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }
      currentRow++;

      // Add data
      var studentsList = studentNames.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      for (var student in studentsList) {
        String studentId = student.key;
        String studentName = student.value;

        // Prepare row data
        List<dynamic> rowData = [
          studentId, // Roll No
          studentName, // Student Name
        ];

        // Add status for each date
        int presentCount = 0;
        for (var date in sortedDates) {
          String status = '-';
          var dateRecords = dateWiseRecords[date] ?? [];
          for (var record in dateRecords) {
            if (record['studentId'] == studentId) {
              status =
                  (record['status'] as String? ?? '').toLowerCase() == 'present'
                      ? 'P'
                      : 'A';
              if (status == 'P') presentCount++;
              break;
            }
          }
          rowData.add(status);
        }

        // Calculate percentage
        double percentage = sortedDates.isNotEmpty
            ? (presentCount / sortedDates.length) * 100
            : 0;

        // Add totals
        rowData.addAll([presentCount, '${percentage.toStringAsFixed(0)}%']);

        // Write row data to sheet
        for (var i = 0; i < rowData.length; i++) {
          var cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
          cell.value = rowData[i];

          // Style the cell
          CellStyle style;

          // Add background color for attendance status cells
          if (i >= 2 && i < sortedDates.length + 2) {
            String status = rowData[i].toString();
            if (status == 'P') {
              style = CellStyle(
                horizontalAlign: HorizontalAlign.Center,
                backgroundColorHex: "FFE8F5E9", // Light green
              );
            } else if (status == 'A') {
              style = CellStyle(
                horizontalAlign: HorizontalAlign.Center,
                backgroundColorHex: "FFFFEBEE", // Light red
              );
            } else {
              style = CellStyle(
                horizontalAlign: HorizontalAlign.Center,
              );
            }
          } else {
            style = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
            );
          }

          cell.cellStyle = style;
        }
        currentRow++;
      }

      // Set column widths
      sheet.setColWidth(0, 10); // Roll No
      sheet.setColWidth(1, 30); // Student Name
      for (var i = 2; i < headers.length - 2; i++) {
        sheet.setColWidth(i, 8); // Date columns
      }
      sheet.setColWidth(headers.length - 2, 10); // Total
      sheet.setColWidth(headers.length - 1, 12); // Percentage

      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      const String fileName = 'attendance_report.xlsx';
      final String filePath = '${directory.path}/$fileName';

      // Save the Excel file
      final List<int>? fileBytes = excel.save();
      if (fileBytes == null) {
        throw 'Failed to generate Excel file';
      }

      // Write the file
      File(filePath).writeAsBytesSync(fileBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Attendance Report',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('Error exporting to excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export report'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildStudentAttendanceCard(
      String studentId, List<Map<String, dynamic>> attendanceHistory) {
    String studentName = studentNames[studentId] ?? 'Unknown';
    int presentCount = presentDaysCount[studentId] ?? 0;
    int totalDays = attendanceHistory.length;
    double attendancePercentage =
        totalDays > 0 ? (presentCount / totalDays) * 100 : 0;

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
              child: ExpansionTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      studentName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Attendance: ${attendancePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: attendancePercentage >= 75
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendanceHistory.length,
                    itemBuilder: (context, index) {
                      var record = attendanceHistory[index];
                      bool isPresent =
                          record['status'].toString().toLowerCase() ==
                              'present';
                      return ListTile(
                        leading: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color:
                              isPresent ? AppColors.success : AppColors.error,
                        ),
                        title: Text(
                          record['date'].toDate().toString().split(' ')[0],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: Text(
                          record['status'],
                          style: TextStyle(
                            color:
                                isPresent ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance History',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'View student attendance records',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => exportToExcel(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.download_sharp,
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
                      : studentAttendanceHistory.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No attendance records found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 16),
                              itemCount: studentAttendanceHistory.length,
                              itemBuilder: (context, index) {
                                String studentId = studentAttendanceHistory.keys
                                    .elementAt(index);
                                List<Map<String, dynamic>> attendanceHistory =
                                    studentAttendanceHistory[studentId]!;
                                return _buildStudentAttendanceCard(
                                    studentId, attendanceHistory);
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
}
