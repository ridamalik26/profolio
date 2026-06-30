import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase using native config files:
  //   Android: android/app/google-services.json
  //   iOS:     ios/Runner/GoogleService-Info.plist
  // Run: flutterfire configure  (adds these + firebase_options.dart)
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: ProFolioApp()));
}

class ProFolioApp extends ConsumerWidget {
  const ProFolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ProFolio',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

/// Listens to Firebase auth state and routes accordingly.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStream = ref.watch(authStateChangesProvider);

    return authStream.when(
      data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
      loading: () => const _SplashScreen(),
      error: (e, s) => const LoginScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF8B6F47),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.work_outline,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF8B6F47)),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
