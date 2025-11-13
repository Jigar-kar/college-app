// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:bca_c/screens/admin/admin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddTeacher extends StatefulWidget {
  const AddTeacher({super.key});

  @override
  _AddTeacherState createState() => _AddTeacherState();
}

class _AddTeacherState extends State<AddTeacher> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String name = '', email = '', password = '', phoneNumber = '';
  String selectedClasses = '';
  List<String> selectedSubjects = [];
  List<String> subjects = [];
  List<String> classes = ["FY", "SY", "TY"];
  bool isLoadingSubjects = true;
  File? _photo;

  final ImagePicker _picker = ImagePicker();
  
  final String githubToken = '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'; // Use your GitHub token here.
  final String githubRepo = 'Statuababa-Bca'; // Your GitHub repository name.
  final String githubOwner = 'satuababa-bca-1'; // Your GitHub username.
  final String githubBranch = 'user_photo'; // The branch to upload to.

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('subjects').get();
      setState(() {
        subjects = snapshot.docs.map((doc) => doc['name'] as String).toList();
        isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSubjects = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching subjects: $e')),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadPhotoToGitHub(File photo) async {
    final String fileName = 'teacher_photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String fileContent = base64Encode(photo.readAsBytesSync()); // Convert the image to base64.

    final url = Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/contents/$fileName');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $githubToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'message': 'Upload teacher photo',
        'content': fileContent, // The base64 encoded file content.
      }),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final String downloadUrl = responseData['content']['download_url']; // Extract the download URL.
      return downloadUrl;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo to GitHub: ${response.body}')),
      );
      return null;
    }
  }

  Future<void> _addTeacher() async {
    if (_formKey.currentState!.validate()) {
      if (selectedClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one class')),
        );
        return;
      }
      
      if (selectedSubjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one subject')),
        );
        return;
      }
      
      // Detailed debug print statements
      print('Selected Subjects Type: ${selectedSubjects.runtimeType}');
      print('Selected Subjects Length: ${selectedSubjects.length}');
      print('Selected Subjects: $selectedSubjects');
      print('Subjects List: $subjects');
      
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;
        if (user != null) {
          String? photoUrl;

          // Upload photo to GitHub
          if (_photo != null) {
            photoUrl = await _uploadPhotoToGitHub(_photo!);
          }

          // Add teacher details to 'teachers' collection
          await _firestore.collection('teachers').doc(user.uid).set({
            'name': name,
            'email': email,
            'phone': phoneNumber,
            'subject': selectedSubjects,  // Ensure this is a list
            'class': selectedClasses,
            'photoUrl': photoUrl, 
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Add user role to 'users' collection
          await _firestore.collection('users').doc(user.uid).set({
            'email': email,
            'role': 'Teacher',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher added successfully!')),
          );

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const AdminScreen()));

          // Reset form
          setState(() {
            name = '';
            email = '';
            password = '';
            phoneNumber = '';
            selectedSubjects = [];
            selectedClasses = '';
            _photo = null;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.only(right: 330.0),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.deepPurple,
                  size: 28,
                ),
              ),
            ),
            const Text(
              "Add New Teacher",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(label: 'Name', icon: Icons.person, onChanged: (val) => name = val),
                  const SizedBox(height: 16),
                  _buildTextField(label: 'Email', icon: Icons.email, onChanged: (val) => email = val),
                  const SizedBox(height: 16),
                  _buildTextField(
                      label: 'Password', icon: Icons.lock, obscureText: true, onChanged: (val) => password = val),
                  const SizedBox(height: 16),
                  _buildTextField(label: 'Phone No', icon: Icons.phone, onChanged: (val) => phoneNumber = val),
                  const SizedBox(height: 20),
                  _buildMultiSelectFieldForclass(
                    label: 'Classes',
                    items: classes,
                    selectedItems: selectedClasses,
                    onSelectionChanged: (selectedItems) => setState(() => selectedClasses = selectedItems),
                  ),
                  const SizedBox(height: 16),
                  isLoadingSubjects
                      ? const CircularProgressIndicator()
                      : _buildMultiSelectField(
                          label: 'Subjects',
                          items: subjects,
                          selectedItems: selectedSubjects,
                          onSelectionChanged: (selectedItems) => setState(() => selectedSubjects = selectedItems),
                        ),
                  const SizedBox(height: 24),
                  if (_photo != null) ...[
                    const Text('Selected Photo:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _photo!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => setState(() => _photo = null),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Remove Photo", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickPhoto,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    child: const Text("Pick Photo", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addTeacher,
                    child: const Text("Add Teacher"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool obscureText = false,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMultiSelectField({
    required String label,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              bool isSelected = selectedItems.contains(item);
              return FilterChip(
                label: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.deepPurple : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  List<String> updatedSelection = List.from(selectedItems);
                  if (selected) {
                    updatedSelection.add(item);
                  } else {
                    updatedSelection.remove(item);
                  }
                  onSelectionChanged(updatedSelection);
                },
                selectedColor: Colors.deepPurple.withOpacity(0.15),
                checkmarkColor: Colors.deepPurple,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.deepPurple : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedItems.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Please select at least one ${label.toLowerCase()}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildMultiSelectFieldForclass({
    required String label,
    required List<String> items,
    required String selectedItems,
    required Function(String) onSelectionChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              bool isSelected = selectedItems == item;
              return FilterChip(
                label: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.deepPurple : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  if (selected) {
                    onSelectionChanged(item);
                  } else {
                    onSelectionChanged('');
                  }
                },
                selectedColor: Colors.deepPurple.withOpacity(0.15),
                checkmarkColor: Colors.deepPurple,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.deepPurple : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedItems.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Please select a ${label.toLowerCase()}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

}
