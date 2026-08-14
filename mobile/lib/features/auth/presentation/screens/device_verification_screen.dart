import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/ui/neo_loading_indicator.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_visual_shell.dart';

/// MFA de primeiro acesso: device desconhecido pro backend precisa confirmar
/// o código enviado por e-mail antes de receber a sessão de verdade. Mesmo
/// padrão visual/UX de [VerifyEmailScreen] (irmã deste fluxo), só trocando
/// email+código de cadastro por challengeToken+código de login.
class DeviceVerificationScreen extends ConsumerStatefulWidget {
  const DeviceVerificationScreen({super.key, required this.challengeToken});

  final String challengeToken;

  @override
  ConsumerState<DeviceVerificationScreen> createState() =>
      _DeviceVerificationScreenState();
}

class _DeviceVerificationScreenState
    extends ConsumerState<DeviceVerificationScreen> {
  static const _cooldownSeconds = 60;

  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVerifying = false;
  bool _isResending = false;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
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
      final user = await repository.verifyDevice(
        widget.challengeToken,
        _codeController.text.trim(),
      );

      if (!mounted) return;
      ref.read(authStateProvider.notifier).setAuthenticated(user);
      AppSnackbar.success(
        context,
        'Dispositivo confirmado! Bem-vindo de volta.',
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on DioException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, ApiException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resendDeviceCode(widget.challengeToken);

      if (!mounted) return;
      AppSnackbar.success(
        context,
        'Enviamos um novo código para o seu e-mail.',
      );
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

    return AuthVisualShell(
      code: 'VJ//DEVICE_HANDSHAKE',
      title: 'Confirme o dispositivo',
      description:
          'Este é o primeiro acesso neste dispositivo. Digite o código de seis '
          'dígitos enviado para o seu e-mail institucional.',
      stepLabel: 'CÓDIGO ENVIADO',
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
                    color: scheme.secondary,
                    child: const Icon(
                      Icons.phonelink_lock_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'DISPOSITIVO AINDA NÃO VERIFICADO',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Botão de reenvio sempre acima do campo de código — mesma
              // regra aplicada em VerifyEmailScreen.
              NeoOutlineButton(
                onPressed: canResend ? _resend : null,
                icon: const Icon(Icons.refresh_rounded),
                child: _isResending
                    ? const NeoLoadingIndicator(compact: true)
                    : Text(
                        _cooldownRemaining > 0
                            ? 'REENVIAR EM ${_cooldownRemaining}s'
                            : 'REENVIAR CÓDIGO',
                      ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                autofocus: true,
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
                onPressed: _isVerifying ? null : _verify,
                icon: const Icon(Icons.verified_user_outlined),
                trailing: _isVerifying ? null : const Icon(Icons.check_rounded),
                child: _isVerifying
                    ? const NeoLoadingIndicator(compact: true)
                    : const Text('CONFIRMAR CÓDIGO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
