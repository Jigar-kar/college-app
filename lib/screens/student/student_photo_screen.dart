// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
}

class StudentPhotoScreen extends StatefulWidget {
  const StudentPhotoScreen({super.key});

  @override
  _StudentPhotoScreenState createState() => _StudentPhotoScreenState();
}

class _StudentPhotoScreenState extends State<StudentPhotoScreen> {
  final String repoOwner = "satuababa-bca-1";
  final String repoName = "Statuababa-Bca";
  final String accessToken = "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";

  String currentPath = "admin";
  List<Map<String, dynamic>> items = [];
  bool isLoading = false;
  String selectedClass = "All";

  final List<String> classes = ["All", "FY", "SY", "TY"];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }
      
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isGranted) {
        return true;
      }
    }
    return false;
  }

  Future<void> _downloadAndSavePhoto(String photoUrl, String fileName) async {
    try {
      // Request permissions to user
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        _showSnackBar('Storage permission is required to download photos');
        return;
      }

      setState(() => isLoading = true);
      _showSnackBar('Downloading photo...');

      final response = await http.get(Uri.parse(photoUrl));
      
      if (response.statusCode == 200) {
        if (kIsWeb) {
          _showSnackBar('Downloads not supported on web platform');
          return;
        }

        final result = await ImageGallerySaver.saveImage(
          response.bodyBytes,
          quality: 100,
          name: fileName,
        );
        
        if (result['isSuccess']) {
          _showSnackBar('Photo saved to gallery successfully!');
        } else {
          throw Exception('Failed to save to gallery');
        }
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      _showSnackBar('Error downloading photo: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  Future<void> _fetchItems() async {
    setState(() => isLoading = true);

    final url = 'https://api.github.com/repos/$repoOwner/$repoName/contents/$currentPath';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Accept": "application/vnd.github.v3+json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          items = data.map((item) => {
            'name': item['name'] as String,
            'type': item['type'] as String,
            'path': item['path'] as String,
            'download_url': item['download_url'] as String?,
          }).toList();

          if (selectedClass != "All") {
            items = items.where((item) {
              return item['path'].toLowerCase().contains(selectedClass.toLowerCase());
            }).toList();
          }
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

  void _navigateToFolder(String path) {
    setState(() {
      currentPath = path;
      items = [];
    });
    _fetchItems();
  }

  Future<void> _previewPhoto(String photoUrl) async {
    if (await canLaunchUrl(Uri.parse(photoUrl))) {
      await launchUrl(
        Uri.parse(photoUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      _showSnackBar('Unable to preview photo. Please try again.');
    }
  }

  Widget _buildClassFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            "Filter by Class:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedClass,
                  isExpanded: true,
                  items: classes.map((String class_) {
                    return DropdownMenuItem<String>(
                      value: class_,
                      child: Text(class_),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedClass = newValue;
                      });
                      _fetchItems();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1A237E),
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "View Photos",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Browse and download photos shared by your faculty.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              _buildClassFilter(),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                const Center(child: Text('No photos available'))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: kIsWeb ? 9 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: item['type'] == 'dir'
                          ? () => _navigateToFolder(item['path'])
                          : () => _previewPhoto(item['download_url']!),
                      child: Container(
                        decoration: BoxDecoration(
                          color: item['type'] == 'dir' ? Colors.amber[100] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item['type'] == 'dir')
                              const Icon(
                                Icons.folder,
                                size: 50,
                                color: Colors.amber,
                              )
                            else
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(11),
                                      ),
                                      child: Image.network(
                                        item['download_url']!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (item['type'] != 'dir')
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.download,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            onPressed: () => _downloadAndSavePhoto(
                                              item['download_url']!,
                                              item['name'],
                                            ),
                                            tooltip: 'Download Photo',
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey),
                                ),
                              ),
                              child: Text(
                                item['name'],
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
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
