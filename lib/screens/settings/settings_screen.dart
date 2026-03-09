import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_theme.dart';

// User profile, preferences, and sign out
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification toggle — local UI simulation
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user    = authProvider.authUser;
    final profile = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card showing avatar, display name, email, and verification badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                // Avatar with first letter of name
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  child: Text(
                    (profile?.displayName.isNotEmpty == true
                            ? profile!.displayName[0]
                            : user?.email?[0] ?? 'U')
                        .toUpperCase(),
                    style: const TextStyle(color: AppColors.accent,
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? user?.displayName ?? 'User',
                        style: const TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      // Verified badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('✓ Email Verified',
                            style: TextStyle(
                                color: AppColors.success, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            const Text('Preferences',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12,
                    fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            // Notification toggle — simulated, no real push notifications
            Container(
              decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined,
                    color: AppColors.accent),
                title: const Text('Location Notifications',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                  _notificationsEnabled
                      ? 'Notified about nearby services'
                      : 'Notifications disabled',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(value
                          ? 'Location notifications enabled'
                          : 'Location notifications disabled'),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  activeColor: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // App version info
            Container(
              decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12)),
              child: const ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.textMuted),
                title: Text('App Version',
                    style: TextStyle(color: AppColors.textPrimary)),
                trailing: Text('1.0.0',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Account',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12,
                    fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            // Sign out with confirmation dialog
            Container(
              decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Sign Out',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Sign Out',
                          style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text('Are you sure you want to sign out?',
                          style: TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    // AuthWrapper automatically navigates to LoginScreen on signout
                    await context.read<AuthProvider>().signOut();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}