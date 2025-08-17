import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<UserCredential> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    // Create the user in Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Optionally set display name
    await cred.user?.updateDisplayName(name);

    // Save extra info in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }
}
