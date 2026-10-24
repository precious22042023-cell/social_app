import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';

final Map<String, String> _byEmail = {};
final ValueNotifier<int> nameVersion = ValueNotifier(0);

String? usernameOf(String email) => _byEmail[email];

Future<void> loadUsernames() async {
  try {
    final s =
        await FirebaseFirestore.instance.collection('usernames').get();
    _byEmail.clear();
    for (final d in s.docs) {
      final e = (d.data()['email'] ?? '') as String;
      if (e.isNotEmpty) _byEmail[e] = d.id;
    }
  } catch (_) {}
}

Future<void> chooseUsername(BuildContext context) async {
  final me = FirebaseAuth.instance.currentUser?.email ?? '';
  final old = usernameOf(me);
  final c = TextEditingController(text: old ?? '');
  String? err;
  await showDialog<void>(
    context: context,
    builder: (dc) => StatefulBuilder(
      builder: (dc2, setLocal) => AlertDialog(
        title: Text(old == null ? 'Choose a username' : 'Change username'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: 'letters, numbers, _',
            prefixText: '@',
            errorText: err,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(old == null ? 'Later' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = c.text.trim().toLowerCase();
              if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(name)) {
                setLocal(() => err = '3-20 letters, numbers or _');
                return;
              }
              if (name == old) {
                Navigator.pop(dc);
                return;
              }
              final col = FirebaseFirestore.instance.collection('usernames');
              final batch = FirebaseFirestore.instance.batch();
              if (old != null) batch.delete(col.doc(old));
              batch.set(col.doc(name), {
                'email': me,
                'createdAt': FieldValue.serverTimestamp(),
              });
              try {
                await batch.commit();
              } catch (e) {
                setLocal(() => err = 'Already taken. Try another');
                return;
              }
              if (dc.mounted) Navigator.pop(dc);
              await loadUsernames();
              nameVersion.value++;
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class UsernameGate extends StatefulWidget {
  const UsernameGate({super.key});

  @override
  State<UsernameGate> createState() => _UsernameGateState();
}

class _UsernameGateState extends State<UsernameGate> {
  bool ready = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await loadUsernames();
    if (!mounted) return;
    setState(() => ready = true);
    final me = FirebaseAuth.instance.currentUser?.email ?? '';
    if (usernameOf(me) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) chooseUsername(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: nameVersion,
      builder: (context, v, _) => ready
          ? HomeShell(key: ValueKey(v))
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
