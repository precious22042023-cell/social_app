import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'post_card.dart';

int _ms(QueryDocumentSnapshot d) {
  final t = (d.data() as Map<String, dynamic>)['createdAt'];
  return t is Timestamp
      ? t.millisecondsSinceEpoch
      : DateTime.now().millisecondsSinceEpoch;
}

class FollowingFeed extends StatefulWidget {
  const FollowingFeed({super.key});

  @override
  State<FollowingFeed> createState() => _FollowingFeedState();
}

class _FollowingFeedState extends State<FollowingFeed> {
  late Future<List<QueryDocumentSnapshot>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<List<QueryDocumentSnapshot>> load() async {
    final me = FirebaseAuth.instance.currentUser?.email ?? '';
    final db = FirebaseFirestore.instance;
    final f = await db
        .collection('follows')
        .where('follower', isEqualTo: me)
        .get();
    final emails = f.docs
        .map((d) => ((d.data())['following'] ?? '') as String)
        .where((e) => e.isNotEmpty)
        .toList();
    final out = <QueryDocumentSnapshot>[];
    for (var i = 0; i < emails.length; i += 10) {
      final end = i + 10 > emails.length ? emails.length : i + 10;
      final s = await db
          .collection('posts')
          .where('user', whereIn: emails.sublist(i, end))
          .get();
      out.addAll(s.docs);
    }
    out.sort((a, b) => _ms(b).compareTo(_ms(a)));
    return out.take(30).toList();
  }

  Future<void> refresh() async {
    final f = load();
    setState(() => future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('Error: ${snap.error}')),
              ),
            ]);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!;
          if (docs.isEmpty) {
            return ListView(children: const [
              Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                  child: Text(
                    'No posts yet.\nFollow people to see their posts here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ]);
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length,
            itemBuilder: (context, i) =>
                PostCard(key: ValueKey(docs[i].id), doc: docs[i]),
          );
        },
      ),
    );
  }
}
