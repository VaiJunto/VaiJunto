import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../auth/presentation/screens/login_screen.dart';

/// Presentation-only desktop entry. Access is always enforced by the backend's separate admin token.
class DesktopAdminEntryScreen extends ConsumerStatefulWidget {
  const DesktopAdminEntryScreen({super.key});
  @override
  ConsumerState<DesktopAdminEntryScreen> createState() =>
      _DesktopAdminEntryScreenState();
}

class _DesktopAdminEntryScreenState
    extends ConsumerState<DesktopAdminEntryScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _totp = TextEditingController();
  bool _panel = false;
  bool _loading = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _totp.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(dioProvider).post('/admin/auth/login', data: {
        'email': _email.text,
        'password': _password.text,
        'totpCode': _totp.text
      });
      if (mounted) {
        setState(() => _error =
            'Acesso confirmado. O painel de operações será liberado nos próximos módulos.');
      }
    } on DioException {
      if (mounted) {
        setState(() => _error =
            'Não foi possível confirmar as credenciais administrativas.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (MediaQuery.sizeOf(context).width < 700) return const LoginScreen();
    return Scaffold(
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: NeoCard(
                  color: scheme.surface,
                  padding: const EdgeInsets.all(28),
                  child: _panel
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text('ACESSO ADMINISTRATIVO',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 8),
                              const Text(
                                  'Use credenciais administrativas separadas e o código do seu autenticador.'),
                              const SizedBox(height: 20),
                              TextField(
                                  controller: _email,
                                  decoration: const InputDecoration(
                                      labelText: 'E-mail administrativo')),
                              const SizedBox(height: 12),
                              TextField(
                                  controller: _password,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Senha')),
                              const SizedBox(height: 12),
                              TextField(
                                  controller: _totp,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Código de 6 dígitos')),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(_error!,
                                        style: TextStyle(color: scheme.error))),
                              const SizedBox(height: 20),
                              NeoButton(
                                  onPressed: _loading ? null : _login,
                                  child: Text(_loading
                                      ? 'CONFIRMANDO...'
                                      : 'ACESSAR PAINEL')),
                            ])
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text('VJ//ADMIN_ENTRY',
                                  style: TextStyle(
                                      color: scheme.tertiary,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text('Opa, parece que você descobriu o segredo.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 12),
                              const Text(
                                  'O painel é feito para uma tela maior. A aparência desta página nunca concede acesso.'),
                              const SizedBox(height: 24),
                              NeoButton(
                                  onPressed: () =>
                                      setState(() => _panel = true),
                                  child: const Text('ACESSAR PAINEL')),
                              const SizedBox(height: 12),
                              NeoOutlineButton(
                                  onPressed: () => Navigator.of(context)
                                      .pushReplacement(MaterialPageRoute(
                                          builder: (_) => const LoginScreen())),
                                  child: const Text('ABRIR O VAIJUNTO NORMAL')),
                            ]),
                ))));
  }
}
