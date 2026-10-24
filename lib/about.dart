import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

const String _name = 'SunChat';
const String _version = '1.0';
const String _developer = 'Sunil Choudhary';
const String _phone = '9351797012';
const String _email = 'sunilchoudhary03045@gmail.com';
const String _link = 'https://sunchat-93.web.app';

void showAbout(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AboutScreen()),
  );
}

Future<void> _copy(BuildContext c, String text, String label) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (c.mounted) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

Widget _section(BuildContext c, String title, List<Widget> children) {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    decoration: BoxDecoration(
      color: cardColor(c),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor(c)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        ...children,
        const SizedBox(height: 6),
      ],
    ),
  );
}

Widget _contact(BuildContext c, IconData icon, String label, String value) {
  return ListTile(
    leading: Icon(icon, color: Theme.of(c).colorScheme.primary),
    title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    subtitle: Text(value, style: const TextStyle(fontSize: 15)),
    trailing: IconButton(
      icon: const Icon(Icons.copy, size: 20),
      tooltip: 'Copy',
      onPressed: () => _copy(c, value, label),
    ),
  );
}

Widget _term(String head, String body) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(head, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(body, style: const TextStyle(height: 1.4)),
      ],
    ),
  );
}

Widget _feature(BuildContext c, IconData icon, String text) {
  return Chip(
    avatar: Icon(icon, size: 18),
    label: Text(text),
    backgroundColor: tintColor(c),
    side: BorderSide(color: borderColor(c)),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFFD1D1D),
                  Color(0xFFFCB045),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.chat_bubble,
                      size: 34, color: Color(0xFFFD1D1D)),
                ),
                SizedBox(height: 12),
                Text(
                  _name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text('Version $_version',
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 10),
                Text(
                  'Share moments with friends',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          _section(context, 'Features', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _feature(context, Icons.photo_outlined, 'Posts and photos'),
                  _feature(context, Icons.history_toggle_off, 'Stories'),
                  _feature(context, Icons.favorite_border, 'Likes'),
                  _feature(context, Icons.chat_bubble_outline, 'Comments'),
                  _feature(context, Icons.people_outline, 'Follow'),
                  _feature(context, Icons.search, 'Search'),
                  _feature(context, Icons.notifications_none, 'Alerts'),
                  _feature(context, Icons.dark_mode_outlined, 'Dark mode'),
                ],
              ),
            ),
          ]),
          _section(context, 'Developer', [
            ListTile(
              leading: Icon(Icons.code,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Made by',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: const Text(_developer, style: TextStyle(fontSize: 15)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Built with Flutter and Firebase.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ]),
          _section(context, 'Contact and support', [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Need help or found a bug? Get in touch.'),
            ),
            _contact(context, Icons.phone_outlined, 'Phone', _phone),
            _contact(context, Icons.email_outlined, 'Support email', _email),
            _contact(context, Icons.language, 'Website', _link),
          ]),
          _section(context, 'Legal', [
            ExpansionTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Terms of use'),
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _term('1. Acceptance',
                    'By creating an account or using $_name you agree to these terms. If you do not agree, please do not use the app.'),
                _term('2. Your account',
                    'Use a real email address and keep your password safe. You are responsible for everything that happens under your account.'),
                _term('3. Your content',
                    'You own what you post. By posting you allow $_name to store it and show it to other users of the app. Stories are shown for 24 hours.'),
                _term('4. Rules',
                    'Do not post anything illegal, hateful, abusive, sexual, or threatening. Do not post other peoples private information or content that you do not have the right to share. Do not spam or try to break the app.'),
                _term('5. Removal',
                    'The developer may remove content or suspend accounts that break these rules, without notice.'),
                _term('6. No guarantee',
                    'The app is free and provided as it is. It may have bugs, change, or go offline at any time. To the extent allowed by law, the developer is not responsible for lost content or data.'),
                _term('7. Changes',
                    'These terms may be updated. If you keep using the app after a change, you accept the new terms.'),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _term('What we store',
                    'Your email, username, profile photo and bio, posts, photos, stories, comments, likes, follows, and alerts.'),
                _term('Where it is stored',
                    'Your data is stored with Google Firebase. It is not sold and it is not shared with advertisers.'),
                _term('What others can see',
                    'Your username, profile photo, bio, posts, and email address can be seen by other signed-in users, for example in profiles and search.'),
                _term('Delete your data',
                    'To delete your account or data, send a request to $_email.'),
              ],
            ),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: Center(
              child: Text(
                '© 2026 $_developer. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
