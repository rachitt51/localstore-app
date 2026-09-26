import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/visit.dart';
import '../../core/ui/app_snackbar.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/format.dart';
import '../../core/ui/skeleton.dart';
import 'visits_notifier.dart';
import 'widgets/visit_status_chip.dart';

/// `/visit`: request a free home visit, then track past requests.
class VisitScreen extends ConsumerStatefulWidget {
  const VisitScreen({super.key});

  @override
  ConsumerState<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends ConsumerState<VisitScreen> {
  final _note = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _busy = false;
  String? _error;
  bool _justRequested = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime? get _preferredAt {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final preferredAt = _preferredAt;
    if (preferredAt == null) {
      setState(() => _error = 'Pick a date and time');
      return;
    }
    if (!preferredAt.isAfter(DateTime.now())) {
      setState(() => _error = 'Pick a time in the future');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(visitsProvider.notifier)
          .request(preferredAt: preferredAt, note: _note.text.trim());
      if (!mounted) return;
      setState(() {
        _justRequested = true;
        _date = null;
        _time = null;
        _note.clear();
      });
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(VisitDto visit) async {
    try {
      await ref.read(visitsProvider.notifier).cancel(visit.id);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        ScaffoldMessenger.of(context),
        content: Text(errorMessage(e)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final visits = ref.watch(visitsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Book a visit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_justRequested)
            _SuccessCard(
              onBookAnother: () => setState(() => _justRequested = false),
            )
          else
            _RequestForm(
              date: _date,
              time: _time,
              note: _note,
              busy: _busy,
              error: _error,
              onPickDate: _pickDate,
              onPickTime: _pickTime,
              onSubmit: _submit,
            ),
          const SizedBox(height: 24),
          Text('Your visit requests', style: text.titleLarge),
          const SizedBox(height: 8),
          visits.when(
            data: (items) => items.isEmpty
                ? const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No visit requests yet',
                    message: 'Book a free home visit above.',
                  )
                : Column(
                    children: [
                      for (final v in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _VisitTile(
                            visit: v,
                            onCancel: v.isCancellable ? () => _cancel(v) : null,
                          ),
                        ),
                    ],
                  ),
            loading: () => const Column(
              children: [
                Skeleton(height: 72, radius: 8),
                SizedBox(height: 8),
                Skeleton(height: 72, radius: 8),
              ],
            ),
            error: (e, _) => ErrorState(
              error: e,
              onRetry: () => ref.invalidate(visitsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.date,
    required this.time,
    required this.note,
    required this.busy,
    required this.error,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSubmit,
  });

  final DateTime? date;
  final TimeOfDay? time;
  final TextEditingController note;
  final bool busy;
  final String? error;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book a free home visit', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Our expert contacts you within 30 minutes. Free consultation, no obligation.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    date == null
                        ? 'Date'
                        : formatDateTime(date!).split(',').first,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(time == null ? 'Time' : time!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Anything we should know before we visit',
              border: OutlineInputBorder(),
            ),
          ),
          InlineError(error),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: Text(busy ? 'Sending…' : 'Request a visit'),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.onBookAnother});

  final VoidCallback onBookAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Visit request sent', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "We'll confirm your visit shortly.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onBookAnother,
            child: const Text('Book another visit'),
          ),
        ],
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit, required this.onCancel});

  final VisitDto visit;
  final VoidCallback? onCancel;

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
                  formatDateTime(visit.preferredAt),
                  style: text.titleSmall,
                ),
              ),
              VisitStatusChip(status: visit.status),
            ],
          ),
          if (visit.note != null && visit.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              visit.note!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (visit.ownerNote != null && visit.ownerNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Store note: ${visit.ownerNote}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
