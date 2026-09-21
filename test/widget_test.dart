import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:localstore_app/app/app.dart';
import 'package:localstore_app/features/home/home_screen.dart';

void main() {
  testWidgets('home screen shows the API health status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiHealthProvider.overrideWith((ref) async => 'ok')],
        child: const LocalStoreApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LocalStore'), findsOneWidget);
    expect(find.text('API: ok'), findsOneWidget);
  });
}
