// ═══════════════════════════════════════════════════════════════════════════════
// FILE: lib/services/auth_service.dart
//
// WHY THIS FILE EXISTS:
//   The Service layer is the ONLY place that talks to Firebase.
//   UI widgets and Providers must NEVER import firebase_auth directly.
//
//   This separation means:
//     - You can swap Firebase for a different backend later without touching UI
//     - Unit tests can mock this service
//     - All error handling is in one place
//
// DATA FLOW:
//   UI calls AuthProvider method
//   → AuthProvider calls AuthService method
//   → AuthService talks to Firebase
//   → Result bubbles back up
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';   // UserModel lives here

class AuthService {
  // ── Private Firebase instances ─────────────────────────────────────────────
  // WHY: We keep references private so only this class can call Firebase directly.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── authStateChanges ───────────────────────────────────────────────────────
  // WHY: Returns a Stream<User?> that emits every time the user signs in or out.
  //      The AuthProvider listens to this stream to know if the user is logged in.
  //
  // HOW STREAMS WORK IN FLUTTER:
  //   A Stream is like a pipe. Data flows through it over time.
  //   StreamBuilder widgets rebuild automatically when new data arrives.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── currentUser ───────────────────────────────────────────────────────────
  // WHY: Quick synchronous access to the currently signed-in user.
  //      Returns null if nobody is signed in.
  // User? get currentUser => _auth.currentUser;
  User? get currentUser => _auth.currentUser;

  // ── signUp ────────────────────────────────────────────────────────────────
  // WHY: Creates a new Firebase Auth account AND a Firestore user document.
  //      We need both because Auth only stores email/password,
  //      but we want to store extra info (displayName) in Firestore.
  //
  // STEP BY STEP:
  //   1. createUserWithEmailAndPassword → Firebase creates the Auth account
  //   2. updateDisplayName → stores the name in the Auth profile
  //   3. sendEmailVerification → sends the confirmation email
  //   4. _createUserDocument → stores extra info in Firestore /users/{uid}
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Step 1: Create Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Step 2: Add display name to Auth profile
    await credential.user!.updateDisplayName(displayName);

    // Step 3: Send verification email – user must click this before accessing app
    await credential.user!.sendEmailVerification();

    // Step 4: Create the /users/{uid} document in Firestore
    await _createUserDocument(credential.user!, displayName);

    return credential;
  }

  // ── _createUserDocument ───────────────────────────────────────────────────
  // WHY: Firebase Auth only stores email + password.
  //      We store a richer profile in Firestore so listings can show who created them.
  //
  // NOTE: set() with SetOptions(merge: true) means:
  //   "Write these fields, but don't delete fields that already exist."
  //   This is safer than set() alone which would overwrite everything.
  Future<void> _createUserDocument(User user, String displayName) async {
    final userModel = UserModel(
      uid:         user.uid,
      email:       user.email ?? '',
      displayName: displayName,
      createdAt:   DateTime.now(),
    );

    await _firestore
        .collection('users')       // Firestore collection named 'users'
        .doc(user.uid)             // Document ID = Firebase Auth UID
        .set(userModel.toMap(), SetOptions(merge: true));
  }

  // ── signIn ────────────────────────────────────────────────────────────────
  // WHY: Signs in with email + password.
  //      We return the UserCredential so the caller can check emailVerified.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── signOut ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── resendVerificationEmail ───────────────────────────────────────────────
  // WHY: Users sometimes miss the verification email. This lets them request
  //      a new one from the "Email not verified" screen.
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // ── reloadUser ────────────────────────────────────────────────────────────
  // WHY: After the user clicks the verification link, we need to reload
  //      the Auth object to see the updated emailVerified = true.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ── getUserProfile ────────────────────────────────────────────────────────
  // WHY: Fetches the Firestore user document for the Settings screen.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Error message helper ──────────────────────────────────────────────────
  // WHY: Firebase throws FirebaseAuthException with cryptic error codes.
  //      This converts them to human-readable messages for the UI.
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}