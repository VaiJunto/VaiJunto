import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/app_version_label.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/validation/auth_validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/vaijunto_logo.dart';
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

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
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
    final authState = ref.watch(authStateProvider);

    // Só erros: o sucesso é sinalizado pela troca de tela no _AuthGate.
    ref.listen(authStateProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          // Senha certa, mas o e-mail institucional ainda não foi confirmado:
          // leva direto para a tela de confirmação em vez de só reclamar.
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      const VaiJuntoLogo(),
                      const SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-mail institucional',
                                hintText: 'seu.nome@fatec.sp.gov.br',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: validateInstitutionalEmail,
                            ),
                            const SizedBox(height: 16),
                            // Sem checklist de requisitos aqui de propósito: no
                            // login, mostrar em tempo real quais regras a senha
                            // digitada satisfaz só ajuda quem está tentando
                            // adivinhar uma senha que não é sua. O checklist
                            // fica só no cadastro, onde a senha está sendo
                            // criada, não adivinhada.
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline),
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
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              validator: validatePassword,
                            ),
                            const SizedBox(height: 24),
                            NeoButton(
                              onPressed: authState.isLoading ? null : _submit,
                              child: authState.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : const Text('ENTRAR'),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: theme.dividerColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'ainda não faz parte?',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Botão de verdade, não um link de texto discreto: quem
                      // ainda não tem conta precisa enxergar isso como uma
                      // ação clara, do mesmo tamanho do "ENTRAR" acima.
                      NeoOutlineButton(
                        onPressed: authState.isLoading ? null : _goToRegister,
                        child: const Text('CRIAR CONTA GRÁTIS'),
                      ),
                      const SizedBox(height: 20),
                      const AppVersionLabel(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
