import 'package:flutter/material.dart';
import 'about.dart';
import 'following.dart';
import 'home.dart';

class FeedTabs extends StatelessWidget {
  const FeedTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SunChat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'About',
              onPressed: () => showAbout(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'For you'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: feedLimit,
              // ignore: prefer_const_constructors
              builder: (context, v, _) => FeedScreen(),
            ),
            const FollowingFeed(),
          ],
        ),
      ),
    );
  }
}
