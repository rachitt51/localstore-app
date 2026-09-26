import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/visit.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/format.dart';
import '../../../core/ui/skeleton.dart';
import '../../orders/widgets/reason_sheet.dart';
import '../../visits/widgets/visit_status_chip.dart';
import 'owner_visits_notifier.dart';

/// `/owner/visits`: segmented queue of home-visit requests with dense
/// Confirm / Decline actions.
class OwnerVisitsScreen extends ConsumerStatefulWidget {
  const OwnerVisitsScreen({super.key});

  @override
  ConsumerState<OwnerVisitsScreen> createState() => _OwnerVisitsScreenState();
}

class _OwnerVisitsScreenState extends ConsumerState<OwnerVisitsScreen> {
  VisitSegment _segment = VisitSegment.requested;
  String? _busyId;

  void _invalidateAll() {
    for (final s in VisitSegment.values) {
      ref.invalidate(ownerVisitsProvider(s));
    }
  }

  Future<void> _confirm(VisitDto visit) async {
    setState(() => _busyId = visit.id);
    try {
      await ref.read(ownerVisitsProvider(_segment).notifier).confirm(visit.id);
      _invalidateAll();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          ScaffoldMessenger.of(context),
          content: Text(errorMessage(e)),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(VisitDto visit) async {
    final note = await showReasonSheet(
      context,
      title: 'Decline this visit?',
      confirmLabel: 'Decline',
      hint: 'Note for the customer (optional)',
      required: false,
    );
    if (note == null || !mounted) return;
    setState(() => _busyId = visit.id);
    try {
      await ref
          .read(ownerVisitsProvider(_segment).notifier)
          .decline(visit.id, note: note);
      _invalidateAll();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          ScaffoldMessenger.of(context),
          content: Text(errorMessage(e)),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visits = ref.watch(ownerVisitsProvider(_segment));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<VisitSegment>(
              showSelectedIcon: true,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(64, 40),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                side: BorderSide(color: scheme.outline),
                selectedBackgroundColor: scheme.secondaryContainer,
                selectedForegroundColor: scheme.onSecondaryContainer,
              ),
              segments: [
                for (final s in VisitSegment.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {_segment},
              onSelectionChanged: (set) => setState(() => _segment = set.first),
            ),
          ),
        ),
        Expanded(
          child: visits.when(
            data: (items) => items.isEmpty
                ? EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'Nothing here',
                    message: 'No visit requests in "${_segment.label}".',
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(ownerVisitsProvider(_segment).notifier)
                        .refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _VisitCard(
                        visit: items[i],
                        busy: _busyId == items[i].id,
                        onConfirm: _segment == VisitSegment.requested
                            ? () => _confirm(items[i])
                            : null,
                        onDecline: _segment == VisitSegment.requested
                            ? () => _decline(items[i])
                            : null,
                      ),
                    ),
                  ),
            loading: () => const SkeletonList(),
            error: (e, _) => ErrorState(
              error: e,
              onRetry: () => ref.invalidate(ownerVisitsProvider(_segment)),
            ),
          ),
        ),
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.busy,
    required this.onConfirm,
    required this.onDecline,
  });

  final VisitDto visit;
  final bool busy;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;

  static const _dense = Size(64, 40);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.customer?.displayName ?? 'Customer',
                  style: text.titleSmall,
                ),
              ),
              VisitStatusChip(status: visit.status),
            ],
          ),
          if (visit.customer != null)
            Text(
              visit.customer!.phone,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 4),
          Text(formatDateTime(visit.preferredAt), style: text.bodyMedium),
          if (visit.note != null && visit.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              visit.note!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (onConfirm != null || onDecline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onDecline != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onDecline,
                      style: OutlinedButton.styleFrom(
                        minimumSize: _dense,
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                if (onConfirm != null && onDecline != null)
                  const SizedBox(width: 8),
                if (onConfirm != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onConfirm,
                      style: FilledButton.styleFrom(minimumSize: _dense),
                      child: const Text('Confirm'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
