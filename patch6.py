import re

IMP = "import 'notifications.dart';\n"

def edit(path, fn):
    s = open(path).read()
    s, n = fn(s)
    if n == 0:
        print('NO MATCH (not changed):', path)
        return
    if IMP not in s:
        s = IMP + s
    open(path, 'w').write(s)
    print('patched:', path)

def post_card(s):
    return re.subn(
        r"onPressed: \(\) => doc\.reference\.update\(\{(.*?)\}\),",
        lambda m: "onPressed: () {\n"
        "                      doc.reference.update({" + m.group(1) + "});\n"
        "                      if (!liked) {\n"
        "                        notify(to: author, type: 'like', postId: doc.id);\n"
        "                      }\n"
        "                    },",
        s, count=1, flags=re.S)

def comments(s):
    return re.subn(
        r"(await comments\.add\(\{.*?\}\);)",
        lambda m: m.group(1) + "\n      notify(to: widget.author, type: 'comment', postId: widget.postId);",
        s, count=1, flags=re.S)

def profile(s):
    return re.subn(
        r"onPressed: \(\) => ref\.set\(\{(.*?)\}\),",
        lambda m: "onPressed: () {\n"
        "                                ref.set({" + m.group(1) + "});\n"
        "                                notify(to: email, type: 'follow');\n"
        "                              },",
        s, count=1, flags=re.S)

def home(s):
    if 'NotificationsScreen' in s:
        return s, 0
    s, a = re.subn(
        r"(\n\s*)(ProfileScreen\(email: me\.email \?\? '', isTab: true\),)",
        r"\1const NotificationsScreen(),\1\2", s, count=1)
    s = s.replace("destinations: const [", "destinations: [", 1)
    s, b = re.subn(
        r"(\n\s*)(NavigationDestination\(\s*icon: Icon\(Icons\.person_outline\))",
        r"\1NavigationDestination(\1  icon: NotifIcon(selected: false),\1  selectedIcon: NotifIcon(selected: true),\1  label: 'Alerts',\1),\1\2",
        s, count=1)
    print('home matches:', a, b)
    return s, a * b

edit('lib/post_card.dart', post_card)
edit('lib/comments.dart', comments)
edit('lib/profile.dart', profile)
edit('lib/home.dart', home)
