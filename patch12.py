import re

p = 'lib/search.dart'
s = open(p).read()

if "collection('usernames')" in s:
    print('already patched')
    raise SystemExit

new_query = r"""final users = FirebaseFirestore.instance.collection('users');
      final nq = q.startsWith('@') ? q.substring(1) : q;
      final byEmail = await users
          .where('email', isGreaterThanOrEqualTo: nq)
          .where('email', isLessThan: '$nq\uf8ff')
          .limit(20)
          .get();
      final un = await FirebaseFirestore.instance
          .collection('usernames')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: nq)
          .where(FieldPath.documentId, isLessThan: '$nq\uf8ff')
          .limit(10)
          .get();
      final emails = un.docs
          .map((d) => (d.data()['email'] ?? '') as String)
          .where((e) => e.isNotEmpty)
          .toList();
      final byName = emails.isEmpty
          ? null
          : await users.where('email', whereIn: emails).get();
      final seen = <String>{};
      final docs = <QueryDocumentSnapshot>[];
      for (final d in [...?byName?.docs, ...byEmail.docs]) {
        if (seen.add(d.id)) docs.add(d);
      }"""

s, a = re.subn(
    r"final snap = await FirebaseFirestore\.instance\s*\.collection\('users'\)\s*\.where\('email', isGreaterThanOrEqualTo: q\)\s*\.where\('email', isLessThan: '\$q\\uf8ff'\)\s*\.limit\(20\)\s*\.get\(\);",
    lambda m: new_query, s, count=1)

s, b = re.subn(r"results = snap\.docs;", "results = docs;", s, count=1)

# search box color for dark mode
s, c = re.subn(r"fillColor: Colors\.white,", "fillColor: cardColor(context),", s, count=1)
s = s.replace("const InputDecoration(", "InputDecoration(")
if "import 'theme.dart';" not in s:
    s = "import 'theme.dart';\n" + s

print('matches:', a, b, c)
if a and b:
    open(p, 'w').write(s)
    print('patched: lib/search.dart')
else:
    print('NO MATCH (not changed)')
