import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';

// Handles all Firebase Auth operations — the only file that talks to Firebase Auth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream that emits whenever the user signs in or out
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Currently signed-in user, null if logged out
  User? get currentUser => _auth.currentUser;

  // Creates Auth account, sends verification email, and saves user to Firestore
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);
    await credential.user!.sendEmailVerification();
    await _createUserDocument(credential.user!, displayName);
    return credential;
  }

  // Saves extra user info to Firestore /users/{uid}
  Future<void> _createUserDocument(User user, String displayName) async {
    final userModel = UserModel(
      uid:         user.uid,
      email:       user.email ?? '',
      displayName: displayName,
      createdAt:   DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap(), SetOptions(merge: true));
  }

  // Signs in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async => await _auth.signOut();

  // Resends the email verification link
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Reloads the Auth user to pick up emailVerified changes
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Fetches the user profile document from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Converts Firebase error codes to readable messages for the UI
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':      return 'No account found with this email.';
      case 'wrong-password':      return 'Incorrect password. Please try again.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'weak-password':       return 'Password must be at least 6 characters.';
      case 'invalid-email':       return 'Please enter a valid email address.';
      case 'too-many-requests':   return 'Too many attempts. Please wait and try again.';
      default:                    return 'An error occurred: ${e.message}';
    }
  }
}