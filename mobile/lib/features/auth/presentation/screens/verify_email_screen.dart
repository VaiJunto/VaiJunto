import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/neo_button.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';

/// Confirma o e-mail institucional com o código de 6 dígitos enviado por
/// e-mail. É empilhada tanto pelo cadastro (código já foi enviado, aqui
/// [codeAlreadySent] chega `true`) quanto pelo login, quando o backend recusa
/// por EMAIL_NOT_VERIFIED — nesse caso o código mais recente do usuário pode
/// ser de um cadastro muito antes (login horas ou dias depois), então em vez
/// de deixar a pessoa tentar contra um código possivelmente vencido, esta
/// tela já manda um novo assim que abre.
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
      final user = await repository.verifyEmail(widget.email, _codeController.text.trim());

      if (!mounted) return;
      // Confirmar o código JÁ é o login — entra direto, sem passo extra.
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

  /// [silent] evita o snackbar de sucesso no envio automático ao abrir a tela
  /// (vindo do bloqueio de login) — só faz sentido comemorar o envio quando a
  /// pessoa pediu de propósito, tocando em "Reenviar código".
  Future<void> _resend({bool silent = false}) async {
    setState(() => _isResending = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resendVerificationCode(widget.email);

      if (!mounted) return;
      setState(() => _hasFreshCode = true);
      if (!silent) {
        AppSnackbar.success(context, 'Enviamos um novo código para o seu e-mail.');
      }
      _startCooldown();
    } on DioException catch (e) {
      if (!mounted) return;
      // RATE_LIMITED pode vir do backend mesmo com o cooldown local ativo
      // (relógios diferentes) — a mensagem já explica quanto falta esperar.
      AppSnackbar.error(context, ApiException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canResend = !_isResending && _cooldownRemaining <= 0;
    // Enquanto o envio automático (silencioso) ainda não confirmou que um
    // código fresco existe, não faz sentido deixar tentar um código: seria
    // repetir exatamente o cenário que gerou confusão (chutar contra um
    // código antigo antes do novo sequer ter sido enviado).
    final canSubmit = !_isVerifying && _hasFreshCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirme seu e-mail')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mark_email_read_outlined,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  _hasFreshCode
                      ? 'Enviamos um código de 6 dígitos para:'
                      : 'Confirmando seu e-mail institucional:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 28),
                if (!_hasFreshCode)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Enviando código...'),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _codeController,
                  enabled: _hasFreshCode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Código de 6 dígitos',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _verify(),
                  validator: (v) => (v == null || v.trim().length != 6)
                      ? 'Informe os 6 dígitos do código'
                      : null,
                ),
                const SizedBox(height: 20),
                NeoButton(
                  onPressed: canSubmit ? _verify : null,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('CONFIRMAR'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: canResend ? () => _resend() : null,
                    child: _isResending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _cooldownRemaining > 0
                                ? 'Reenviar código em ${_cooldownRemaining}s'
                                : 'Reenviar código',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
