import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  void showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
    );
  }

  Future<void> submit(bool signUp) async {
    setState(() => loading = true);
    try {
      final auth = FirebaseAuth.instance;
      if (signUp) {
        await auth.createUserWithEmailAndPassword(
            email: email.text.trim(), password: password.text);
      } else {
        await auth.signInWithEmailAndPassword(
            email: email.text.trim(), password: password.text);
      }
    } on FirebaseAuthException catch (e) {
      showError('${e.code}: ${e.message}');
    } catch (e) {
      showError('Other error: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bubble_chart, size: 72, color: Color(0xFF5B5BD6)),
              const SizedBox(height: 8),
              const Text('SunChat',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
              const Text('Share what is on your mind',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password (min 6 characters)',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              if (loading)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => submit(false),
                    child: const Text('Log in'),
                  ),
                ),
                TextButton(
                  onPressed: () => submit(true),
                  child: const Text('Create account'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
