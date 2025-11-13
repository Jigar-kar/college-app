import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
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
  static const Color warning = Color(0xFFFFA726);
}

enum ClassStatus {
  upcoming,
  ongoing,
  completed
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedClass;
  List<String> classOptions = ['FY', 'SY', 'TY'];
  bool isLoading = true;
  List<Map<String, dynamic>> timetableData = [];

  @override
  void initState() {
    super.initState();
    fetchTimetableData();
  }

  ClassStatus getClassStatus(String startTime, String endTime) {
    // Convert string times to DateTime objects for comparison
    final now = DateTime.now();
    final currentTime = DateTime(now.year, now.month, now.day, 
      int.parse(startTime.split(':')[0]), 
      int.parse(startTime.split(':')[1].split(' ')[0])
    );
    
    final classStart = DateTime(now.year, now.month, now.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1].split(' ')[0])
    );
    
    final classEnd = DateTime(now.year, now.month, now.day,
      int.parse(endTime.split(':')[0]),
      int.parse(endTime.split(':')[1].split(' ')[0])
    );

    if (currentTime.isBefore(classStart)) {
      return ClassStatus.upcoming;
    } else if (currentTime.isAfter(classEnd)) {
      return ClassStatus.completed;
    } else {
      return ClassStatus.ongoing;
    }
  }

  Color getStatusColor(ClassStatus status) {
    switch (status) {
      case ClassStatus.upcoming:
        return AppColors.warning;
      case ClassStatus.ongoing:
        return AppColors.success;
      case ClassStatus.completed:
        return AppColors.error;
    }
  }

  String getStatusText(ClassStatus status) {
    switch (status) {
      case ClassStatus.upcoming:
        return 'Upcoming';
      case ClassStatus.ongoing:
        return 'Ongoing';
      case ClassStatus.completed:
        return 'Completed';
    }
  }

  Future<void> fetchTimetableData() async {
    try {
      setState(() => isLoading = true);

      final now = DateTime.now();
      final weekdays = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ];
      final currentDay = weekdays[now.weekday % 7];

      var query = _firestore
          .collection('timetables')
          .where('day', isEqualTo: currentDay)
          .orderBy('startTime');

      if (_selectedClass != null) {
        query = query.where('class', isEqualTo: _selectedClass);
      }

      final snapshot = await query.get();
      final List<Map<String, dynamic>> data = [];

      for (var doc in snapshot.docs) {
        final classData = doc.data();
        final status = getClassStatus(
          classData['startTime'] as String, 
          classData['endTime'] as String
        );
        
        data.add({
          ...classData,
          'id': doc.id,
          'status': status,
        });
      }

      setState(() {
        timetableData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching timetable: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> exportToExcel() async {
    try {
      setState(() => isLoading = true);

      var excel = Excel.createExcel();
      var sheet = excel['Timetable'];

      // Add headers
      var headers = ['Class', 'Subject', 'Start Time', 'End Time', 'Day'];
      for (var i = 0; i < headers.length; i++) {
        var cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Add data
      for (var i = 0; i < timetableData.length; i++) {
        var data = timetableData[i];
        var rowData = [
          data['class'],
          data['subject'],
          data['startTime'],
          data['endTime'],
          data['day'],
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = rowData[j];
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
          );
        }
      }

      // Set column widths
      for (var i = 0; i < headers.length; i++) {
        sheet.setColWidth(i, 15);
      }

      final directory = await getApplicationDocumentsDirectory();
      const String fileName = 'timetable_report.xlsx';
      final String filePath = '${directory.path}/$fileName';

      final List<int>? fileBytes = excel.save();
      if (fileBytes == null) throw 'Failed to generate Excel file';

      File(filePath).writeAsBytesSync(fileBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Timetable Report',
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

  Widget _buildTimetableCard(Map<String, dynamic> classData) {
    final ClassStatus status = classData['status'] as ClassStatus;
    final Color statusColor = getStatusColor(status);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.2),
            ),
            child: Icon(
              _getSubjectIcon(classData['subject']),
              color: statusColor,
            ),
          ),
          title: Text(
            classData['subject'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '${classData['startTime']} - ${classData['endTime']}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getStatusText(status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          trailing: Text(
            classData['class'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    // Add more subject-icon mappings as needed
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.book;
      case 'computer':
        return Icons.computer;
      default:
        return Icons.subject;
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
                            'Time Table',
                            style: TextStyle(
                              fontSize: 24,
                                    fontWeight: FontWeight.bold,
                              color: Colors.white,
                                  ),
                                ),
                                Text(
                            'View class schedule',
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedClass,
                    hint: const Text('Select Class'),
                    items: classOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedClass = newValue;
                      });
                      fetchTimetableData();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                      : timetableData.isEmpty
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
                                    'No timetable records found',
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
                              itemCount: timetableData.length,
                              itemBuilder: (context, index) {
                                return _buildTimetableCard(
                                    timetableData[index]);
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
