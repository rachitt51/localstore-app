import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/auth/session.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/error_state.dart';

/// Resend cooldown (`OTP_COOLDOWN` on the API is 30 s).
const otpResendCooldown = Duration(seconds: 30);

/// Phone step then OTP step, one route. On success the session becomes
/// signed in and the router redirects to `?from=` (see `redirectFor`).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String? _error;
  String? _devCode;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 ? '+91$digits' : '+$digits';
  }

  bool get _phoneValid {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 ||
        (digits.length == 12 && digits.startsWith('91'));
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = otpResendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _requestOtp() async {
    if (!_phoneValid) {
      setState(() => _error = 'Enter a 10-digit mobile number');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .requestOtp(_normalizedPhone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _devCode = result.devCode;
        // Demo speed: the console provider returns the code; prefill it.
        if (result.devCode != null) _code.text = result.devCode!;
      });
      _startCooldown();
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the code you received');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final tokens = await ref
          .read(authRepositoryProvider)
          .verifyOtp(_normalizedPhone, code);
      await ref.read(sessionProvider.notifier).signIn(tokens);
      // The router's refreshListenable now redirects away from /login.
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Sign in'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _otpSent ? 'Enter the code' : 'Your mobile number',
              style: text.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'We sent a one-time code to $_normalizedPhone.'
                  : 'We will send a one-time code by SMS. No password needed.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (!_otpSent) ...[
              TextField(
                controller: _phone,
                autofocus: true,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _requestOtp(),
              ),
              InlineError(_error),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _requestOtp,
                child: Text(_busy ? 'Sending…' : 'Send code'),
              ),
            ] else ...[
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: text.headlineSmall?.copyWith(letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'One-time code',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _verify(),
              ),
              if (_devCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Dev hint: the code is $_devCode',
                    style: text.bodySmall?.copyWith(color: scheme.tertiary),
                    textAlign: TextAlign.center,
                  ),
                ),
              InlineError(_error),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _verify,
                child: Text(_busy ? 'Verifying…' : 'Verify and continue'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _otpSent = false;
                            _error = null;
                            _code.clear();
                          }),
                    child: const Text('Change number'),
                  ),
                  TextButton(
                    onPressed: _busy || _cooldown > 0 ? null : _requestOtp,
                    child: Text(
                      _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend code',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
