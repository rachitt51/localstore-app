import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/json.dart';
import '../../core/models/visit.dart';

/// Customer `/visits`: request, list and cancel a home-visit booking.
class VisitsRepository {
  VisitsRepository(this._api);

  final ApiClient _api;

  Future<List<VisitDto>> list() async {
    final body = asJson(await _api.get('/visits'));
    return asJsonList(body['items']).map(VisitDto.fromJson).toList();
  }

  Future<VisitDto> request({
    required DateTime preferredAt,
    String? note,
  }) async => VisitDto.fromJson(
    asJson(
      await _api.post(
        '/visits',
        body: {
          'preferredAt': preferredAt.toUtc().toIso8601String(),
          if (note != null && note.isNotEmpty) 'note': note,
        },
      ),
    ),
  );

  Future<VisitDto> cancel(String id) async =>
      VisitDto.fromJson(asJson(await _api.post('/visits/$id/cancel')));
}

final visitsRepositoryProvider = Provider<VisitsRepository>(
  (ref) => VisitsRepository(ref.watch(apiClientProvider)),
);
