import 'dart:async';

import 'package:flutter/material.dart';

/// Shows a SnackBar with the app's shared hygiene: short-lived, swipe to
/// dismiss, and shown through an explicit [messenger] so it renders in the
/// right Scaffold (pass one scoped to a single Scaffold — a messenger shared
/// by nested Scaffolds, e.g. a tab screen inside a shell, renders the snackbar
/// over the wrong area).
///
/// The framework's own auto-dismiss is tied to the entrance animation
/// completing, which does not fire reliably when the host screen rebuilds
/// often (the storefront rebuilds on every cart/list change). A backup timer
/// closes this exact snackbar after [duration] so it never lingers.
///
/// [bottomInset] lifts it above a screen's own in-body bottom bar (such as the
/// product screen's Buy now / Add to cart row). Screens whose bottom furniture
/// is a NavigationBar leave it at 0: the snackbar already renders above the bar.
void showAppSnackBar(
  ScaffoldMessengerState messenger, {
  required Widget content,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
  double bottomInset = 0,
}) {
  messenger.clearSnackBars();
  final controller = messenger.showSnackBar(
    SnackBar(
      content: content,
      action: action,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
    ),
  );
  Timer(duration + const Duration(milliseconds: 250), () {
    // No-op if the user already dismissed it (swipe, action, or navigation).
    try {
      controller.close();
    } catch (_) {}
  });
}
