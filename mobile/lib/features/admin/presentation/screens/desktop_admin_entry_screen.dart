import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/ui/neo_street_backdrop.dart';
import '../../../../core/storage/secure_storage.dart';
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
  bool _authenticated = false;
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
      final response = await ref.read(dioProvider).post('/admin/auth/login',
          data: {
            'email': _email.text,
            'password': _password.text,
            'totpCode': _totp.text
          });
      if (mounted) {
        await ref
            .read(secureStorageProvider)
            .saveToken(response.data['token'] as String);
        setState(() => _authenticated = true);
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
    if (_authenticated) return const _AdminOperationsPanel();
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

class _AdminOperationsPanel extends ConsumerStatefulWidget {
  const _AdminOperationsPanel();
  @override
  ConsumerState<_AdminOperationsPanel> createState() =>
      _AdminOperationsPanelState();
}

class _AdminOperationsPanelState extends ConsumerState<_AdminOperationsPanel> {
  final _search = TextEditingController();
  List<dynamic> _users = const [];
  List<dynamic> _reports = const [];
  String? _error;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(dioProvider).get('/admin/reports');
      if (mounted) {
        setState(() => _reports = r.data as List<dynamic>);
      }
    } on DioException {
      if (mounted) {
        setState(
            () => _error = 'Não foi possível carregar a fila de denúncias.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _find() async {
    if (_search.text.trim().length < 2) {
      setState(() => _error = 'Digite ao menos 2 caracteres.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(dioProvider)
          .get('/admin/search', queryParameters: {'q': _search.text.trim()});
      if (mounted) {
        setState(() => _users = r.data as List<dynamic>);
      }
    } on DioException {
      if (mounted) {
        setState(() => _error = 'Não foi possível pesquisar pessoas.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: NeoStreetBackdrop()),
        Padding(
          padding: const EdgeInsets.all(32),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PAINEL ADMINISTRATIVO',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('VJ//COMMUNITY_OPERATIONS • acesso auditado',
                style:
                    TextStyle(color: scheme.tertiary, fontFamily: 'monospace')),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _search,
                      onSubmitted: (_) => _find(),
                      decoration: const InputDecoration(
                          labelText: 'Pesquisar pessoa por nome ou e-mail'))),
              const SizedBox(width: 12),
              NeoButton(
                  onPressed: _loading ? null : _find,
                  child: const Text('PESQUISAR')),
            ]),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: TextStyle(color: scheme.error))),
            const SizedBox(height: 20),
            Expanded(
                child: Row(children: [
              Expanded(child: _usersCard(scheme)),
              const SizedBox(width: 16),
              Expanded(child: _reportsCard(scheme)),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _usersCard(ColorScheme scheme) => NeoCard(
      color: scheme.surface,
      padding: const EdgeInsets.all(16),
      child: ListView(children: [
        const Text('PESSOAS', style: TextStyle(fontWeight: FontWeight.w900)),
        if (_users.isEmpty)
          const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Pesquise para iniciar uma análise.')),
        ..._users.map((u) => ListTile(
            title: Text(u['fullName'] as String),
            subtitle: Text('${u['email']} • ${u['verificationStatus']}'),
            trailing: Text(u['suspended'] == true
                ? 'SUSPENSO'
                : u['warned'] == true
                    ? 'ADVERTIDO'
                    : 'ATIVO')))
      ]));
  Widget _reportsCard(ColorScheme scheme) => NeoCard(
      color: scheme.surface,
      padding: const EdgeInsets.all(16),
      child: ListView(children: [
        Row(children: [
          const Expanded(
              child: Text('DENÚNCIAS',
                  style: TextStyle(fontWeight: FontWeight.w900))),
          NeoOutlineButton(
              onPressed: _loading ? null : _loadReports,
              child: const Text('ATUALIZAR'))
        ]),
        if (_reports.isEmpty)
          const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Nenhuma denúncia na fila.')),
        ..._reports.map((r) => ListTile(
            title: Text('DENÚNCIA • ${r['status']}'),
            subtitle: Text('${r['evidenceCount']} evidência(s) selecionada(s)'),
            trailing: const Icon(Icons.lock_outline)))
      ]));
}
