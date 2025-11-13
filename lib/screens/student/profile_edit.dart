import 'package:bca_c/components/loader.dart';
import 'package:bca_c/services/id_card_service.dart';
import 'package:bca_c/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
}

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  _ProfileEditState createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _enrollmentNoController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _parentsContactController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      Map<String, dynamic> userData = await _userService.getStudentInfo();
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _rollNoController.text = userData['rollNo'] ?? '';
        _enrollmentNoController.text = userData['enrollmentNo'] ?? '';
        _mobileNoController.text = userData['mobileNo'] ?? '';
        _classController.text = userData['class'] ?? '';
        _courseController.text = userData['course'] ?? '';
        if (userData['birthDate'] is Timestamp) {
          _birthDateController.text = DateFormat('dd MMM yyyy').format((userData['birthDate'] as Timestamp).toDate());
        } else {
          _birthDateController.text = userData['birthDate'] ?? '';
        }
        _parentsContactController.text = userData['parentsContact'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }

  Widget buildIdCardButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: () async {
          setState(() {
            isLoading = true;
          });
          try {
            Map<String, dynamic> userData = await _userService.getStudentInfo();
            String pdfPath = await IdCardService.generateIdCard(userData);
            await OpenFile.open(pdfPath);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error generating ID card: $e')),
            );
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        },
        icon: const Icon(Icons.badge, color: Colors.white),
        label: const Text('Generate ID Card', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        await _userService.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          rollNo: _rollNoController.text,
          enrollmentNo: _enrollmentNoController.text,
          mobileNo: _mobileNoController.text,
          studentClass: _classController.text,
          course: _courseController.text,
          birthDate: _birthDateController.text,
          parentsContact: _parentsContactController.text,
        );
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }

  Widget buildIdCardButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: () async {
          setState(() {
            isLoading = true;
          });
          try {
            Map<String, dynamic> userData = await _userService.getStudentInfo();
            String pdfPath = await IdCardService.generateIdCard(userData);
            await OpenFile.open(pdfPath);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error generating ID card: $e')),
            );
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        },
        icon: const Icon(Icons.badge, color: Colors.white),
        label: const Text('Generate ID Card', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNoController.dispose();
    _enrollmentNoController.dispose();
    _mobileNoController.dispose();
    _classController.dispose();
    _courseController.dispose();
    _birthDateController.dispose();
    _parentsContactController.dispose();
    super.dispose();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              isLoading
                  ? const Center(child: Loader())
                  : Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField('Name', _nameController, Icons.person),
                            const SizedBox(height: 16),
                            _buildTextField('Email', _emailController, Icons.email, isEmail: true),
                            const SizedBox(height: 16),
                            _buildTextField('Roll No', _rollNoController, Icons.format_list_numbered),
                            const SizedBox(height: 16),
                            _buildTextField('Enrollment No', _enrollmentNoController, Icons.assignment),
                            const SizedBox(height: 16),
                            _buildTextField('Mobile No', _mobileNoController, Icons.phone, isPhone: true),
                            const SizedBox(height: 16),
                            _buildTextField('Parents Contact', _parentsContactController, Icons.phone_android, isPhone: true),
                            const SizedBox(height: 16),
                            _buildTextField('Birth Date', _birthDateController, Icons.cake, isDate: true),
                            const SizedBox(height: 16),
                            _buildTextField('Class', _classController, Icons.class_),
                            const SizedBox(height: 16),
                            _buildTextField('Course', _courseController, Icons.book),
                            const SizedBox(height: 30),
                            _buildUpdateButton(),
                            const SizedBox(height: 16),
                            _buildIdCardButton(),
                        ],
                      ),
                    ),
                  )
            ],
          ),
        ),
      ),
      )
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isEmail = false, bool isPhone = false, bool isDate = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        readOnly: isDate,
        onTap: isDate ? () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: controller.text.isNotEmpty
                ? DateFormat('dd MMM yyyy').parse(controller.text)
                : DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            controller.text = DateFormat('dd MMM yyyy').format(picked);
          }
        } : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.cardBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          prefixIcon: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.primaryColor),
          ),
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Enter your $label';
          }
          if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
            return 'Enter a valid email address';
          }
          if (isPhone && !RegExp(r'^[0-9]{10}$').hasMatch(val)) {
            return 'Enter a valid 10-digit phone number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text('Update Profile', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildIdCardButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: () async {
          setState(() {
            isLoading = true;
          });
          try {
            Map<String, dynamic> userData = await _userService.getStudentInfo();
            String pdfPath = await IdCardService.generateIdCard(userData);
            await OpenFile.open(pdfPath);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error generating ID card: $e')),
            );
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        },
        icon: const Icon(Icons.badge, color: Colors.white),
        label: const Text('Generate ID Card', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
  }

