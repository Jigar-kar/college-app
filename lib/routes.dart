import 'package:bca_c/components/onbording.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/teacher/teacher_screen.dart';
import 'components/splash_screen.dart';

final routes = {
  '/': (context) => const SplashScreen(),
  '/login' : (context) => const LoginScreen(),
  '/register': (context) =>  const RegistrationScreen(),
  '/admin': (context) => const AdminScreen(),
  '/student_dashboard': (context) => const StudentDashboard(),
  '/teacher': (context) => const TeacherScreen(),
  '/onboard': (context) => const OnBoardingPage()
};
