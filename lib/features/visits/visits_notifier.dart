import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/visit.dart';
import 'visits_repository.dart';

/// The signed-in customer's visit requests, newest first (as the API
/// returns them).
class VisitsNotifier extends AsyncNotifier<List<VisitDto>> {
  @override
  Future<List<VisitDto>> build() => ref.read(visitsRepositoryProvider).list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(ref.read(visitsRepositoryProvider).list);
  }

  Future<VisitDto> request({
    required DateTime preferredAt,
    String? note,
  }) async {
    final visit = await ref
        .read(visitsRepositoryProvider)
        .request(preferredAt: preferredAt, note: note);
    await refresh();
    return visit;
  }

  Future<void> cancel(String id) async {
    await ref.read(visitsRepositoryProvider).cancel(id);
    await refresh();
  }
}

final visitsProvider = AsyncNotifierProvider<VisitsNotifier, List<VisitDto>>(
  VisitsNotifier.new,
);
