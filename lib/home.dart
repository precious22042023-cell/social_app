import 'notifications.dart';
import 'feed_tabs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'images.dart';
import 'post_card.dart';
import 'profile.dart';
import 'search.dart';
import 'stories.dart';

final ValueNotifier<int> feedLimit = ValueNotifier(30);

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          const FeedTabs(),
          const SearchScreen(),
          const NotificationsScreen(),
          ProfileScreen(email: me.email ?? '', isTab: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: NotifIcon(selected: false),
            selectedIcon: NotifIcon(selected: true),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  void addPost(BuildContext context) {
    final controller = TextEditingController();
    String? image;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context2, setLocal) => AlertDialog(
          title: const Text('New post'),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                        hintText: "What's on your mind?"),
                  ),
                  if (image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: b64Image(image!, height: 160),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await pickImageBase64(dialogContext);
                        if (picked != null) setLocal(() => image = picked);
                      },
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(
                          image == null ? 'Add photo' : 'Change photo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty || image != null) {
                  final u = FirebaseAuth.instance.currentUser;
                  try {
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .add({
                      'user': u?.email ?? 'Unknown',
                      'uid': u?.uid ?? '',
                      'text': text,
                      'image': image ?? '',
                      'createdAt': FieldValue.serverTimestamp(),
                      'likes': <String>[],
                    });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Post error: $e')),
                      );
                    }
                  }
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => addPost(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(feedLimit.value)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length + 2,
            itemBuilder: (context, i) {
              if (i == 0) {
                return const StoriesBar();
              }
              if (i == docs.length + 1) {
                if (docs.length < feedLimit.value) {
                  return const SizedBox(height: 16);
                }
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton(
                    onPressed: () => feedLimit.value += 30,
                    child: const Text('Load more'),
                  ),
                );
              }
              final d = docs[i - 1];
              return PostCard(key: ValueKey(d.id), doc: d);
            },
          );
        },
      ),
    );
  }
}
