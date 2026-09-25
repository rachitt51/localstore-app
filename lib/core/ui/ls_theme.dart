import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LocalStore Design System roles that Material 3 has no slot for
/// (success, warning, neutral, owner mode, ply placeholder), verbatim from
/// the design system's `flutter.md`.
@immutable
class LsColors extends ThemeExtension<LsColors> {
  const LsColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.neutralContainer,
    required this.onNeutralContainer,
    required this.ownerBar,
    required this.onOwnerBar,
    required this.ownerAccent,
    required this.onOwnerAccent,
    required this.ply1,
    required this.ply2,
    required this.plyInk,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color neutralContainer;
  final Color onNeutralContainer;
  final Color ownerBar;
  final Color onOwnerBar;
  final Color ownerAccent;
  final Color onOwnerAccent;
  final Color ply1;
  final Color ply2;
  final Color plyInk;

  @override
  LsColors copyWith() => LsColors(
    success: success,
    onSuccess: onSuccess,
    successContainer: successContainer,
    onSuccessContainer: onSuccessContainer,
    warning: warning,
    onWarning: onWarning,
    warningContainer: warningContainer,
    onWarningContainer: onWarningContainer,
    neutralContainer: neutralContainer,
    onNeutralContainer: onNeutralContainer,
    ownerBar: ownerBar,
    onOwnerBar: onOwnerBar,
    ownerAccent: ownerAccent,
    onOwnerAccent: onOwnerAccent,
    ply1: ply1,
    ply2: ply2,
    plyInk: plyInk,
  );

  @override
  LsColors lerp(ThemeExtension<LsColors>? other, double t) {
    if (other is! LsColors) return this;
    final o = other;
    return LsColors(
      success: Color.lerp(success, o.success, t)!,
      onSuccess: Color.lerp(onSuccess, o.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, o.successContainer, t)!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        o.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, o.warning, t)!,
      onWarning: Color.lerp(onWarning, o.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, o.warningContainer, t)!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        o.onWarningContainer,
        t,
      )!,
      neutralContainer: Color.lerp(neutralContainer, o.neutralContainer, t)!,
      onNeutralContainer: Color.lerp(
        onNeutralContainer,
        o.onNeutralContainer,
        t,
      )!,
      ownerBar: Color.lerp(ownerBar, o.ownerBar, t)!,
      onOwnerBar: Color.lerp(onOwnerBar, o.onOwnerBar, t)!,
      ownerAccent: Color.lerp(ownerAccent, o.ownerAccent, t)!,
      onOwnerAccent: Color.lerp(onOwnerAccent, o.onOwnerAccent, t)!,
      ply1: Color.lerp(ply1, o.ply1, t)!,
      ply2: Color.lerp(ply2, o.ply2, t)!,
      plyInk: Color.lerp(plyInk, o.plyInk, t)!,
    );
  }
}

const lightLs = LsColors(
  success: Color(0xFF17656E),
  onSuccess: Color(0xFFFFFFFF),
  successContainer: Color(0xFFCCEBEE),
  onSuccessContainer: Color(0xFF002F35),
  warning: Color(0xFF8A5300),
  onWarning: Color(0xFFFFFFFF),
  warningContainer: Color(0xFFFBE3BD),
  onWarningContainer: Color(0xFF3A2300),
  neutralContainer: Color(0xFFE9E4DD),
  onNeutralContainer: Color(0xFF3B3632),
  ownerBar: Color(0xFF2B3338),
  onOwnerBar: Color(0xFFF1F4F6),
  // Wood Waves site gold.
  ownerAccent: Color(0xFFC9A84C),
  onOwnerAccent: Color(0xFF2B2000),
  ply1: Color(0xFFEADFCF),
  ply2: Color(0xFFDCCBB3),
  plyInk: Color(0xFF6E5A45),
);

const darkLs = LsColors(
  success: Color(0xFF7FD3DD),
  onSuccess: Color(0xFF00363C),
  successContainer: Color(0xFF0B4F57),
  onSuccessContainer: Color(0xFFB0EEF5),
  warning: Color(0xFFFFBA5C),
  onWarning: Color(0xFF472A00),
  warningContainer: Color(0xFF6A3F00),
  onWarningContainer: Color(0xFFFFDDB5),
  neutralContainer: Color(0xFF3A3530),
  onNeutralContainer: Color(0xFFE6DED6),
  ownerBar: Color(0xFF242C31),
  onOwnerBar: Color(0xFFE3E9EC),
  ownerAccent: Color(0xFFC9A84C),
  onOwnerAccent: Color(0xFF2B2000),
  ply1: Color(0xFF2A241E),
  ply2: Color(0xFF352D25),
  plyInk: Color(0xFFB9A48C),
);

/// The theme's [LsColors], falling back by brightness so widgets render
/// under plain test themes too.
LsColors lsColorsOf(ThemeData theme) =>
    theme.extension<LsColors>() ??
    (theme.brightness == Brightness.dark ? darkLs : lightLs);

const _tnum = [FontFeature.tabularFigures()];

TextTheme lsText(Color ink) {
  // Wood Waves brand type: Playfair Display for display type, Plus Jakarta
  // Sans for body and labels. Prices keep IBM Plex Sans (see lsPrice below).
  final display = GoogleFonts.playfairDisplay;
  final sans = GoogleFonts.plusJakartaSans;
  return TextTheme(
    headlineSmall: display(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.24,
    ),
    titleLarge: display(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: sans(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: sans(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: sans(fontSize: 16, height: 24 / 16),
    bodyMedium: sans(fontSize: 14, height: 20 / 14),
    bodySmall: sans(fontSize: 12, height: 16 / 12),
    labelLarge: sans(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.14,
    ),
    labelMedium: sans(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.12,
    ),
    labelSmall: sans(
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.66,
    ),
  ).apply(bodyColor: ink, displayColor: ink);
}

/// PriceText styles: size xl 28/34 w700, lg 20/26 w700, md 16/22 w700,
/// sm 14/20 w600, unit 12/16 w500.
TextStyle lsPrice(double size, double height, FontWeight w) =>
    GoogleFonts.ibmPlexSans(
      fontSize: size,
      height: height / size,
      fontWeight: w,
      fontFeatures: _tnum,
    );
