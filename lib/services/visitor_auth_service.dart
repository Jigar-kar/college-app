import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisitorAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> registerVisitor({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? purpose,
  }) async {
    try {
      // Create auth user
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': 'visitor',
      });

      // Create visitor profile
      await _firestore
          .collection('visitors')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'phone': phone,
        'purpose': purpose,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Registration successful',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this email';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> loginVisitor({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if visitor profile exists and is active
      final visitorDoc = await _firestore
          .collection('visitors')
          .doc(userCredential.user!.uid)
          .get();

      if (!visitorDoc.exists || visitorDoc.data()?['status'] != 'active') {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Visitor account not found or inactive',
        };
      }

      return {
        'success': true,
        'user': userCredential.user,
        'profile': visitorDoc.data(),
        'message': 'Login successful',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getCurrentVisitor() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final visitorDoc =
        await _firestore.collection('visitors').doc(user.uid).get();

    if (!visitorDoc.exists) return null;

    return {
      'uid': user.uid,
      ...visitorDoc.data()!,
    };
  }
}
