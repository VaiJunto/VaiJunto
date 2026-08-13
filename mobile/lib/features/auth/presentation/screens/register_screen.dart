import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_version.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/neo_auth_backdrop.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_loading_indicator.dart';
import '../../../../core/validation/auth_validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/password_requirements.dart';
import '../widgets/vaijunto_logo.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordSectionKey = GlobalKey();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  double _lastHandledKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_handlePasswordFocus);
  }

  void _handlePasswordFocus() {
    if (mounted) setState(() {});
  }

  void _schedulePasswordRequirementsReveal(double keyboardInset) {
    if (keyboardInset <= 0) {
      _lastHandledKeyboardInset = 0;
      return;
    }
    if (!_passwordFocusNode.hasFocus ||
        (keyboardInset - _lastHandledKeyboardInset).abs() < 1) {
      return;
    }

    _lastHandledKeyboardInset = keyboardInset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_passwordFocusNode.hasFocus) return;
      final targetContext = _passwordSectionKey.currentContext;
      if (targetContext == null) return;

      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.08,
        duration: Duration.zero,
      );
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.removeListener(_handlePasswordFocus);
    _passwordFocusNode.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.register({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'password': _passwordController.text,
        'profileTypes': ['PASSENGER'],
      });

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: result.email,
            codeAlreadySent: true,
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, ApiException.fromDio(error).message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    _schedulePasswordRequirementsReveal(keyboardInset);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeoAuthBackdrop(),
          SafeArea(
            maintainBottomViewPadding: true,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      16,
                      22,
                      20 + keyboardInset,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 410),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _RegisterHeader(),
                                const SizedBox(height: 27),
                                Text(
                                  'NOVO ACESSO INSTITUCIONAL',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.tertiary,
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'CRIAR CONTA',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontSize: 30,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Use seu e-mail institucional. Leva menos de um minuto.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome completo',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Informe seu nome'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail institucional',
                                    hintText: 'seu.nome@fatec.sp.gov.br',
                                    prefixIcon: Icon(Icons.alternate_email),
                                    helperText:
                                        '@aluno.cps.sp.gov.br ou @fatec.sp.gov.br',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: validateInstitutionalEmail,
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  key: _passwordSectionKey,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Crie uma senha',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                          tooltip: _obscurePassword
                                              ? 'Mostrar senha'
                                              : 'Ocultar senha',
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      ),
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      onChanged: (_) => setState(() {}),
                                      onFieldSubmitted: (_) => _submit(),
                                      validator: validatePassword,
                                    ),
                                    const SizedBox(height: 12),
                                    PasswordRequirements(
                                      password: _passwordController.text,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  color: theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 410),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeoButton(
                            onPressed: _isSubmitting ? null : _submit,
                            trailing: _isSubmitting
                                ? null
                                : const Icon(Icons.arrow_forward_rounded),
                            child: _isSubmitting
                                ? const NeoLoadingIndicator(compact: true)
                                : const Text('CRIAR CONTA'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'V $kAppVersion',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            const VaiJuntoLogo(size: 40, showWordmark: false),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'VAIJUNTO',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Voltar',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Stack(
          children: [
            Container(height: 2, color: scheme.ink),
            Container(width: 68, height: 2, color: scheme.primary),
          ],
        ),
      ],
    );
  }
}
