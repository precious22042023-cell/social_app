import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'images.dart';
import 'widgets.dart';

int _millis(QueryDocumentSnapshot d) {
  final t = (d.data() as Map<String, dynamic>)['createdAt'];
  return t is Timestamp
      ? t.millisecondsSinceEpoch
      : DateTime.now().millisecondsSinceEpoch;
}

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  late final Stream<QuerySnapshot> stream;

  @override
  void initState() {
    super.initState();
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    stream = FirebaseFirestore.instance
        .collection('stories')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .snapshots();
  }

  Future<void> addStory() async {
    final data = await pickImageBase64(context);
    if (data == null || !mounted) return;
    final caption = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Share to your story'),
        content: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: b64Image(data, height: 220),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caption,
                  maxLength: 100,
                  decoration: const InputDecoration(
                      hintText: 'Add a caption (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final u = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('stories').add({
        'user': u?.email ?? 'Unknown',
        'uid': u?.uid ?? '',
        'image': data,
        'caption': caption.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Story error: $e')));
      }
    }
  }

  void open(List<QueryDocumentSnapshot> list) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewer(stories: list)),
    );
  }

  Widget bubble({
    required String label,
    required String email,
    required bool ring,
    required VoidCallback onTap,
    VoidCallback? onPlus,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ring
                          ? const Color(0xFF5B5BD6)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: Avatar(email: email, radius: 26),
                ),
                if (onPlus != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: onPlus,
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Color(0xFF5B5BD6),
                        child: Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final byUser = <String, List<QueryDocumentSnapshot>>{};
          if (snap.hasData) {
            for (final d in snap.data!.docs) {
              final m = d.data() as Map<String, dynamic>;
              final u = (m['user'] ?? '') as String;
              byUser.putIfAbsent(u, () => []).add(d);
            }
          }
          for (final l in byUser.values) {
            l.sort((a, b) => _millis(a).compareTo(_millis(b)));
          }
          final me = FirebaseAuth.instance.currentUser?.email ?? '';
          final others = byUser.keys.where((k) => k != me).toList();
          final mine = byUser[me];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              bubble(
                label: 'Your story',
                email: me,
                ring: mine != null,
                onTap: () {
                  if (mine == null) {
                    addStory();
                  } else {
                    open(mine);
                  }
                },
                onPlus: addStory,
              ),
              for (final u in others)
                bubble(
                  label: nameOf(u),
                  email: u,
                  ring: true,
                  onTap: () => open(byUser[u]!),
                ),
            ],
          );
        },
      ),
    );
  }
}

class StoryViewer extends StatefulWidget {
  final List<QueryDocumentSnapshot> stories;
  const StoryViewer({super.key, required this.stories});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  int i = 0;

  void next() {
    if (i < widget.stories.length - 1) {
      setState(() => i++);
    } else {
      Navigator.pop(context);
    }
  }

  void prev() {
    if (i > 0) setState(() => i--);
  }

  Future<void> deleteStory() async {
    try {
      await widget.stories[i].reference.delete();
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.stories[i].data() as Map<String, dynamic>;
    final user = (d['user'] ?? '') as String;
    final caption = (d['caption'] ?? '') as String;
    final image = (d['image'] ?? '') as String;
    final mine = user == FirebaseAuth.instance.currentUser?.email;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final w = MediaQuery.of(context).size.width;
                  if (details.localPosition.dx < w / 3) {
                    prev();
                  } else {
                    next();
                  }
                },
                child: Center(child: b64Image(image, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var k = 0; k < widget.stories.length; k++)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: k <= i ? Colors.white : Colors.white30,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Avatar(email: user, radius: 16),
                      const SizedBox(width: 8),
                      Text(nameOf(user),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(timeAgo(d['createdAt']),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      if (mine)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white),
                          onPressed: deleteStory,
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (caption.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
