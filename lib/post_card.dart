import 'theme.dart';
import 'notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'comments.dart';
import 'images.dart';
import 'profile.dart';
import 'widgets.dart';

class PostCard extends StatelessWidget {
  final DocumentSnapshot doc;
  const PostCard({super.key, required this.doc});

  Future<void> confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
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
      await doc.reference.delete();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete error: $e')));
      }
    }
  }

  Future<void> editPost(BuildContext context) async {
    final data = doc.data() as Map<String, dynamic>;
    final hasImage = ((data['image'] ?? '') as String).isNotEmpty;
    final controller =
        TextEditingController(text: (data['text'] ?? '') as String);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit post'),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final text = controller.text.trim();
    if (text.isEmpty && !hasImage) return;
    if (text == ((data['text'] ?? '') as String)) return;
    try {
      await doc.reference.update({'text': text, 'edited': true});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Edit error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final data = doc.data() as Map<String, dynamic>;
    final author = (data['user'] ?? '') as String;
    final text = (data['text'] ?? '') as String;
    final image = (data['image'] ?? '') as String;
    final likes = List<String>.from(data['likes'] ?? []);
    final liked = likes.contains(me.uid);
    final mine = data['uid'] == me.uid || author == me.email;

    void openPost() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PostScreen(postId: doc.id, author: author, text: text, image: image),
        ),
      );
    }

    void openProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(email: author)),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cardColor(context),
      shape: Border(bottom: BorderSide(color: borderColor(context))),
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: openPost,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: openProfile,
                    child: Row(
                      children: [
                        Avatar(email: author),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nameOf(author),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            Text(
                                timeAgo(data['createdAt']) +
                                    (data['edited'] == true ? ' · edited' : ''),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (mine)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => editPost(context),
                    ),
                  if (mine)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => confirmDelete(context),
                    ),
                ],
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(text,
                      style: const TextStyle(fontSize: 16, height: 1.35)),
                ),
              ],
              if (image.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: b64Image(image, height: 280),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      doc.reference.update({
                      'likes': liked
                          ? FieldValue.arrayRemove([me.uid])
                          : FieldValue.arrayUnion([me.uid]),
                    });
                      if (!liked) {
                        notify(to: author, type: 'like', postId: doc.id);
                      }
                    },
                  ),
                  Text('${likes.length}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('Comments',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
