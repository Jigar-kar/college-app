// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:bca_c/components/onbording.dart';
import 'package:bca_c/screens/admin/admin_screen.dart';
import 'package:bca_c/screens/student/student_dashboard.dart';
import 'package:bca_c/screens/teacher/teacher_screen.dart';
import 'package:bca_c/screens/visitor/home_screen.dart';
import 'package:bca_c/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _startSplashScreen();
  }

  void _startSplashScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    _navigateBasedOnUserRole();
  }

  Future<void> _navigateBasedOnUserRole() async {
    try {
      User? user = _auth.getCurrentUser();

      if (user != null) {
        String role = await _auth.getUserRole();
        if (role.toLowerCase() == 'student') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const StudentDashboard()));
        } else if (role.toLowerCase() == 'teacher') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const TeacherScreen()));
        } else if (role.toLowerCase() == 'admin') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AdminScreen()));
        } else if (role.toLowerCase() == 'visitor') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          _showError('Unknown role. Please contact admin.');
        }
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const OnBoardingPage()));
      }
    } catch (e) {
      _showError('Error occurred: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const OnBoardingPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 600;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: isWeb
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/logo3.png",
                    alignment: Alignment.center,
                    width: isWeb ? 300 : 300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to \n Satuababa BCA College',
                    textAlign: isWeb ? TextAlign.center : TextAlign.center,
                    style: TextStyle(
                      fontSize: isWeb ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 211, 6, 230)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
