import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/ui/neo_loading_indicator.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_visual_shell.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.codeAlreadySent = false,
  });

  final String email;
  final bool codeAlreadySent;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _cooldownSeconds = 60;

  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVerifying = false;
  bool _isResending = false;
  bool _hasFreshCode = false;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.codeAlreadySent) {
      _hasFreshCode = true;
      _startCooldown();
    } else {
      _resend(silent: true);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _cooldownRemaining--;
        if (_cooldownRemaining <= 0) timer.cancel();
      });
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isVerifying = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.verifyEmail(
        widget.email,
        _codeController.text.trim(),
      );

      if (!mounted) return;
      ref.read(authStateProvider.notifier).setAuthenticated(user);
      AppSnackbar.success(context, 'E-mail confirmado! Bem-vindo ao VaiJunto.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on DioException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, ApiException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend({bool silent = false}) async {
    setState(() => _isResending = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resendVerificationCode(widget.email);

      if (!mounted) return;
      setState(() => _hasFreshCode = true);
      if (!silent) {
        AppSnackbar.success(
          context,
          'Enviamos um novo código para o seu e-mail.',
        );
      }
      _startCooldown();
    } on DioException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, ApiException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canResend = !_isResending && _cooldownRemaining <= 0;
    final canSubmit = !_isVerifying && _hasFreshCode;

    return AuthVisualShell(
      code: 'VJ//EMAIL_HANDSHAKE',
      title: 'Confirme o sinal',
      description:
          'Use os seis dígitos enviados para provar que este endereço institucional é seu.',
      stepLabel: _hasFreshCode ? 'CÓDIGO ATIVO' : 'SINCRONIZANDO',
      showBack: true,
      content: NeoCard(
        color: scheme.surface,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    color: _hasFreshCode ? scheme.secondary : scheme.tertiary,
                    child: Icon(
                      _hasFreshCode
                          ? Icons.mark_email_read_outlined
                          : Icons.outgoing_mail,
                      color: _hasFreshCode ? Colors.white : NeoBrutal.inkLight,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasFreshCode
                              ? 'DESTINO CONFIRMADO'
                              : 'ABRINDO CANAL',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!_hasFreshCode) ...[
                const Center(
                  child: NeoLoadingIndicator(label: 'ENVIANDO CÓDIGO...'),
                ),
                const SizedBox(height: 18),
              ],
              TextFormField(
                controller: _codeController,
                enabled: _hasFreshCode,
                autofocus: _hasFreshCode,
                decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos',
                  counterText: '',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 23,
                  letterSpacing: 9,
                  fontWeight: FontWeight.w700,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (_) => _verify(),
                validator: (value) => value == null || value.trim().length != 6
                    ? 'Informe os 6 dígitos do código'
                    : null,
              ),
              const SizedBox(height: 16),
              NeoButton(
                onPressed: canSubmit ? _verify : null,
                icon: const Icon(Icons.verified_user_outlined),
                trailing: _isVerifying ? null : const Icon(Icons.check_rounded),
                child: _isVerifying
                    ? const NeoLoadingIndicator(compact: true)
                    : const Text('CONFIRMAR ACESSO'),
              ),
            ],
          ),
        ),
      ),
      afterContent: NeoOutlineButton(
        onPressed: canResend ? () => _resend() : null,
        icon: const Icon(Icons.refresh_rounded),
        child: _isResending
            ? const NeoLoadingIndicator(compact: true)
            : Text(
                _cooldownRemaining > 0
                    ? 'REENVIAR EM ${_cooldownRemaining}s'
                    : 'REENVIAR CÓDIGO',
              ),
      ),
    );
  }
}
