import 'theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile.dart';
import 'widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  List<QueryDocumentSnapshot> results = [];
  bool loading = false;
  String error = '';
  int ticket = 0;

  @override
  void initState() {
    super.initState();
    ensureMyDoc();
  }

  Future<void> ensureMyDoc() async {
    final u = FirebaseAuth.instance.currentUser;
    final email = u?.email;
    if (u == null || email == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .set({'email': email, 'uid': u.uid}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> search(String raw) async {
    final q = raw.trim().toLowerCase();
    final my = ++ticket;
    if (q.isEmpty) {
      setState(() {
        results = [];
        loading = false;
        error = '';
      });
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final users = FirebaseFirestore.instance.collection('users');
      final nq = q.startsWith('@') ? q.substring(1) : q;
      final byEmail = await users
          .where('email', isGreaterThanOrEqualTo: nq)
          .where('email', isLessThan: '$nq\uf8ff')
          .limit(20)
          .get();
      final un = await FirebaseFirestore.instance
          .collection('usernames')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: nq)
          .where(FieldPath.documentId, isLessThan: '$nq\uf8ff')
          .limit(10)
          .get();
      final emails = un.docs
          .map((d) => (d.data()['email'] ?? '') as String)
          .where((e) => e.isNotEmpty)
          .toList();
      final byName = emails.isEmpty
          ? null
          : await users.where('email', whereIn: emails).get();
      final seen = <String>{};
      final docs = <QueryDocumentSnapshot>[];
      for (final d in [...?byName?.docs, ...byEmail.docs]) {
        if (seen.add(d.id)) docs.add(d);
      }
      if (my != ticket || !mounted) return;
      setState(() {
        results = docs;
        loading = false;
      });
    } catch (e) {
      if (my != ticket || !mounted) return;
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  Widget body() {
    if (controller.text.trim().isEmpty) {
      return const Center(child: Text('Type a name or email'));
    }
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error.isNotEmpty) {
      return Center(child: Text('Error: $error'));
    }
    if (results.isEmpty) {
      return const Center(child: Text('No people found'));
    }
    return ListView(
      children: [
        for (final d in results)
          Builder(builder: (context) {
            final m = d.data() as Map<String, dynamic>;
            final email = (m['email'] ?? d.id) as String;
            return ListTile(
              leading: Avatar(email: email),
              title: Text(nameOf(email),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(email),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfileScreen(email: email)),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: controller,
              onChanged: search,
              decoration: InputDecoration(
                hintText: 'Search people by email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: body()),
        ],
      ),
    );
  }
}
