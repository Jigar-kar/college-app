import 'dart:io';

import 'package:bca_c/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class IdCardService {
  static Future<String> generateIdCard(Map<String, dynamic> userData) async {
    final pdf = pw.Document();
    final ByteData logoBytes = await rootBundle.load('assets/logo3.png');
    final Uint8List logoData = logoBytes.buffer.asUint8List();
    final logo = pw.MemoryImage(logoData);
    final UserService userService = UserService();
    Map<String, dynamic> studentInfo = {};

    try {
      // Fetch student details
      studentInfo = await userService.getStudentInfo();

      // Format birthDate if it's a Timestamp
      if (studentInfo['birthDate'] is Timestamp) {
        studentInfo['birthDate'] = DateFormat('dd MMM yyyy')
            .format((studentInfo['birthDate'] as Timestamp).toDate());
      }
      print('Student Info: $studentInfo');
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 400,
              height: 250,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.black, width: 2),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(10),
                        topRight: pw.Radius.circular(10),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Image(logo, width: 40, height: 40),
                        pw.SizedBox(width: 10),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SMT. L. P. SAVANI',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900,
                              ),
                            ),
                            pw.Text(
                              'BCA COLLEGE PALITANA',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Name: ${userData['name']}', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(height: 5),
                            pw.Text('Enrollment No: ${userData['enrollmentNo']}', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(height: 5),
                            pw.Text('Course: ${userData['course']} (${userData['class']})', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(height: 5),
                            pw.Text('Academic Year: ${DateTime.now().year}-${DateTime.now().year + 1}', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(height: 5),
                            pw.Text('D.O.B: ${studentInfo['birthDate']}', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(height: 5),
                            pw.Text('Mobile No: ${userData['mobileNo']}', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(height: 5),
                          ],
                        ),
                        pw.Spacer(),
                        pw.Column(
                          children: [
                            pw.Container(
                              width: 100,
                              height: 120,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black),
                              ),
                              child: pw.Center(
                                child: pw.Text('Photo'),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Container(
                              width: 80,
                              height: 80,
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: 'Student ID: ${studentInfo['enrollmentNo']}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  pw.Container(
                    alignment: pw.Alignment.bottomRight,
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Principal',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/id_card_${userData['enrollmentNo']}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}