// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentPDFScreen extends StatefulWidget {
  const StudentPDFScreen({super.key});

  @override
  _StudentPDFScreenState createState() => _StudentPDFScreenState();
}

class _StudentPDFScreenState extends State<StudentPDFScreen> {
  final String repoOwner = "satuababa-bca-1";
  final String repoName = "Statuababa-Bca";
  final String accessToken = "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";
  
  String currentPath = "study_materials";
  List<Map<String, dynamic>> items = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => isLoading = true);

    final url = 'https://api.github.com/repos/$repoOwner/$repoName/contents/$currentPath';

    try {
      final response = await Dio().get(
        url,
        options: Options(
          headers: {
            "Authorization": "Bearer $accessToken",
            "Accept": "application/vnd.github.v3+json",
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          items = (response.data as List<dynamic>)
              .map((item) => {
                    'name': item['name'],
                    'type': item['type'],
                    'path': item['path'],
                    'download_url': item['download_url'],
                  })
              .toList();
        });
      } else {
        _showSnackBar('Failed to fetch items: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Exception: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _downloadAndOpenPDF(String pdfUrl, String fileName) async {
    try {
      setState(() => isLoading = true);
      _showSnackBar('Downloading PDF...');

      final response = await Dio().get(
        pdfUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        if (kIsWeb) {
          await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
          return;
        }

        final directory = Directory.systemTemp;
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          await launchUrl(Uri.file(filePath));
        } else {
          await launchUrl(Uri.file(filePath), mode: LaunchMode.externalApplication);
        }

        _showSnackBar('PDF downloaded successfully!');
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      _showSnackBar('Error downloading PDF: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToFolder(String path) {
    setState(() {
      currentPath = path;
      items = [];
    });
    _fetchItems();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1A237E),
                  size: 28,
                ),
              ),
              const SizedBox(height: 20,),
              const Text(
                "View PDFs",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Browse and view PDFs Which Shered By Your Faculty.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                const Center(child: Text('No items available'))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: kIsWeb ? 9 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: item['type'] == 'dir'
                          ? () => _navigateToFolder(item['path'])
                          : item['name'].endsWith('.pdf')
                              ? () => _downloadAndOpenPDF(item['download_url']!, item['name'])
                              : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: item['type'] == 'dir' ? Colors.amber[100] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['type'] == 'dir'
                                  ? Icons.folder
                                  : Icons.picture_as_pdf,
                              size: 50,
                              color: item['type'] == 'dir' ? Colors.amber : Colors.red,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['name'],
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
  }
}
