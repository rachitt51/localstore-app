import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/address.dart';
import '../../core/models/json.dart';

/// `/me/addresses`.
class AddressesRepository {
  AddressesRepository(this._api);

  final ApiClient _api;

  Future<List<Address>> list() async =>
      asJsonList(await _api.get('/me/addresses'))
          .map(Address.fromJson)
          .toList(growable: false);

  Future<Address> create(Map<String, dynamic> body) async =>
      Address.fromJson(asJson(await _api.post('/me/addresses', body: body)));

  Future<Address> update(String id, Map<String, dynamic> body) async =>
      Address.fromJson(
        asJson(await _api.patch('/me/addresses/$id', body: body)),
      );

  Future<void> delete(String id) => _api.delete('/me/addresses/$id');
}

final addressesRepositoryProvider = Provider<AddressesRepository>(
  (ref) => AddressesRepository(ref.watch(apiClientProvider)),
);

class AddressesNotifier extends AsyncNotifier<List<Address>> {
  @override
  Future<List<Address>> build() => ref.read(addressesRepositoryProvider).list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(ref.read(addressesRepositoryProvider).list);
  }

  Future<Address> save({String? id, required Map<String, dynamic> body}) async {
    final repo = ref.read(addressesRepositoryProvider);
    final saved = id == null
        ? await repo.create(body)
        : await repo.update(id, body);
    // The default flag can move between rows; reload the list.
    state = AsyncData(await repo.list());
    return saved;
  }

  Future<void> delete(String id) async {
    final repo = ref.read(addressesRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await repo.list());
  }
}

final addressesProvider =
    AsyncNotifierProvider.autoDispose<AddressesNotifier, List<Address>>(
      AddressesNotifier.new,
    );
