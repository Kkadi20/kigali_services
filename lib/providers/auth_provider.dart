import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/listing_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _authUser;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  User?      get authUser       => _authUser;
  UserModel? get userProfile    => _userProfile;
  bool       get isLoading      => _isLoading;
  String?    get errorMessage   => _errorMessage;
  String?    get userEmail      => _authService.currentUser?.email;
  String?    get userId         => _authUser?.uid;
  bool       get isLoggedIn     => _authUser != null;
  bool       get isEmailVerified => _authUser?.emailVerified ?? false;

  AuthProvider() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((User? user) async {
      _authUser = user;
      if (user != null) {
        _userProfile = await _authService.getUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );
      if (!credential.user!.emailVerified) {
        _errorMessage = 'Please verify your email address first.';
        await _authService.signOut();
        _setLoading(false);
        return false;
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> resendVerificationEmail() async {
    _clearError();
    try {
      await _authService.resendVerificationEmail();
    } catch (e) {
      _errorMessage = 'Could not resend email. Try again later.';
      notifyListeners();
    }
  }

  Future<bool> reloadUser() async {
    await _authService.reloadUser();
    _authUser = _authService.currentUser;
    notifyListeners();
    return _authUser?.emailVerified ?? false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() => _clearError();
}