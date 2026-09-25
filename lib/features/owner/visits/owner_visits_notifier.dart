import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/visit.dart';
import 'owner_visits_repository.dart';

/// Segments of the owner visits queue.
enum VisitSegment {
  requested('Requested', VisitStatus.requested),
  confirmed('Confirmed', VisitStatus.confirmed),
  declined('Declined', VisitStatus.declined);

  const VisitSegment(this.label, this.status);

  final String label;
  final String status;
}

/// One segment of the owner visits queue.
class OwnerVisitsNotifier extends AsyncNotifier<List<VisitDto>> {
  OwnerVisitsNotifier(this.segment);

  final VisitSegment segment;

  @override
  Future<List<VisitDto>> build() =>
      ref.read(ownerVisitsRepositoryProvider).list(status: segment.status);

  Future<void> refresh() async {
    final next = await AsyncValue.guard(
      () =>
          ref.read(ownerVisitsRepositoryProvider).list(status: segment.status),
    );
    if (next.hasValue || !state.hasValue) state = next;
  }

  Future<void> confirm(String id, {String? note}) async {
    await ref.read(ownerVisitsRepositoryProvider).confirm(id, note: note);
    await refresh();
  }

  Future<void> decline(String id, {String? note}) async {
    await ref.read(ownerVisitsRepositoryProvider).decline(id, note: note);
    await refresh();
  }
}

final ownerVisitsProvider = AsyncNotifierProvider.autoDispose
    .family<OwnerVisitsNotifier, List<VisitDto>, VisitSegment>(
      OwnerVisitsNotifier.new,
    );
