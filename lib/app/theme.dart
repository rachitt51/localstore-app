import 'package:flutter/material.dart';

// Placeholder brand colour until the client's branding is confirmed
// (proposal §9.8).
const _seedColor = Color(0xFF2E7D32);

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
  );
}
