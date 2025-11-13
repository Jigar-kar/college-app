import 'package:bca_c/services/GitHubService.dart'; // Import the GitHubService
import 'package:file_picker/file_picker.dart'; // Import the file picker package
import 'package:flutter/material.dart';

class TeacherUploadScreen extends StatefulWidget {
  const TeacherUploadScreen({super.key});

  @override
  _TeacherUploadScreenState createState() => _TeacherUploadScreenState();
}

class _TeacherUploadScreenState extends State<TeacherUploadScreen> {
  bool isLoading = false;
  String? folderTitle;
  List<String> filePaths = [];

  Future<void> uploadFilesToGitHub() async {
    setState(() {
      isLoading = true;
    });

    final gitHubService = GitHubService(
      token: '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',
      username: 'satuababa-bca-1',
      repo: 'Statuababa-Bca',
      folderPath: 'study_materials/$folderTitle',
    );

    try {
      for (String filePath in filePaths) {
        final fileName = filePath.split('/').last;
        await gitHubService.uploadFile(filePath, fileName);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Files uploaded successfully.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to upload one or more files.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
        filePaths.clear();
      });
    }
  }

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        filePaths = result.paths.whereType<String>().toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),

              // Header
              const Text(
                "Upload Study Materials",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Provide folder title, select multiple PDF documents, and upload them to the repository.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Input for Folder Title
              TextField(
                decoration: InputDecoration(
                  labelText: "Folder Title",
                  hintText: "Enter folder name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    folderTitle = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Select Files Button
              ElevatedButton(
                onPressed: folderTitle == null || folderTitle!.isEmpty
                    ? null
                    : pickFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: folderTitle == null || folderTitle!.isEmpty
                      ? Colors.grey
                      : Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_present, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Select Files",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Upload Button
              ElevatedButton(
                onPressed: filePaths.isEmpty
                    ? null
                    : uploadFilesToGitHub,
                style: ElevatedButton.styleFrom(
                  backgroundColor: filePaths.isEmpty ? Colors.grey : Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Upload Files",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Display Selected Files
              if (filePaths.isNotEmpty)
                Column(
                  children: filePaths.map((filePath) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.deepPurple, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Selected File: ${filePath.split('/').last}",
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Loading Indicator
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
