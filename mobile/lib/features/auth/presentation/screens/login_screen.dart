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
import '../providers/auth_provider.dart';
import '../widgets/vaijunto_logo.dart';
import 'device_verification_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final challengeToken = await ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (!mounted || challengeToken == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DeviceVerificationScreen(
            challengeToken: challengeToken,
          ),
        ),
      );
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is ApiException && error.code == 'EMAIL_NOT_VERIFIED') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VerifyEmailScreen(
                  email: _emailController.text.trim().toLowerCase(),
                ),
              ),
            );
            return;
          }
          AppSnackbar.error(context, error.toString());
        },
      );
    });

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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final keyboardInset =
                          MediaQuery.viewInsetsOf(context).bottom;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          22,
                          18,
                          22,
                          18 + keyboardInset,
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 36,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 410),
                              child: AutofillGroup(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _SimpleBrand(),
                                      const SizedBox(height: 30),
                                      Text(
                                        'ACESSO INSTITUCIONAL',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: scheme.tertiary,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'ENTRAR',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(fontSize: 32),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'Acesse sua conta institucional.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'E-mail institucional',
                                          hintText: 'seu.nome@fatec.sp.gov.br',
                                          prefixIcon:
                                              Icon(Icons.alternate_email),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        validator: validateInstitutionalEmail,
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: InputDecoration(
                                          labelText: 'Senha',
                                          prefixIcon:
                                              const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
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
                                          AutofillHints.password,
                                        ],
                                        onFieldSubmitted: (_) => _submit(),
                                        validator: validatePassword,
                                      ),
                                      const SizedBox(height: 18),
                                      NeoButton(
                                        onPressed: authState.isLoading
                                            ? null
                                            : _submit,
                                        trailing: authState.isLoading
                                            ? null
                                            : const Icon(
                                                Icons.arrow_forward_rounded,
                                              ),
                                        child: authState.isLoading
                                            ? const NeoLoadingIndicator(
                                                compact: true,
                                              )
                                            : const Text('ENTRAR'),
                                      ),
                                      const SizedBox(height: 26),
                                      Text(
                                        'PRIMEIRO ACESSO?',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      NeoOutlineButton(
                                        onPressed: authState.isLoading
                                            ? null
                                            : _goToRegister,
                                        height: 48,
                                        icon: const Icon(
                                          Icons.person_add_alt_1_outlined,
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_rounded,
                                        ),
                                        child: const Text(
                                          'CRIAR CONTA GRÁTIS',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const _VersionFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        'V $kAppVersion',
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: 8,
        ),
      ),
    );
  }
}

class _SimpleBrand extends StatelessWidget {
  const _SimpleBrand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            const VaiJuntoLogo(size: 42, showWordmark: false),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VAIJUNTO',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'CARONAS UNIVERSITÁRIAS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(height: 2, color: scheme.ink),
            Container(width: 72, height: 2, color: scheme.primary),
          ],
        ),
      ],
    );
  }
}
