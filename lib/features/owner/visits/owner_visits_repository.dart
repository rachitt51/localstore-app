import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/json.dart';
import '../../../core/models/visit.dart';

/// `/admin/visits`.
class OwnerVisitsRepository {
  OwnerVisitsRepository(this._api);

  final ApiClient _api;

  Future<List<VisitDto>> list({String? status}) async {
    final body = asJson(
      await _api.get('/admin/visits', query: {'status': status}),
    );
    return asJsonList(body['items']).map(VisitDto.fromJson).toList();
  }

  Future<VisitDto> confirm(String id, {String? note}) async =>
      VisitDto.fromJson(
        asJson(
          await _api.post(
            '/admin/visits/$id/confirm',
            body: {if (note != null && note.isNotEmpty) 'note': note},
          ),
        ),
      );

  Future<VisitDto> decline(String id, {String? note}) async =>
      VisitDto.fromJson(
        asJson(
          await _api.post(
            '/admin/visits/$id/decline',
            body: {if (note != null && note.isNotEmpty) 'note': note},
          ),
        ),
      );
}

final ownerVisitsRepositoryProvider = Provider<OwnerVisitsRepository>(
  (ref) => OwnerVisitsRepository(ref.watch(apiClientProvider)),
);
