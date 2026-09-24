import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/address.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/skeleton.dart';
import '../account/addresses_repository.dart';
import 'checkout_draft.dart';
import 'widgets/address_form_sheet.dart';

/// Saved addresses. In [selectMode] (checkout funnel) tapping one selects it
/// and continues to `/checkout`; otherwise it is the address book from
/// the account menu.
class AddressScreen extends ConsumerWidget {
  const AddressScreen({
    super.key,
    required this.selectMode,
    this.popOnSelect = false,
  });

  final bool selectMode;

  /// True when opened from Checkout's "Change": selecting pops back instead
  /// of pushing a second Checkout.
  final bool popOnSelect;

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Address? existing,
  }) async {
    final saved = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddressFormSheet(existing: existing),
    );
    if (saved != null && selectMode && context.mounted) {
      _select(context, ref, saved);
    }
  }

  void _select(BuildContext context, WidgetRef ref, Address address) {
    ref.read(checkoutDraftProvider.notifier).selectAddress(address);
    if (popOnSelect && context.canPop()) {
      context.pop();
    } else {
      context.push('/checkout');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final selectedId = ref.watch(
      checkoutDraftProvider.select((d) => d.address?.id),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: Text(selectMode ? 'Deliver to' : 'Addresses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add address'),
      ),
      body: addresses.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.location_off_outlined,
                title: 'No saved addresses',
                message: 'Add a delivery address to continue.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(addressesProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    final selected = selectMode && a.id == selectedId;
                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : selectMode
                            ? Icons.radio_button_off
                            : Icons.location_on_outlined,
                      ),
                      title: Row(
                        children: [
                          Flexible(child: Text(a.label)),
                          if (a.isDefault) ...[
                            const SizedBox(width: 8),
                            const Chip(
                              label: Text('Default'),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(a.oneLine),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openForm(context, ref, existing: a),
                      ),
                      onTap: selectMode
                          ? () => _select(context, ref, a)
                          : () => _openForm(context, ref, existing: a),
                    );
                  },
                ),
              ),
        loading: () => const SkeletonList(rows: 3),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(addressesProvider),
        ),
      ),
    );
  }
}
