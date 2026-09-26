import 'package:flutter/material.dart';

/// Clearance the floating SnackBar needs above a bottom nav bar or a
/// screen's own bottom action bar (`NavigationBar` height 64 + padding, or
/// the Buy now / Add to cart bar), so it never sits over either.
const _snackBarBottomClearance = 84.0;

/// Shows a SnackBar with the app's shared hygiene: short-lived, swipe to
/// dismiss, and clear of the bottom nav bar / bottom action bar so it never
/// blocks taps there. Replaces whatever SnackBar is already showing.
void showAppSnackBar(
  BuildContext context, {
  required Widget content,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: content,
        action: action,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.down,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, _snackBarBottomClearance),
      ),
    );
}
