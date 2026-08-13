import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/ui/app_version_label.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/validation/auth_validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/password_requirements.dart';
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

  bool _obscurePassword = true;
  bool _isVanDriver = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Chama o repositório direto, sem passar pelo authStateProvider: o
  // cadastro não é mais um login (a conta só fica utilizável depois da
  // confirmação de e-mail), então não deve mexer no estado global de sessão.
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
        'profileTypes':
            _isVanDriver ? ['VAN_DRIVER', 'PASSENGER'] : ['PASSENGER'],
      });

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(email: result.email, codeAlreadySent: true),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, ApiException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use seu e-mail institucional para entrar na comunidade da sua faculdade.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe seu nome'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail institucional',
                          hintText: 'seu.nome@fatec.sp.gov.br',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.alternate_email),
                          helperText:
                              'Aceitamos @aluno.cps.sp.gov.br e @fatec.sp.gov.br',
                          helperMaxLines: 2,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: validateInstitutionalEmail,
                      ),
                      const SizedBox(height: 16),
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
                        onChanged: (_) => setState(() {}),
                        validator: validatePassword,
                      ),
                      const SizedBox(height: 12),
                      PasswordRequirements(password: _passwordController.text),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: NeoCard(
                          color: theme.colorScheme.surfaceContainerHighest,
                          padding: EdgeInsets.zero,
                          child: SwitchListTile(
                            title: const Text('Sou motorista de van/fretado'),
                            subtitle: const Text(
                              'Ative para gerenciar rotas e passageiros.',
                            ),
                            value: _isVanDriver,
                            onChanged: (val) =>
                                setState(() => _isVanDriver = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(child: AppVersionLabel()),
                    ],
                  ),
                ),
              ),
            ),
            // Botão fixo no rodapé — sempre alcançável, sem precisar rolar.
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: theme.colorScheme.ink, width: 3)),
              ),
              child: NeoButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('CRIAR CONTA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
