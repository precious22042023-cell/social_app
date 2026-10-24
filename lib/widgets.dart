import 'username.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

String timeAgo(dynamic ts) {
  if (ts is! Timestamp) return 'now';
  final t = ts.toDate();
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${t.day}/${t.month}/${t.year}';
}

String nameOf(String email) =>
    usernameOf(email) ??
    (email.contains('@') ? email.split('@').first : email);

final Map<String, Future<Uint8List?>> _photoFutures = {};
final ValueNotifier<int> photoVersion = ValueNotifier<int>(0);

Future<Uint8List?> _loadPhoto(String email) async {
  try {
    final d = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .get();
    final data = d.data();
    final p = data == null ? '' : (data['photo'] ?? '').toString();
    if (p.isEmpty) return null;
    return base64Decode(p);
  } catch (e) {
    return null;
  }
}

void refreshPhoto(String email) {
  _photoFutures.remove(email);
  photoVersion.value++;
}

class Avatar extends StatelessWidget {
  final String email;
  final double radius;
  const Avatar({super.key, required this.email, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final sum = email.codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = ((sum * 37) % 360).toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.55, 0.5).toColor();
    final letter = CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        email.isEmpty ? '?' : email[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
    if (email.isEmpty) return letter;
    return ValueListenableBuilder<int>(
      valueListenable: photoVersion,
      builder: (context, v, child) {
        final future =
            _photoFutures.putIfAbsent(email, () => _loadPhoto(email));
        return FutureBuilder<Uint8List?>(
          future: future,
          builder: (context, snap) {
            final bytes = snap.data;
            if (bytes == null) return letter;
            return CircleAvatar(
              radius: radius,
              backgroundColor: color,
              backgroundImage: MemoryImage(bytes),
            );
          },
        );
      },
    );
  }
}
