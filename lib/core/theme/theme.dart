import 'package:flutter/material.dart';
const platforms = {'Codeforces': Color(0xffff5c45), 'AtCoder': Color(0xff5c7cfa), 'VNOJ': Color(0xff17a875), 'ChuyênTin': Color(0xfff0a129)};
ThemeData appearance(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final accent = Color(dark ? 0xffff9f0a : 0xffe07400);
  final bg = Color(dark ? 0xff0a0b0e : 0xffecedf0);
  final ink = Color(dark ? 0xfff7f7f5 : 0xff111216);
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
    .copyWith(primary: accent, surface: bg, onSurface: ink, secondary: accent);
  return ThemeData(colorScheme: scheme, scaffoldBackgroundColor: bg, fontFamily: 'Be Vietnam Pro',
    textTheme: const TextTheme(headlineMedium: TextStyle(fontWeight: FontWeight.w800, height:1.25,letterSpacing:-1.4),
      titleLarge: TextStyle(fontSize:20,fontWeight:FontWeight.w700,height:1.4),
      bodyMedium:TextStyle(fontSize:14,height:1.5),labelSmall:TextStyle(fontSize:12,height:1.4)),
    filledButtonTheme: FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:ink,foregroundColor:bg,minimumSize:const Size(44,44))));
}
String clock(DateTime t)=>'${t.hour.toString().padLeft(2,"0")}:${t.minute.toString().padLeft(2,"0")}';
DateTime day(DateTime d,[int offset=0])=>DateTime(d.year,d.month,d.day+offset);
const weekdays=['T2','T3','T4','T5','T6','T7','CN'];
