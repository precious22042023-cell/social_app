import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'images.dart';
import 'widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final bio = TextEditingController();
  String photo = '';
  bool loading = true;
  bool saving = false;
  late final String email;

  @override
  void initState() {
    super.initState();
    email = FirebaseAuth.instance.currentUser?.email ?? '';
    load();
  }

  @override
  void dispose() {
    bio.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final d = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();
      final data = d.data();
      if (data != null) {
        bio.text = (data['bio'] ?? '').toString();
        photo = (data['photo'] ?? '').toString();
      }
    } catch (e) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> choose() async {
    final img = await pickImageBase64(context, max: 300, quality: 70);
    if (img != null && mounted) setState(() => photo = img);
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'email': email,
        'bio': bio.text.trim(),
        'photo': photo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      refreshPhoto(email);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    }
  }

  Widget preview() {
    if (photo.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 56,
          backgroundImage: MemoryImage(base64Decode(photo)),
        );
      } catch (e) {}
    }
    return Avatar(email: email, radius: 56);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: preview()),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: choose,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Change photo'),
                    ),
                    if (photo.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => photo = ''),
                        child: const Text('Remove'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bio,
                  maxLength: 150,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                saving
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: save,
                        child: const Text('Save'),
                      ),
              ],
            ),
    );
  }
}
