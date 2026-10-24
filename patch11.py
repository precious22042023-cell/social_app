import re

p = 'lib/home.dart'
s = open(p).read()

if 'feedLimit' in s:
    print('already patched')
    raise SystemExit

n = s.count('.limit(30)')
s = s.replace('.limit(30)', '.limit(feedLimit.value)')

s, a = re.subn(r"itemCount: docs\.length \+ 1,",
               "itemCount: docs.length + 2,", s, count=1)

more = """
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
              }"""

s, b = re.subn(
    r"(if \(i == 0\) \{\s*return const StoriesBar\(\);\s*\})",
    lambda m: m.group(1) + more, s, count=1)

s, c = re.subn(
    r"(class HomeShell extends StatefulWidget)",
    lambda m: "final ValueNotifier<int> feedLimit = ValueNotifier(30);\n\n" + m.group(1),
    s, count=1)

print('matches:', n, a, b, c)
if n and a and b and c:
    open(p, 'w').write(s)
    print('patched: lib/home.dart')
else:
    print('NO MATCH (not changed)')
