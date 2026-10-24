import re, glob

IMP = "import 'theme.dart';\n"

def rd(p):
    return open(p).read()

def wr(p, s):
    if IMP not in s:
        s = IMP + s
    open(p, 'w').write(s)

# 1. main.dart
p = 'lib/main.dart'
s = rd(p)
if 'darkTheme' in s:
    print('main.dart: already patched')
else:
    s, a = re.subn(r"theme: ThemeData\(.*?\n      \),\n      home:",
        "theme: lightTheme(),\n      darkTheme: darkTheme(),\n      themeMode: mode,\n      home:",
        s, count=1, flags=re.S)
    s, b = re.subn(r"return MaterialApp\(",
        "return ValueListenableBuilder<ThemeMode>(\n      valueListenable: themeMode,\n      builder: (context, mode, _) {\n        return MaterialApp(",
        s, count=1)
    s, c = re.subn(r"\n    \);\n  \}\n\}\s*\Z",
        "\n    );\n      },\n    );\n  }\n}\n", s, count=1)
    s, d = re.subn(r"runApp\(const SocialApp\(\)\);",
        "await loadTheme();\n  runApp(const SocialApp());", s, count=1)
    print('main.dart matches:', a, b, c, d)
    if a and b and c and d:
        wr(p, s)
        print('patched: main.dart')
    else:
        print('NO MATCH (not changed): main.dart')

# 2. hard-coded colors
def rep(p, pairs):
    s = rd(p)
    n = 0
    for old, new in pairs:
        n += s.count(old)
        s = s.replace(old, new)
    if n:
        wr(p, s)
        print('patched:', p, '(', n, 'changes )')
    else:
        print('nothing to change:', p)

rep('lib/post_card.dart', [
    ("color: Colors.white,", "color: cardColor(context),"),
    ("side: const BorderSide(color: Color(0xFFE6E8F0))",
     "side: BorderSide(color: borderColor(context))"),
])
rep('lib/comments.dart', [
    ("color: const Color(0xFFE9EAF7),", "color: tintColor(context),"),
])
rep('lib/notifications.dart', [
    ("const Color(0xFFE9EAF7)", "tintColor(context)"),
])

# 3. toggle button on the Profile tab
p = 'lib/profile.dart'
s = rd(p)
if 'toggleTheme' in s:
    print('profile.dart: already patched')
else:
    btn = ("if (isTab)\n"
           "            IconButton(\n"
           "              icon: Icon(Theme.of(context).brightness == Brightness.dark\n"
           "                  ? Icons.light_mode_outlined\n"
           "                  : Icons.dark_mode_outlined),\n"
           "              tooltip: 'Dark mode',\n"
           "              onPressed: () => toggleTheme(context),\n"
           "            ),\n          ")
    s, k = re.subn(
        r"(actions: \[\s*)(if \(isTab\)\s*IconButton\(\s*icon: const Icon\(Icons\.logout\))",
        lambda m: m.group(1) + btn + m.group(2), s, count=1)
    if k:
        wr(p, s)
        print('patched: profile.dart')
    else:
        print('NO MATCH (not changed): profile.dart')

# 4. dim gray text readable on both themes
for f in glob.glob('lib/*.dart'):
    if f.endswith('stories.dart') or f.endswith('theme.dart'):
        continue
    s = rd(f)
    t = s.replace('Colors.black54', 'Colors.grey').replace('Colors.black45', 'Colors.grey')
    if t != s:
        open(f, 'w').write(t)
        print('gray text:', f)
