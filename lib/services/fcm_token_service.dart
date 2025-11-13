import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveAllFCMTokens() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    String? token = await messaging.getToken();
    if (token == null) {
      print("Failed to fetch FCM token.");
      return;
    }

    QuerySnapshot userCollection = await FirebaseFirestore.instance
        .collection('users')
        .where(FirebaseAuth.instance.currentUser!.uid)
        .get();

    for (var doc in userCollection.docs) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .update({'fcmToken': token});
    }

    print("FCM tokens updated for all users successfully!");
  } catch (e) {
    print("Error updating FCM tokens: $e");
  }
}
