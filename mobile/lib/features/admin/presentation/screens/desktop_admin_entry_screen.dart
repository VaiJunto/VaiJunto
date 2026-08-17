import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/ui/neo_street_backdrop.dart';
import '../../../auth/presentation/screens/login_screen.dart';

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
  bool _showLogin = false;
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
      final response =
          await ref.read(dioProvider).post('/admin/auth/login', data: {
        'email': _email.text.trim(),
        'password': _password.text,
        'totpCode': _totp.text.trim()
      });
      await ref
          .read(secureStorageProvider)
          .saveAdminToken(response.data['token'] as String);
      if (mounted)
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => _AdminOperationsPanel(
                role: response.data['role'] as String? ?? 'ADMIN')));
    } on DioException catch (e) {
      if (mounted)
        setState(() => _error = _message(
            e, 'Não foi possível confirmar as credenciais administrativas.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 700) return const LoginScreen();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: NeoCard(
                    color: scheme.surface,
                    padding: const EdgeInsets.all(28),
                    child: _showLogin
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
                                    'Use suas credenciais administrativas e o código do autenticador.'),
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
                                        labelText: 'Código TOTP de 6 dígitos')),
                                if (_error != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(_error!,
                                          style:
                                              TextStyle(color: scheme.error))),
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
                                Text('Administração VaiJunto',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                const SizedBox(height: 12),
                                const Text(
                                    'O painel é feito para tela grande. A aparência desta página nunca concede acesso.'),
                                const SizedBox(height: 24),
                                NeoButton(
                                    onPressed: () =>
                                        setState(() => _showLogin = true),
                                    child: const Text('ACESSAR PAINEL')),
                                const SizedBox(height: 12),
                                NeoOutlineButton(
                                    onPressed: () => Navigator.of(context)
                                        .pushReplacementNamed('/'),
                                    child:
                                        const Text('ABRIR O VAIJUNTO NORMAL')),
                              ])))));
  }
}

class _AdminOperationsPanel extends ConsumerStatefulWidget {
  const _AdminOperationsPanel({required this.role});
  final String role;
  @override
  ConsumerState<_AdminOperationsPanel> createState() =>
      _AdminOperationsPanelState();
}

class _AdminOperationsPanelState extends ConsumerState<_AdminOperationsPanel> {
  final _search = TextEditingController();
  List<dynamic> _users = [],
      _reports = [],
      _stickers = [],
      _tags = [],
      _accounts = [];
  bool _loading = false;
  String? _error;
  bool get _superAdmin => widget.role == 'SUPER_ADMIN';
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final responses = await Future.wait([
        _search.text.trim().isEmpty
            ? dio.get('/admin/users')
            : dio.get('/admin/search',
                queryParameters: {'q': _search.text.trim()}),
        dio.get('/admin/reports'),
        dio.get('/admin/stickers'),
        dio.get('/admin/tags'),
        if (_superAdmin) dio.get('/admin/accounts')
      ]);
      if (mounted)
        setState(() {
          _users = responses[0].data as List<dynamic>;
          _reports = responses[1].data as List<dynamic>;
          _stickers = responses[2].data as List<dynamic>;
          _tags = responses[3].data as List<dynamic>;
          _accounts = _superAdmin ? responses[4].data as List<dynamic> : [];
        });
    } on DioException catch (e) {
      if (mounted)
        setState(
            () => _error = _message(e, 'Não foi possível carregar o painel.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchUsers() => _refresh();
  Future<void> _createSticker() async {
    final code = TextEditingController();
    final label = TextEditingController();
    final ok = await _formDialog('Cadastrar figurinha', [
      TextField(
          controller: code,
          decoration:
              const InputDecoration(labelText: 'Código (ex.: festa_01)')),
      TextField(
          controller: label,
          decoration: const InputDecoration(labelText: 'Nome exibido'))
    ]);
    if (ok != true) return;
    try {
      await ref.read(dioProvider).post('/admin/stickers',
          data: {'code': code.text.trim(), 'label': label.text.trim()});
      await _refresh();
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível cadastrar a figurinha.'));
    } finally {
      code.dispose();
      label.dispose();
    }
  }

  Future<void> _createTag() async {
    final name = TextEditingController();
    final color = TextEditingController(text: '#00AEEF');
    final svg = TextEditingController(
        text:
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 2l3 7 7 .6-5.3 4.5 1.6 6.9L12 17.2 5.7 21l1.6-6.9L2 9.6 9 9z"/></svg>');
    final ok = await _formDialog('Criar tag de pessoa', [
      TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nome da tag')),
      TextField(
          controller: color,
          decoration: const InputDecoration(
              labelText: 'Cor hexadecimal (ex.: #00AEEF)')),
      TextField(
          controller: svg,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Ícone SVG'))
    ]);
    if (ok != true) return;
    try {
      await ref.read(dioProvider).post('/admin/tags', data: {
        'name': name.text.trim(),
        'color': color.text.trim(),
        'iconSvg': svg.text.trim()
      });
      await _refresh();
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível criar a tag.'));
    } finally {
      name.dispose();
      color.dispose();
      svg.dispose();
    }
  }

  Future<void> _sendNewsletter(Map user) async {
    final title = TextEditingController(text: 'Mensagem do VaiJunto');
    final body = TextEditingController();
    final ok = await _formDialog('Newsletter para ${user['fullName']}', [
      TextField(
          controller: title,
          decoration: const InputDecoration(labelText: 'Título')),
      TextField(
          controller: body,
          minLines: 4,
          maxLines: 7,
          decoration:
              const InputDecoration(labelText: 'Mensagem (não respondível)'))
    ]);
    if (ok != true) return;
    try {
      await ref.read(dioProvider).post('/admin/users/${user['id']}/newsletter',
          data: {'title': title.text, 'body': body.text});
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Newsletter enviada.')));
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível enviar a newsletter.'));
    } finally {
      title.dispose();
      body.dispose();
    }
  }

  Future<void> _manageTags(Map user) async {
    await showDialog<void>(
        context: context,
        builder: (context) =>
            StatefulBuilder(builder: (context, setDialogState) {
              final assigned = ((user['tags'] as List?) ?? [])
                  .map((e) => e['id'].toString())
                  .toSet();
              return AlertDialog(
                  title: Text('Tags • ${user['fullName']}'),
                  content: SizedBox(
                      width: 420,
                      child: _tags.isEmpty
                          ? const Text('Crie uma tag primeiro.')
                          : ListView(
                              shrinkWrap: true,
                              children: _tags
                                  .map((tag) => CheckboxListTile(
                                      value: assigned
                                          .contains(tag['id'].toString()),
                                      title: Text(tag['name'].toString()),
                                      subtitle: Text(tag['color'].toString()),
                                      onChanged: (selected) async {
                                        try {
                                          final url =
                                              '/admin/users/${user['id']}/tags/${tag['id']}';
                                          final response = selected == true
                                              ? await ref
                                                  .read(dioProvider)
                                                  .post(url)
                                              : await ref
                                                  .read(dioProvider)
                                                  .delete(url);
                                          user['tags'] = response.data;
                                          setDialogState(() {});
                                          setState(() {});
                                        } on DioException catch (e) {
                                          _showError(_message(e,
                                              'Não foi possível atualizar as tags.'));
                                        }
                                      }))
                                  .toList())),
                  actions: [
                    TextButton(
                        onPressed: () => _createTag(),
                        child: const Text('NOVA TAG')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CONCLUÍDO'))
                  ]);
            }));
  }

  Future<void> _openAdminChat(Map user) async {
    try {
      final response = await ref
          .read(dioProvider)
          .post('/admin/users/${user['id']}/conversation');
      if (!mounted) return;
      await _adminChatDialog3(user, response.data['conversationId'].toString());
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível abrir a conversa.'));
    }
  }

  Future<void> _adminChatDialog(Map user, String conversationId) async {
    final message = TextEditingController();
    /*
    await showDialog<void>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) { Future<List<dynamic>> load() async => (await ref.read(dioProvider).get('/admin/conversations/$conversationId/messages')).data as List<dynamic>; return AlertDialog(title: Text('Chat admin • ${user['fullName']}'), content: SizedBox(width: 520, height: 440, child: FutureBuilder<List<dynamic>>(future: load(), builder: (context, snapshot) => Column(children: [Expanded(child: snapshot.hasData ? ListView(children: snapshot.data!.map((m) => Align(alignment: m['fromAdmin'] == true ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(9), color: m['fromAdmin'] == true ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['fromAdmin'] == true ? 'ADMIN • ${m['sender']}' : m['sender'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), Text(m['body']?.toString() ?? '')]))).toList()) : const Center(child: CircularProgressIndicator())), Row(children: [Expanded(child: TextField(controller: message, decoration: const InputDecoration(hintText: 'Responder como admin'))), IconButton(icon: const Icon(Icons.send), onPressed: () async { if (message.text.trim().isEmpty) return; try { await ref.read(dioProvider).post('/admin/conversations/$conversationId/messages', data: {'body': message.text.trim()}); message.clear(); setDialogState(() {}); } on DioException catch (e) { _showError(_message(e, 'Não foi possível enviar a mensagem.')); } })])])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR'))]); })); message.dispose();
    */
    message.dispose();
  }

  Future<void> _adminChatDialog2(Map user, String conversationId) async {
    final message = TextEditingController();
    /*
    var refresh = 0;
    await showDialog<void>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(title: Text('Chat admin • ${user['fullName']}'), content: SizedBox(width: 520, height: 440, child: Column(children: [Expanded(child: FutureBuilder<List<dynamic>>(key: ValueKey(refresh), future: _loadAdminMessages(conversationId), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); return ListView(children: snapshot.data!.map((m) => Align(alignment: m['fromAdmin'] == true ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(9), color: m['fromAdmin'] == true ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['fromAdmin'] == true ? 'ADMIN • ${m['sender']}' : m['sender'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), Text(m['body']?.toString() ?? '')]))).toList()); })), Row(children: [Expanded(child: TextField(controller: message, decoration: const InputDecoration(hintText: 'Responder como admin'))), IconButton(icon: const Icon(Icons.send), onPressed: () async { if (message.text.trim().isEmpty) return; try { await ref.read(dioProvider).post('/admin/conversations/$conversationId/messages', data: {'body': message.text.trim()}); message.clear(); setDialogState(() => refresh++); } on DioException catch (e) { _showError(_message(e, 'Não foi possível enviar a mensagem.')); } })])])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR'))])));
    message.dispose();
    */
  }

  Future<void> _adminChatDialog3(Map user, String conversationId) async {
    final message = TextEditingController();
    var refresh = 0;
    await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                    title: Text('Chat admin • ${user['fullName']}'),
                    content: SizedBox(
                        width: 520,
                        height: 440,
                        child: Column(children: [
                          Expanded(
                              child: FutureBuilder<List<dynamic>>(
                                  key: ValueKey(refresh),
                                  future: _loadAdminMessages(conversationId),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData)
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    return ListView(
                                        children: snapshot.data!
                                            .map(_adminChatBubble)
                                            .toList());
                                  })),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: message,
                                    decoration: const InputDecoration(
                                        hintText: 'Responder como admin'))),
                            IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () async {
                                  if (message.text.trim().isEmpty) return;
                                  try {
                                    await ref.read(dioProvider).post(
                                        '/admin/conversations/$conversationId/messages',
                                        data: {'body': message.text.trim()});
                                    message.clear();
                                    setDialogState(() => refresh++);
                                  } on DioException catch (e) {
                                    _showError(_message(e,
                                        'Não foi possível enviar a mensagem.'));
                                  }
                                })
                          ])
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('FECHAR'))
                    ])));
    message.dispose();
  }

  Widget _adminChatBubble(dynamic m) => Align(
      alignment:
          m['fromAdmin'] == true ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(9),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                m['fromAdmin'] == true
                    ? 'ADMIN • ${m['sender']}'
                    : m['sender'].toString(),
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text(m['body']?.toString() ?? '')
          ])));

  Future<List<dynamic>> _loadAdminMessages(String conversationId) async =>
      (await ref
              .read(dioProvider)
              .get('/admin/conversations/$conversationId/messages'))
          .data as List<dynamic>;

  Future<void> _personActions(Map user) async => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(user['fullName']?.toString() ?? 'Pessoa'),
              content: const Text('Escolha uma ação para esta pessoa.'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendNewsletter(user);
                    },
                    child: const Text('NEWSLETTER')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _manageTags(user);
                    },
                    child: const Text('TAGS')),
                FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openAdminChat(user);
                    },
                    child: const Text('CHAT ADMIN'))
              ]));

  Future<void> _createAdmin() async {
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'ADMIN';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo administrador'),
          content: SizedBox(
              width: 420,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'E-mail')),
                const SizedBox(height: 12),
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Senha inicial (mín. 12 caracteres)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(
                          value: 'ADMIN', child: Text('Administrador')),
                      DropdownMenuItem(
                          value: 'MODERATOR', child: Text('Moderador'))
                    ],
                    onChanged: (v) => setDialogState(() => role = v!),
                    decoration: const InputDecoration(labelText: 'Função')),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(context, {
                      'email': email.text.trim(),
                      'password': password.text,
                      'role': role
                    }),
                child: const Text('Criar e gerar TOTP')),
          ],
        ),
      ),
    );
    email.dispose();
    password.dispose();
    if (result == null) return;
    try {
      final response =
          await ref.read(dioProvider).post('/admin/accounts', data: result);
      if (!mounted) return;
      await _showTotp(response.data as Map<String, dynamic>);
      await _refresh();
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível criar o administrador.'));
    }
  }

  Future<void> _showTotp(Map<String, dynamic> data) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
              title: const Text('TOTP do novo administrador'),
              content: SizedBox(
                  width: 440,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(
                        'Escaneie este QR no Google Authenticator, Authy ou similar. Ele é mostrado somente agora.'),
                    const SizedBox(height: 16),
                    QrImageView(data: data['totpUri'] as String, size: 220),
                    const SizedBox(height: 12),
                    SelectableText(data['totpSecret'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(data['email'] as String)
                  ])),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Concluído'))
              ]));
  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final totp = TextEditingController();
    final ok = await _formDialog('Alterar minha senha', [
      TextField(
          controller: current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha atual')),
      TextField(
          controller: next,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'Nova senha (mín. 12 caracteres)')),
      TextField(
          controller: totp,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Código TOTP'))
    ]);
    if (ok != true) return;
    try {
      await ref.read(dioProvider).post('/admin/auth/password', data: {
        'currentPassword': current.text,
        'newPassword': next.text,
        'totpCode': totp.text.trim()
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senha alterada com sucesso.')));
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível alterar a senha.'));
    } finally {
      current.dispose();
      next.dispose();
      totp.dispose();
    }
  }

  Future<bool?> _formDialog(String title, List<Widget> fields) =>
      showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(title),
                  content: SizedBox(
                      width: 420,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: fields
                              .expand((w) => [w, const SizedBox(height: 12)])
                              .toList())),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Salvar'))
                  ]));
  void _showError(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
          backgroundColor: Theme.of(context).colorScheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        body: Stack(children: [
      const Positioned.fill(child: NeoStreetBackdrop()),
      SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('PAINEL ADMINISTRATIVO',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            Text('VJ//COMMUNITY_OPERATIONS • ${widget.role}',
                                style: TextStyle(
                                    color: scheme.tertiary,
                                    fontFamily: 'monospace'))
                          ])),
                      SizedBox(
                          width: 155,
                          child: NeoOutlineButton(
                              height: 44,
                              onPressed: _changePassword,
                              child: const Text('MINHA SENHA'))),
                      const SizedBox(width: 12),
                      SizedBox(
                          width: 120,
                          child: NeoButton(
                              height: 44,
                              onPressed: _loading ? null : _refresh,
                              child: const Text('ATUALIZAR')))
                    ]),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: _search,
                              onSubmitted: (_) => _searchUsers(),
                              decoration: const InputDecoration(
                                  labelText:
                                      'Buscar pessoas por nome ou e-mail'))),
                      const SizedBox(width: 12),
                      SizedBox(
                          width: 145,
                          child: NeoButton(
                              onPressed: _loading ? null : _searchUsers,
                              child: const Text('PESQUISAR')))
                    ]),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_error!,
                              style: TextStyle(color: scheme.error))),
                    const SizedBox(height: 16),
                    Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth > 1100;
                      final cards = [
                        _peopleCard(scheme),
                        _tagsCard(scheme),
                        _reportsCard(scheme),
                        _stickersCard(scheme),
                        if (_superAdmin) _adminsCard(scheme)
                      ];
                      return GridView.count(
                          crossAxisCount: twoColumns ? 2 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: twoColumns ? 1.65 : 2.1,
                          children: cards);
                    }))
                  ])))
    ]));
  }

  Widget _card(ColorScheme scheme, String title, List<Widget> children,
          {Widget? action}) =>
      NeoCard(
          color: scheme.surface,
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16))),
              if (action != null) SizedBox(width: 145, child: action)
            ]),
            const SizedBox(height: 12),
            Expanded(
                child: children.isEmpty
                    ? const Center(child: Text('Nenhum registro encontrado.'))
                    : ListView.separated(
                        itemCount: children.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) => children[i]))
          ]));
  Widget _peopleCard(ColorScheme scheme) => _card(
      scheme,
      'PESSOAS (${_users.length})',
      _users
          .map((u) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${u['fullName'] ?? 'Sem nome'}'),
              subtitle: Text(
                  '${u['email'] ?? ''} • ${u['verificationStatus'] ?? 'sem status'}'),
              trailing: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Ações da pessoa',
                  onPressed: () => _personActions(u as Map))))
          .toList());
  Widget _tagsCard(ColorScheme scheme) => _card(
      scheme,
      'TAGS DE PESSOAS (${_tags.length})',
      _tags
          .map((tag) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      color: _tagColor(tag['color']?.toString()),
                      shape: BoxShape.circle)),
              title: Text(tag['name']?.toString() ?? ''),
              subtitle: Text(tag['color']?.toString() ?? '')))
          .toList(),
      action: _superAdmin || widget.role == 'ADMIN'
          ? NeoButton(
              height: 38, onPressed: _createTag, child: const Text('NOVA TAG'))
          : null);
  Widget _reportsCard(ColorScheme scheme) => _card(
      scheme,
      'DENÚNCIAS (${_reports.length})',
      _reports
          .map((r) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('DENÚNCIA • ${r['status']}'),
              subtitle:
                  Text('${r['evidenceCount']} evidência(s) selecionada(s)')))
          .toList());
  Widget _stickersCard(ColorScheme scheme) => _card(
      scheme,
      'FIGURINHAS (${_stickers.length})',
      _stickers
          .map((s) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${s['label']}'),
              subtitle: Text(s['code']?.toString() ?? ''),
              trailing: Text(s['active'] == true ? 'ATIVA' : 'INATIVA')))
          .toList(),
      action: _superAdmin || widget.role == 'ADMIN'
          ? NeoButton(
              height: 38,
              onPressed: _createSticker,
              child: const Text('NOVA FIGURINHA'))
          : null);
  Widget _adminsCard(ColorScheme scheme) => _card(
      scheme,
      'ADMINISTRADORES (${_accounts.length})',
      _accounts
          .map((a) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(a['email']?.toString() ?? ''),
              subtitle: Text(a['role']?.toString() ?? ''),
              trailing: Text(a['active'] == true ? 'ATIVO' : 'INATIVO')))
          .toList(),
      action: NeoButton(
          height: 38,
          onPressed: _createAdmin,
          child: const Text('NOVO ADMIN')));
}

String _message(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map && data['message'] is String)
    return data['message'] as String;
  return fallback;
}

Color _tagColor(String? value) =>
    Color(int.parse((value ?? '#666666').replaceFirst('#', 'FF'), radix: 16));
