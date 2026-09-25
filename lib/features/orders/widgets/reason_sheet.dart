import 'package:flutter/material.dart';

/// Bottom sheet asking for a free-text reason/note. Resolves to the text
/// (possibly empty when not [required]) or null when dismissed.
Future<String?> showReasonSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String hint = 'Reason',
  bool required = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReasonSheet(
      title: title,
      hint: hint,
      confirmLabel: confirmLabel,
      required: required,
    ),
  );
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.required,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final bool required;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (widget.required && value.isEmpty) {
      setState(() => _error = 'A reason is required');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
              const SizedBox(width: 8),
              // The only place `danger-filled` appears: this always confirms
              // a negative action (Reject, Cancel, Mark failed…).
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: _submit,
                child: Text(widget.confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
