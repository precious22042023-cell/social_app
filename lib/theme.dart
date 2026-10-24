import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color igBlue = Color(0xFF0095F6);

final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

Future<void> loadTheme() async {
  try {
    final p = await SharedPreferences.getInstance();
    final v = p.getString('theme');
    if (v == 'dark') themeMode.value = ThemeMode.dark;
    if (v == 'light') themeMode.value = ThemeMode.light;
  } catch (_) {}
}

Future<void> toggleTheme(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', isDark ? 'light' : 'dark');
  } catch (_) {}
}

bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color cardColor(BuildContext c) =>
    _dark(c) ? const Color(0xFF000000) : Colors.white;

Color borderColor(BuildContext c) =>
    _dark(c) ? const Color(0xFF262626) : const Color(0xFFDBDBDB);

Color tintColor(BuildContext c) =>
    _dark(c) ? const Color(0xFF1C1C1C) : const Color(0xFFEFEFEF);

ThemeData _build(Brightness b) {
  final dark = b == Brightness.dark;
  final bg = dark ? Colors.black : Colors.white;
  final text = dark ? const Color(0xFFFAFAFA) : const Color(0xFF262626);
  final line = dark ? const Color(0xFF262626) : const Color(0xFFDBDBDB);
  final scheme = ColorScheme.fromSeed(seedColor: igBlue, brightness: b)
      .copyWith(
    primary: igBlue,
    onPrimary: Colors.white,
    surface: bg,
    onSurface: text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: text,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: bg,
      selectedItemColor: text,
      unselectedItemColor: Colors.grey,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(color: line, thickness: 0.5),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: igBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: igBlue,
      foregroundColor: Colors.white,
    ),
  );
}

ThemeData lightTheme() => _build(Brightness.light);
ThemeData darkTheme() => _build(Brightness.dark);
