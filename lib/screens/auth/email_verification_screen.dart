import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _resentSuccessfully = false;
  bool _isSending = false;

  Future<void> _resend() async {
    setState(() { _isSending = true; });
    final auth = context.read<AuthProvider>();
    await auth.resendVerificationEmail();
    if (mounted) {
      setState(() {
        _isSending = false;
        _resentSuccessfully = true;
      });
    }
  }

  Future<void> _checkVerified() async {
    final auth = context.read<AuthProvider>();
    await auth.reloadUser();
    if (mounted && !auth.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not verified yet. Please check your inbox and spam folder.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.accent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Explanation
              Text(
                'A verification link was sent to:\n${auth.userEmail ?? "your email"}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open your email app, find the message from Firebase, and click the verification link. Then come back here and tap "I\'ve Verified".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Success message after resend
              if (_resentSuccessfully)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Email resent! Check your inbox and spam folder.',
                          style: TextStyle(color: AppColors.success, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Error message
              if (auth.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Primary button — I've Verified
              ElevatedButton.icon(
                onPressed: _checkVerified,
                icon: const Icon(Icons.verified_user_outlined, color: Colors.black),
                label: const Text("I've Verified — Continue"),
              ),
              const SizedBox(height: 12),

              // Resend button
              OutlinedButton.icon(
                onPressed: _isSending ? null : _resend,
                icon: _isSending
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, color: AppColors.accent),
                label: Text(
                  _isSending ? 'Sending...' : 'Resend Verification Email',
                  style: const TextStyle(color: AppColors.accent),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign out link
              TextButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: const Text(
                  'Sign out and use a different account',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}