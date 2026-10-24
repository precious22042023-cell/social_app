import 'theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'comments.dart';
import 'profile.dart';
import 'widgets.dart';

Future<void> notify({
  required String to,
  required String type,
  String postId = '',
}) async {
  final me = FirebaseAuth.instance.currentUser?.email ?? '';
  if (to.isEmpty || to == me) return;
  final col = FirebaseFirestore.instance.collection('notifications');
  final data = {
    'to': to,
    'from': me,
    'type': type,
    'postId': postId,
    'createdAt': FieldValue.serverTimestamp(),
    'read': false,
  };
  try {
    if (type == 'comment') {
      await col.add(data);
    } else {
      await col.doc('${type}_${postId}_${me}_$to').set(data);
    }
  } catch (_) {}
}

int _ms(QueryDocumentSnapshot d) {
  final t = (d.data() as Map<String, dynamic>)['createdAt'];
  return t is Timestamp
      ? t.millisecondsSinceEpoch
      : DateTime.now().millisecondsSinceEpoch;
}

class NotifIcon extends StatelessWidget {
  final bool selected;
  const NotifIcon({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.email ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('to', isEqualTo: me)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final n = snap.hasData ? snap.data!.docs.length : 0;
        return Badge(
          isLabelVisible: n > 0,
          label: Text('$n'),
          child: Icon(selected
              ? Icons.notifications
              : Icons.notifications_outlined),
        );
      },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String words(String type) {
    if (type == 'like') return 'liked your post';
    if (type == 'comment') return 'commented on your post';
    return 'started following you';
  }

  Future<void> markAll(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final d in docs) {
      final m = d.data() as Map<String, dynamic>;
      if (m['read'] != true) batch.update(d.reference, {'read': true});
    }
    try {
      await batch.commit();
    } catch (_) {}
  }

  Future<void> open(BuildContext context, QueryDocumentSnapshot d) async {
    final m = d.data() as Map<String, dynamic>;
    try {
      await d.reference.update({'read': true});
    } catch (_) {}
    if (!context.mounted) return;
    final type = (m['type'] ?? '') as String;
    if (type == 'follow') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileScreen(email: (m['from'] ?? '') as String)),
      );
      return;
    }
    final p = await FirebaseFirestore.instance
        .collection('posts')
        .doc((m['postId'] ?? '') as String)
        .get();
    if (!context.mounted) return;
    if (!p.exists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Post was deleted')));
      return;
    }
    final pm = p.data()!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostScreen(
          postId: p.id,
          author: (pm['user'] ?? '') as String,
          text: (pm['text'] ?? '') as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.email ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('to', isEqualTo: me)
          .snapshots(),
      builder: (context, snap) {
        final all = snap.hasData ? [...snap.data!.docs] : <QueryDocumentSnapshot>[];
        all.sort((a, b) => _ms(b).compareTo(_ms(a)));
        final docs = all.take(50).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Alerts'),
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Mark all read',
                onPressed: () => markAll(docs),
              ),
            ],
          ),
          body: snap.hasError
              ? Center(child: Text('Error: ${snap.error}'))
              : !snap.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : docs.isEmpty
                      ? const Center(child: Text('No notifications yet'))
                      : ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final d = docs[i];
                            final m = d.data() as Map<String, dynamic>;
                            final from = (m['from'] ?? '') as String;
                            final unread = m['read'] != true;
                            return Container(
                              color: unread
                                  ? tintColor(context)
                                  : Colors.transparent,
                              child: ListTile(
                                leading: Avatar(email: from),
                                title: Text(
                                    '${nameOf(from)} ${words((m['type'] ?? '') as String)}'),
                                subtitle: Text(timeAgo(m['createdAt'])),
                                onTap: () => open(context, d),
                              ),
                            );
                          },
                        ),
        );
      },
    );
  }
}
