import 'package:flutter/material.dart';

import '../core/ui/ls_theme.dart';

export '../core/ui/ls_theme.dart';

// Wood Waves brand: wood-brown primary, gold-adjacent steel secondary kept
// for status contrast, blue-teal success as tertiary, warm cream surfaces.
const lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF5D3A22),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE6D4B8),
  onPrimaryContainer: Color(0xFF2C1810),
  secondary: Color(0xFF3E5C6E),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFD6E4EC),
  onSecondaryContainer: Color(0xFF102530),
  tertiary: Color(0xFF17656E),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFCCEBEE),
  onTertiaryContainer: Color(0xFF002F35),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFFAF6F0),
  onSurface: Color(0xFF1F1B17),
  onSurfaceVariant: Color(0xFF5A4E44),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF4EFE8),
  surfaceContainer: Color(0xFFEFE9E1),
  surfaceContainerHigh: Color(0xFFE9E2D9),
  surfaceContainerHighest: Color(0xFFE2DAD0),
  outline: Color(0xFF857769),
  outlineVariant: Color(0xFFD5CBBF),
  inverseSurface: Color(0xFF34302B),
  onInverseSurface: Color(0xFFF7EFE7),
  inversePrimary: Color(0xFFC9A77D),
  scrim: Color(0xFF000000),
  surfaceTint: Colors.transparent,
);

const darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFC9A77D),
  onPrimary: Color(0xFF2C1810),
  primaryContainer: Color(0xFF4A2C1A),
  onPrimaryContainer: Color(0xFFE6D4B8),
  secondary: Color(0xFFA7C8DA),
  onSecondary: Color(0xFF0C3444),
  secondaryContainer: Color(0xFF264B5C),
  onSecondaryContainer: Color(0xFFD2E6F1),
  tertiary: Color(0xFF7FD3DD),
  onTertiary: Color(0xFF00363C),
  tertiaryContainer: Color(0xFF0B4F57),
  onTertiaryContainer: Color(0xFFB0EEF5),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF17130F),
  onSurface: Color(0xFFECE0D6),
  onSurfaceVariant: Color(0xFFD3C4B6),
  surfaceContainerLowest: Color(0xFF110E0B),
  surfaceContainerLow: Color(0xFF1F1B17),
  surfaceContainer: Color(0xFF231F1A),
  surfaceContainerHigh: Color(0xFF2E2924),
  surfaceContainerHighest: Color(0xFF39332D),
  outline: Color(0xFF9D8E80),
  outlineVariant: Color(0xFF50453B),
  inverseSurface: Color(0xFFECE0D6),
  onInverseSurface: Color(0xFF34302B),
  inversePrimary: Color(0xFF5D3A22),
  scrim: Color(0xFF000000),
  surfaceTint: Colors.transparent,
);

ThemeData lsTheme(ColorScheme s, LsColors ls) {
  const r8 = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );
  const r6 = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
  );
  final text = lsText(s.onSurface);
  return ThemeData(
    useMaterial3: true,
    colorScheme: s,
    scaffoldBackgroundColor: s.surface,
    textTheme: text,
    extensions: [ls],
    // Owner screens wrap in
    // Theme(data: t.copyWith(visualDensity: VisualDensity.compact)).
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: s.surface,
      foregroundColor: s.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge,
      shape: Border(bottom: BorderSide(color: s.outlineVariant)),
    ),
    cardTheme: CardThemeData(
      color: s.surfaceContainerLowest,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: s.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: r8,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: r8,
        side: BorderSide(color: s.outline),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: r8,
        textStyle: text.labelLarge,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: r6,
      side: BorderSide(color: s.outline),
      backgroundColor: s.surfaceContainerLowest,
      selectedColor: s.primaryContainer,
      checkmarkColor: s.onPrimaryContainer,
      labelStyle: text.labelLarge,
      showCheckmark: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: s.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: s.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: s.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: s.primary, width: 2),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(s.surfaceContainerHigh),
      shape: const WidgetStatePropertyAll(r8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: s.surfaceContainer,
      indicatorColor: s.primaryContainer,
      elevation: 0,
      indicatorShape: r8,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: s.surfaceContainerLow,
      showDragHandle: true,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: s.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: r8,
      backgroundColor: s.inverseSurface,
      actionTextColor: s.inversePrimary,
    ),
  );
}

final lightTheme = lsTheme(lightScheme, lightLs);
final darkTheme = lsTheme(darkScheme, darkLs);
