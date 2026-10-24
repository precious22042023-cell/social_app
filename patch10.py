import re

IMP = "import 'username.dart';\n"

def rd(p):
    return open(p).read()

def wr(p, s):
    if IMP not in s:
        s = IMP + s
    open(p, 'w').write(s)

# 1. nameOf uses the username when there is one
p = 'lib/widgets.dart'
s = rd(p)
if 'usernameOf' in s:
    print('widgets.dart: already patched')
else:
    s, a = re.subn(
        r"String nameOf\(String email\) =>\s*email\.contains\('@'\) \? email\.split\('@'\)\.first : email;",
        "String nameOf(String email) =>\n    usernameOf(email) ??\n    (email.contains('@') ? email.split('@').first : email);",
        s, count=1)
    if a:
        wr(p, s)
        print('patched: widgets.dart')
    else:
        print('NO MATCH (not changed): widgets.dart')

# 2. main.dart shows the gate instead of the home screen
p = 'lib/main.dart'
s = rd(p)
if 'UsernameGate' in s:
    print('main.dart: already patched')
else:
    s, a = re.subn(r"const HomeShell\(\)", "const UsernameGate()", s, count=1)
    if a:
        wr(p, s)
        print('patched: main.dart')
    else:
        print('NO MATCH (not changed): main.dart')

# 3. change-username button on the Profile tab
p = 'lib/profile.dart'
s = rd(p)
if 'chooseUsername' in s:
    print('profile.dart: already patched')
else:
    btn = ("if (isTab)\n"
           "            IconButton(\n"
           "              icon: const Icon(Icons.alternate_email),\n"
           "              tooltip: 'Change username',\n"
           "              onPressed: () => chooseUsername(context),\n"
           "            ),\n          ")
    s, a = re.subn(
        r"(if \(isTab\)\s*IconButton\(\s*icon: Icon\(Theme\.of\(context\)\.brightness)",
        lambda m: btn + m.group(1), s, count=1)
    if a:
        wr(p, s)
        print('patched: profile.dart')
    else:
        print('NO MATCH (not changed): profile.dart')
