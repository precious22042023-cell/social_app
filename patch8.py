import re

p = 'lib/post_card.dart'
s = open(p).read()

if 'editPost' in s:
    print('already patched')
    raise SystemExit

method = """  Future<void> editPost(BuildContext context) async {
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

"""

s, a = re.subn(
    r"(  @override\n  Widget build\(BuildContext context\) \{)",
    lambda m: method + m.group(1), s, count=1)

edit_btn = """if (mine)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => editPost(context),
                    ),
                  if (mine)"""

s, b = re.subn(
    r"if \(mine\)(\s*IconButton\(\s*icon: const Icon\(Icons\.delete_outline\))",
    lambda m: edit_btn + m.group(1), s, count=1)

s, c = re.subn(
    r"Text\(timeAgo\(data\['createdAt'\]\),",
    "Text(\n                                timeAgo(data['createdAt']) +\n                                    (data['edited'] == true ? ' · edited' : ''),",
    s, count=1)

print('matches:', a, b, c)
if a and b and c:
    open(p, 'w').write(s)
    print('patched:', p)
else:
    print('NO MATCH (not changed)')
