import 'theme.dart';
import 'notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'images.dart';
import 'profile.dart';
import 'widgets.dart';

class PostScreen extends StatefulWidget {
  final String postId, author, text;
  final String image;
  const PostScreen({
    super.key,
    required this.postId,
    required this.author,
    required this.text,
    this.image = '',
  });

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final controller = TextEditingController();
  String? replyParentId;
  String? replyName;

  CollectionReference get comments => FirebaseFirestore.instance
      .collection('posts')
      .doc(widget.postId)
      .collection('comments');

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final parent = replyParentId;
    controller.clear();
    setState(() {
      replyParentId = null;
      replyName = null;
    });
    try {
      await comments.add({
        'user': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
        'text': text,
        'parentId': parent,
        'createdAt': FieldValue.serverTimestamp(),
      });
      notify(to: widget.author, type: 'comment', postId: widget.postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Comment error: $e')));
      }
    }
  }

  void openProfile(String email) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(email: email)),
    );
  }

  Widget header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => openProfile(widget.author),
                child: Avatar(email: widget.author, radius: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nameOf(widget.author),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    if (widget.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(widget.text,
                          style: const TextStyle(fontSize: 17, height: 1.35)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.image.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: b64Image(widget.image, height: 280),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> deleteComment(QueryDocumentSnapshot d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final me = FirebaseAuth.instance.currentUser?.email ?? '';
      final replies =
          await comments.where('parentId', isEqualTo: d.id).get();
      for (final r in replies.docs) {
        if ((r.data() as Map<String, dynamic>)['user'] == me) {
          await r.reference.delete();
        }
      }
      await d.reference.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete error: $e')));
      }
    }
  }

  Widget tile(QueryDocumentSnapshot d, String topId, bool isReply) {
    final m = d.data() as Map<String, dynamic>;
    final user = (m['user'] ?? '') as String;
    return Padding(
      padding: EdgeInsets.fromLTRB(isReply ? 56 : 16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => openProfile(user),
            child: Avatar(email: user, radius: isReply ? 12 : 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nameOf(user),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(timeAgo(m['createdAt']),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    if (user == FirebaseAuth.instance.currentUser?.email)
                      GestureDetector(
                        onTap: () => deleteComment(d),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.grey),
                      ),
                  ],
                ),
                Text((m['text'] ?? '') as String),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => setState(() {
                    replyParentId = topId;
                    replyName = nameOf(user);
                  }),
                  child: const Text('Reply'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: comments.orderBy('createdAt').snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                final items = <Widget>[header()];
                if (docs.isEmpty) {
                  items.add(const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No comments yet')),
                  ));
                }
                for (final t in docs) {
                  final tm = t.data() as Map<String, dynamic>;
                  if (tm['parentId'] != null) continue;
                  items.add(tile(t, t.id, false));
                  for (final r in docs) {
                    final rm = r.data() as Map<String, dynamic>;
                    if (rm['parentId'] == t.id) {
                      items.add(tile(r, t.id, true));
                    }
                  }
                }
                return ListView(children: items);
              },
            ),
          ),
          if (replyName != null)
            Container(
              color: tintColor(context),
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Expanded(child: Text('Replying to $replyName')),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      replyParentId = null;
                      replyName = null;
                    }),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: replyName == null
                            ? 'Add a comment...'
                            : 'Write a reply...',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
