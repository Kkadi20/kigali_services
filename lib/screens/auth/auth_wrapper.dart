import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';
import '../home_screen.dart';

// Routes to the correct screen based on authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watches AuthProvider — rebuilds automatically when auth state changes
    final authProvider = context.watch<AuthProvider>();

    // Show spinner while initial auth state is loading
    if (authProvider.isLoading && authProvider.authUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Route based on auth state
    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    } else if (!authProvider.isEmailVerified) {
      return const EmailVerificationScreen();
    } else {
      return const HomeScreen();
    }
  }
}