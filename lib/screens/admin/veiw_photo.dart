import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManagePhotosScreen extends StatefulWidget {
  const ManagePhotosScreen({super.key});

  @override
  _ManagePhotosScreenState createState() => _ManagePhotosScreenState();
}

class _ManagePhotosScreenState extends State<ManagePhotosScreen> {
  final String repoOwner = "satuababa-bca-1"; // GitHub username
  final String repoName = "Statuababa-Bca"; // GitHub repository name
  final String accessToken = "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"; // GitHub token

  String currentPath = ""; // Tracks the current folder path
  List<Map<String, dynamic>> items = []; // List of folders/files
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      isLoading = true;
    });

    final url =
        'https://api.github.com/repos/$repoOwner/$repoName/contents/$currentPath';

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
          items = data.map((item) {
            return {
              'name': item['name'] as String,
              'type': item['type'] as String, // 'file' or 'dir'
              'path': item['path'] as String,
              'download_url': item['download_url'] as String?,
            };
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch items: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToFolder(String path) {
    setState(() {
      currentPath = path; // Navigate to the new path
      items = []; // Clear items temporarily
    });
    _fetchItems(); // Fetch items for the new folder
  }

  Future<void> _deletePhoto(String path) async {
    final url =
        'https://api.github.com/repos/$repoOwner/$repoName/contents/$path';

    try {
      final getResponse = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Accept": "application/vnd.github.v3+json",
        },
      );

      if (getResponse.statusCode == 200) {
        final fileInfo = jsonDecode(getResponse.body);
        final fileSha = fileInfo['sha'];

        final deleteResponse = await http.delete(
          Uri.parse(url),
          headers: {
            "Authorization": "Bearer $accessToken",
            "Accept": "application/vnd.github.v3+json",
          },
          body: jsonEncode({
            "message": "Delete photo $path",
            "sha": fileSha,
          }),
        );

        if (deleteResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo deleted successfully!')),
          );
          _fetchItems(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to delete photo: ${deleteResponse.statusCode}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to fetch file info: ${getResponse.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
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
              // Custom Back Button
              currentPath.isEmpty
                  ? const SizedBox.shrink()
                  : InkWell(
                      onTap: () {
                        if (currentPath.contains('/')) {
                          final parentPath = currentPath.substring(0, currentPath.lastIndexOf('/'));
                          _navigateToFolder(parentPath);
                        } else {
                          _navigateToFolder("");
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                    ),
              const SizedBox(height: 20),

              // Header
              const Text(
                "Manage Photos",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Browse and manage folders and photos",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Loading Indicator or Content
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? const Center(child: Text('No items available'))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return item['type'] == 'dir'
                                ? GestureDetector(
                                    onTap: () => _navigateToFolder(item['path']!),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.amber[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.folder, size: 50, color: Colors.amber),
                                          const SizedBox(height: 8),
                                          Text(
                                            item['name'],
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            item['download_url']!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deletePhoto(item['path']!),
                                          ),
                                        ),
                                      ],
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
