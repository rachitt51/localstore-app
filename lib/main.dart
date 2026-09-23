import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/auth/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(
    // Failed providers show an ErrorState with a manual retry instead of
    // Riverpod's automatic back-off retries.
    retry: (retryCount, error) => null,
  );
  // Restore the session before the first frame so the router never has to
  // guess (see SessionNotifier.restore).
  await container.read(sessionProvider.notifier).restore();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LocalStoreApp(),
    ),
  );
}
