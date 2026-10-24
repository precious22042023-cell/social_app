import 'username.dart';
import 'theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCT6Qf_nzPQQZgjrLGwnJvf1hGHKh7cgM4',
      authDomain: 'social-app-1d7b6.firebaseapp.com',
      projectId: 'social-app-1d7b6',
      storageBucket: 'social-app-1d7b6.firebasestorage.app',
      messagingSenderId: '429204554485',
      appId: '1:429204554485:web:94659f9a8e42966b28bbbc',
    ),
  );
  await loadTheme();
  runApp(const SocialApp());
}

class SocialApp extends StatelessWidget {
  const SocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SunChat',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: mode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return snap.hasData ? const UsernameGate() : const LoginScreen();
        },
      ),
    );
      },
    );
  }
}
