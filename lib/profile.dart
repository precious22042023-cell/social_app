import 'username.dart';
import 'theme.dart';
import 'notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'post_card.dart';
import 'widgets.dart';

Widget _stat(String label, int n) {
  return Column(
    children: [
      Text('$n',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ],
  );
}

class ProfileScreen extends StatelessWidget {
  final String email;
  final bool isTab;
  const ProfileScreen({super.key, required this.email, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nameOf(email)),
        actions: [
          if (isTab)
            IconButton(
              icon: const Icon(Icons.alternate_email),
              tooltip: 'Change username',
              onPressed: () => chooseUsername(context),
            ),
          if (isTab)
            IconButton(
              icon: Icon(Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              tooltip: 'Dark mode',
              onPressed: () => toggleTheme(context),
            ),
          if (isTab)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('user', isEqualTo: email)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = [...snap.data!.docs];
          docs.sort((a, b) {
            final ta = (a.data() as Map<String, dynamic>)['createdAt'];
            final tb = (b.data() as Map<String, dynamic>)['createdAt'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            if (ta is! Timestamp && tb is! Timestamp) return 0;
            return ta is! Timestamp ? -1 : 1;
          });
          return ListView(
            children: [
              _Header(email: email, postCount: docs.length),
              const Divider(),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No posts yet')),
                ),
              ...docs.map((d) => PostCard(key: ValueKey(d.id), doc: d)),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String email;
  final int postCount;
  const _Header({required this.email, required this.postCount});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.email ?? '';
    final isMe = me == email;
    final follows = FirebaseFirestore.instance.collection('follows');
    final ref = follows.doc('${me}_$email');
    return StreamBuilder<QuerySnapshot>(
      stream: follows.where('following', isEqualTo: email).snapshots(),
      builder: (context, a) {
        final followers = a.hasData ? a.data!.docs.length : 0;
        final iFollow =
            a.hasData && a.data!.docs.any((d) => d.id == ref.id);
        return StreamBuilder<QuerySnapshot>(
          stream: follows.where('follower', isEqualTo: email).snapshots(),
          builder: (context, b) {
            final following = b.hasData ? b.data!.docs.length : 0;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                children: [
                  Avatar(email: email, radius: 44),
                  const SizedBox(height: 12),
                  Text(nameOf(email),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  Text(email, style: const TextStyle(color: Colors.grey)),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(email)
                        .snapshots(),
                    builder: (context, u) {
                      final raw = u.hasData ? u.data!.data() : null;
                      final data =
                          raw is Map<String, dynamic> ? raw : <String, dynamic>{};
                      final bio = (data['bio'] ?? '').toString();
                      if (bio.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(bio, textAlign: TextAlign.center),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('Posts', postCount),
                      _stat('Followers', followers),
                      _stat('Following', following),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isMe)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        ),
                        child: const Text('Edit profile'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: iFollow
                          ? OutlinedButton(
                              onPressed: () => ref.delete(),
                              child: const Text('Following'),
                            )
                          : FilledButton(
                              onPressed: () {
                                ref.set({
                                'follower': me,
                                'following': email,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                                notify(to: email, type: 'follow');
                              },
                              child: const Text('Follow'),
                            ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
