import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:localstore_app/core/models/visit.dart';
import 'package:localstore_app/features/visits/visit_screen.dart';
import 'package:localstore_app/features/visits/visits_repository.dart';

/// In-memory stand-in for `/visits`.
class FakeVisitsRepository implements VisitsRepository {
  final List<VisitDto> _visits = [];
  int requestCalls = 0;
  int cancelCalls = 0;

  @override
  Future<List<VisitDto>> list() async => List.unmodifiable(_visits);

  @override
  Future<VisitDto> request({
    required DateTime preferredAt,
    String? note,
  }) async {
    requestCalls++;
    final visit = VisitDto(
      id: 'v${_visits.length + 1}',
      status: VisitStatus.requested,
      preferredAt: preferredAt,
      note: note,
      createdAt: DateTime.now(),
    );
    _visits.insert(0, visit);
    return visit;
  }

  @override
  Future<VisitDto> cancel(String id) async {
    cancelCalls++;
    final i = _visits.indexWhere((v) => v.id == id);
    final cancelled = VisitDto(
      id: _visits[i].id,
      status: VisitStatus.cancelled,
      preferredAt: _visits[i].preferredAt,
      note: _visits[i].note,
      createdAt: _visits[i].createdAt,
    );
    _visits[i] = cancelled;
    return cancelled;
  }
}

Widget _app(FakeVisitsRepository repo) => ProviderScope(
  retry: (_, _) => null,
  overrides: [visitsRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp.router(
    routerConfig: GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const VisitScreen())],
    ),
  ),
);

void main() {
  testWidgets('no requests yet shows the empty state', (tester) async {
    final repo = FakeVisitsRepository();
    await tester.pumpWidget(_app(repo));
    await tester.pump();

    expect(find.text('No visit requests yet'), findsOneWidget);
    expect(find.text('Request a visit'), findsOneWidget);
  });

  testWidgets('submitting a valid date and time shows the success card', (
    tester,
  ) async {
    final repo = FakeVisitsRepository();
    await tester.pumpWidget(_app(repo));
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Date'));
    await tester.pumpAndSettle();
    // Pick tomorrow so the combined date+time is always in the future,
    // regardless of what time of day the suite runs.
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.text('${tomorrow.day}').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Request a visit'));
    await tester.pumpAndSettle();

    expect(repo.requestCalls, 1);
    expect(find.text('Visit request sent'), findsOneWidget);
  });

  testWidgets('an existing request can be cancelled', (tester) async {
    final repo = FakeVisitsRepository();
    await repo.request(
      preferredAt: DateTime.now().add(const Duration(days: 1)),
      note: 'Ground floor site',
    );
    await tester.pumpWidget(_app(repo));
    await tester.pump();

    expect(find.text('Requested'), findsOneWidget);
    expect(find.text('Ground floor site'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.cancelCalls, 1);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });
}
