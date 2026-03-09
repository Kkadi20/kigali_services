import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'firebase_options.dart';

// App entry point — initializes Firebase then launches the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Firebase project using generated firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KigaliDirectoryApp());
}

class KigaliDirectoryApp extends StatelessWidget {
  const KigaliDirectoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider registers all providers at the root so any widget can access them
    return MultiProvider(
      providers: [
        // Manages authentication state across the whole app
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        // Manages all listings, search, filter, and CRUD operations
        ChangeNotifierProvider<ListingProvider>(create: (_) => ListingProvider()),
      ],
      child: MaterialApp(
        title: 'Kigali Directory',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // AuthWrapper routes to Login or Home based on auth state
        home: const AuthWrapper(),
      ),
    );
  }
}