import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session.dart';

enum _AccountAction { signIn, editName, addresses, ownerMode, signOut }

/// Account lives in Home's app bar, not on a screen (demo-v0.md).
class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session.user;
    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (action) => _onSelected(context, ref, action),
      itemBuilder: (context) => [
        if (user == null)
          const PopupMenuItem(
            value: _AccountAction.signIn,
            child: ListTile(leading: Icon(Icons.login), title: Text('Sign in')),
          )
        else ...[
          PopupMenuItem(
            value: _AccountAction.editName,
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.displayName),
              subtitle: Text(user.phone),
            ),
          ),
          const PopupMenuItem(
            value: _AccountAction.addresses,
            child: ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('Addresses'),
            ),
          ),
          if (user.isStaff)
            const PopupMenuItem(
              value: _AccountAction.ownerMode,
              child: ListTile(
                leading: Icon(Icons.storefront),
                title: Text('Owner mode'),
              ),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _AccountAction.signOut,
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign out'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _AccountAction action,
  ) async {
    switch (action) {
      case _AccountAction.signIn:
        context.push('/login?from=${Uri.encodeComponent('/')}');
      case _AccountAction.editName:
        await showDialog<void>(
          context: context,
          builder: (_) => const EditNameDialog(),
        );
      case _AccountAction.addresses:
        context.push('/account/addresses');
      case _AccountAction.ownerMode:
        context.go('/owner');
      case _AccountAction.signOut:
        await ref.read(sessionProvider.notifier).signOut();
        // Leave any signed-in-only screen explicitly (see LoginScreen).
        if (context.mounted) context.go('/');
    }
  }
}

/// `PATCH /me {name}`.
class EditNameDialog extends ConsumerStatefulWidget {
  const EditNameDialog({super.key});

  @override
  ConsumerState<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<EditNameDialog> {
  late final _controller = TextEditingController(
    text: ref.read(sessionProvider).user?.name ?? '',
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).updateName(name);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Name',
          hintText: 'Business or contact name',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
