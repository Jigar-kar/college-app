import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';  // To access local file system

class GitHubService {
  final String token; // Teacher's GitHub Token
  final String username; // Teacher's GitHub Username
  final String repo; // Repository name
  final String folderPath; // Path to the folder in the repo (e.g., 'study_materials')

  GitHubService({
    required this.token,
    required this.username,
    required this.repo,
    required this.folderPath,
  });

  // Method to upload a PDF file to GitHub
  Future<void> uploadFile(String filePath, String fileName) async {
    // Read the PDF file as base64
    String base64Content = await _readFileAsBase64(filePath);

    // Prepare the API URL
    final url = Uri.parse(
        'https://api.github.com/repos/$username/$repo/contents/$folderPath/$fileName');

    // Prepare the request body
    final body = json.encode({
      'message': 'Add new study material: $fileName',
      'content': base64Content,
    });

    // Make the API request
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // Check for success
    if (response.statusCode == 201) {
      print('File uploaded successfully!');
    } else {
      print('Failed to upload file: ${response.body}');
    }
  }

  // Helper function to read a file as Base64
  Future<String> _readFileAsBase64(String filePath) async {
    final file = File(filePath);
    List<int> bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  fetchStudyMaterials() {}
}
