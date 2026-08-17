import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/ui/neo_loading_indicator.dart';
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
        body: Stack(children: [
      const Positioned.fill(
          child: NeoStreetBackdrop(variant: NeoStreetBackdropVariant.auth)),
      SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Row(children: [
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.only(right: 64),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const NeoBadge(
                                          color: NeoBrutal.ultraviolet,
                                          foregroundColor: Colors.white,
                                          child: Text('ACESSO RESTRITO')),
                                      const SizedBox(height: 28),
                                      Text('CENTRAL DE\nOPERAÇÕES',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(fontSize: 48)),
                                      const SizedBox(height: 16),
                                      Text(
                                          'Pessoas, segurança e conteúdo do VaiJunto em um só lugar.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 28),
                                      _AdminRouteLine(color: scheme.tertiary),
                                      const SizedBox(height: 12),
                                      Text('VJ//COMMUNITY_OPERATIONS • SJC',
                                          style: TextStyle(
                                              color: scheme.tertiary,
                                              fontFamily: 'IBMPlexMono',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11))
                                    ]))),
                        SizedBox(
                            width: 460,
                            child: NeoCard(
                                color: scheme.surface,
                                padding: const EdgeInsets.all(28),
                                child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 140),
                                    child: _showLogin
                                        ? _adminLoginForm(scheme)
                                        : _adminEntry(scheme))))
                      ])))))
    ]));
  }

  Widget _adminEntry(ColorScheme scheme) => Column(
          key: const ValueKey('admin-entry'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VJ//ADMIN_ENTRY', style: _systemStyle(scheme)),
            const SizedBox(height: 10),
            Text('ADMINISTRAÇÃO VAIJUNTO',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
                'Entre com seu acesso administrativo para abrir o workspace de operações.'),
            const SizedBox(height: 24),
            NeoButton(
                icon: const Icon(Icons.lock_open_outlined),
                trailing: const Icon(Icons.arrow_forward),
                onPressed: () => setState(() => _showLogin = true),
                child: const Text('ENTRAR NO PAINEL')),
            const SizedBox(height: 12),
            NeoOutlineButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
                child: const Text('VOLTAR AO VAIJUNTO'))
          ]);

  Widget _adminLoginForm(ColorScheme scheme) => Column(
          key: const ValueKey('admin-login'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VJ//SECURE_LOGIN', style: _systemStyle(scheme)),
            const SizedBox(height: 10),
            Text('ACESSO ADMINISTRATIVO',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Credenciais administrativas + código autenticador.'),
            const SizedBox(height: 20),
            TextField(
                controller: _email,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                    labelText: 'E-mail administrativo',
                    prefixIcon: Icon(Icons.alternate_email))),
            const SizedBox(height: 12),
            TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Senha', prefixIcon: Icon(Icons.key_outlined))),
            const SizedBox(height: 12),
            TextField(
                controller: _totp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onSubmitted: (_) => _loading ? null : _login(),
                decoration: const InputDecoration(
                    labelText: 'Código TOTP',
                    counterText: '',
                    prefixIcon: Icon(Icons.pin_outlined))),
            if (_error != null)
              Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: .1),
                      border: Border.all(
                          color: scheme.error, width: NeoBrutal.borderWidth)),
                  child: Text(_error!,
                      style: TextStyle(
                          color: scheme.error, fontWeight: FontWeight.w700))),
            const SizedBox(height: 20),
            NeoButton(
                icon: _loading
                    ? const NeoLoadingIndicator(compact: true)
                    : const Icon(Icons.login),
                onPressed: _loading ? null : _login,
                child: Text(_loading ? 'CONFIRMANDO...' : 'ACESSAR PAINEL')),
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _showLogin = false;
                          _error = null;
                        }),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('VOLTAR'))
          ]);

  TextStyle _systemStyle(ColorScheme scheme) => TextStyle(
      color: scheme.tertiary,
      fontFamily: 'IBMPlexMono',
      fontWeight: FontWeight.w700,
      letterSpacing: .8,
      fontSize: 11);
}

enum _AdminSection { people, reports, stickers, tags, accounts }

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
  _AdminSection _section = _AdminSection.people;
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
  Future<void> _createStickerWithAsset() async {
    final code = TextEditingController();
    final label = TextEditingController();
    PlatformFile? asset;
    final ok = await _showAdminDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                    title: const Text('Cadastrar figurinha'),
                    content: SizedBox(
                        width: 460,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'Uma reação visual para o chat. PNG, JPG, WEBP ou GIF animado, até 2 MB.'),
                              const SizedBox(height: 16),
                              TextField(
                                  controller: label,
                                  decoration: const InputDecoration(
                                      labelText: 'Nome da figurinha',
                                      hintText: 'Ex.: Comemorando')),
                              const SizedBox(height: 12),
                              TextField(
                                  controller: code,
                                  decoration: const InputDecoration(
                                      labelText: 'Código interno',
                                      hintText: 'Ex.: comemorando_01')),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                  onPressed: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: const [
                                              'png',
                                              'jpg',
                                              'jpeg',
                                              'webp',
                                              'gif'
                                            ],
                                            withData: true);
                                    if (result != null)
                                      setDialog(
                                          () => asset = result.files.single);
                                  },
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: Text(asset == null
                                      ? 'ESCOLHER ARQUIVO'
                                      : 'TROCAR ARQUIVO')),
                              if (asset != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(children: [
                                      if (asset!.bytes != null)
                                        ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.memory(asset!.bytes!,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(
                                              '${asset!.name}\n${(asset!.size / 1024).toStringAsFixed(0)} KB'))
                                    ]))
                            ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: asset == null
                              ? null
                              : () => Navigator.pop(context, true),
                          child: const Text('Salvar'))
                    ])));
    if (ok == true && asset?.bytes != null)
      try {
        await ref.read(dioProvider).post('/admin/stickers',
            data: FormData.fromMap({
              'code': code.text.trim(),
              'label': label.text.trim(),
              'asset':
                  MultipartFile.fromBytes(asset!.bytes!, filename: asset!.name)
            }));
        await _refresh();
      } on DioException catch (e) {
        _showError(_message(e, 'Não foi possível cadastrar a figurinha.'));
      } finally {
        code.dispose();
        label.dispose();
      }
  }

  Future<void> _createTagWithFile() async {
    final name = TextEditingController();
    const colors = [
      Color(0xFF00AEEF),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF673AB7),
      Color(0xFF3F51B5),
      Color(0xFF009688),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFFF44336),
      Color(0xFF795548),
      Color(0xFF607D8B),
      Color(0xFF111827)
    ];
    Color color = colors.first;
    PlatformFile? icon;
    final ok = await _showAdminDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                    title: const Text('Criar tag de pessoa'),
                    content: SizedBox(
                        width: 460,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                  controller: name,
                                  decoration: const InputDecoration(
                                      labelText: 'Nome da tag',
                                      hintText: 'Ex.: Motorista parceiro')),
                              const SizedBox(height: 18),
                              const Text('Cor da tag'),
                              const SizedBox(height: 8),
                              Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: colors
                                      .map((item) => InkWell(
                                          onTap: () =>
                                              setDialog(() => color = item),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          child: Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                  color: item,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: color == item
                                                          ? Colors.white
                                                          : Colors.transparent,
                                                      width: 3)))))
                                      .toList()),
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                  onPressed: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: const ['svg'],
                                            withData: true);
                                    if (result != null)
                                      setDialog(
                                          () => icon = result.files.single);
                                  },
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(icon == null
                                      ? 'ANEXAR ÍCONE SVG'
                                      : 'TROCAR ÍCONE SVG')),
                              if (icon != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(icon!.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)))
                            ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: icon == null
                              ? null
                              : () => Navigator.pop(context, true),
                          child: const Text('Salvar'))
                    ])));
    if (ok == true && icon?.bytes != null)
      try {
        final svg = String.fromCharCodes(icon!.bytes!);
        await ref.read(dioProvider).post('/admin/tags', data: {
          'name': name.text.trim(),
          'color':
              '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
          'iconSvg': svg.trim()
        });
        await _refresh();
      } on DioException catch (e) {
        _showError(_message(e, 'Não foi possível criar a tag.'));
      } finally {
        name.dispose();
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
    await _showAdminDialog<void>(
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
                        onPressed: () => _createTagWithFile(),
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
    await _showAdminDialog<void>(
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
                                    if (!snapshot.hasData) {
                                      return const Center(
                                          child: NeoLoadingIndicator(
                                              label: 'CARREGANDO CONVERSA'));
                                    }
                                    return ListView(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        children: snapshot.data!
                                            .map(_adminChatBubble)
                                            .toList());
                                  })),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: message,
                                    decoration: const InputDecoration(
                                        hintText: 'Responder como admin',
                                        prefixIcon:
                                            Icon(Icons.chat_bubble_outline)))),
                            const SizedBox(width: 10),
                            SizedBox(
                                width: 56,
                                child: NeoButton(
                                    height: 52,
                                    onPressed: () async {
                                      if (message.text.trim().isEmpty) return;
                                      try {
                                        await ref.read(dioProvider).post(
                                            '/admin/conversations/$conversationId/messages',
                                            data: {
                                              'body': message.text.trim()
                                            });
                                        message.clear();
                                        setDialogState(() => refresh++);
                                      } on DioException catch (e) {
                                        _showError(_message(e,
                                            'Não foi possível enviar a mensagem.'));
                                      }
                                    },
                                    child: const Icon(Icons.send)))
                          ])
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('FECHAR'))
                    ])));
    message.dispose();
  }

  Widget _adminChatBubble(dynamic m) {
    final fromAdmin = m['fromAdmin'] == true;
    final scheme = Theme.of(context).colorScheme;
    return Align(
        alignment: fromAdmin ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: fromAdmin
                    ? scheme.secondary.withValues(alpha: .14)
                    : scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.ink, width: 2),
                borderRadius: BorderRadius.circular(NeoBrutal.borderRadius)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  fromAdmin ? 'ADMIN • ${m['sender']}' : m['sender'].toString(),
                  style: TextStyle(
                      color: fromAdmin ? scheme.secondary : scheme.tertiary,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(m['body']?.toString() ?? '')
            ])));
  }

  Future<List<dynamic>> _loadAdminMessages(String conversationId) async =>
      (await ref
              .read(dioProvider)
              .get('/admin/conversations/$conversationId/messages'))
          .data as List<dynamic>;

  Future<void> _personActions(Map user) async => _showAdminDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(user['fullName']?.toString() ?? 'Pessoa'),
              content: SizedBox(
                  width: 460,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(user['email']?.toString() ?? '',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.secondary))),
                    const SizedBox(height: 8),
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            'Escolha uma ação. Todas ficam registradas no histórico administrativo.')),
                    const SizedBox(height: 16),
                    _personActionButton(
                        Icons.chat_bubble_outline,
                        'Abrir chat administrativo',
                        'Converse com esta pessoa pelo canal oficial do painel.',
                        () {
                      Navigator.pop(context);
                      _openAdminChat(user);
                    }),
                    _personActionButton(Icons.sell_outlined, 'Gerenciar tags',
                        'Adicione ou remova identificadores visuais do perfil.',
                        () {
                      Navigator.pop(context);
                      _manageTags(user);
                    }),
                    _personActionButton(
                        Icons.campaign_outlined,
                        'Enviar newsletter',
                        'Envie uma comunicação sem possibilidade de resposta.',
                        () {
                      Navigator.pop(context);
                      _sendNewsletter(user);
                    }),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'))
              ]));

  Widget _personActionButton(IconData icon, String title, String description,
          VoidCallback onTap) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  alignment: Alignment.centerLeft),
              child: Row(children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(description, style: const TextStyle(fontSize: 12))
                    ]))
              ])));

  Future<void> _createAdmin() async {
    final email = TextEditingController();
    final password = TextEditingController();
    Map<String, dynamic>? created;
    await _showAdminDialog<void>(
        context: context,
        builder: (dialogContext) {
          String role = 'ADMIN';
          String? error;
          bool saving = false;
          return StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                      title: const Text('Criar acesso administrativo'),
                      content: SizedBox(
                          width: 480,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                    'A pessoa receberá um acesso protegido por senha e TOTP. Escolha somente o nível necessário.'),
                                const SizedBox(height: 16),
                                TextField(
                                    controller: email,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                        labelText: 'E-mail do responsável',
                                        errorText: error != null &&
                                                email.text.trim().isEmpty
                                            ? 'Informe o e-mail.'
                                            : null)),
                                const SizedBox(height: 12),
                                TextField(
                                    controller: password,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                        labelText: 'Senha inicial',
                                        helperText:
                                            'Use pelo menos 12 caracteres.',
                                        errorText: error != null &&
                                                password.text.length < 12
                                            ? 'A senha precisa ter 12 caracteres.'
                                            : null)),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                    initialValue: role,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'ADMIN',
                                          child: Text('Administrador')),
                                      DropdownMenuItem(
                                          value: 'MODERATOR',
                                          child: Text('Moderador'))
                                    ],
                                    onChanged: saving
                                        ? null
                                        : (value) => setDialogState(() {
                                              role = value!;
                                              error = null;
                                            }),
                                    decoration: const InputDecoration(
                                        labelText: 'Nível de acesso')),
                                const SizedBox(height: 12),
                                Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(role == 'ADMIN'
                                        ? 'Administrador: gerencia pessoas, tags, comunicações, figurinhas e contas administrativas. Não pode criar Super Admin.'
                                        : 'Moderador: cuida de denúncias e da segurança das pessoas. Não cria contas, tags ou configurações do sistema.')),
                                if (error != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(error!,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              fontWeight: FontWeight.w700)))
                              ])),
                      actions: [
                        TextButton(
                            onPressed:
                                saving ? null : () => Navigator.pop(context),
                            child: const Text('Cancelar')),
                        FilledButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (email.text.trim().isEmpty ||
                                        password.text.length < 12) {
                                      setDialogState(() => error =
                                          'Revise os campos destacados antes de criar o acesso.');
                                      return;
                                    }
                                    setDialogState(() {
                                      saving = true;
                                      error = null;
                                    });
                                    try {
                                      final response = await ref
                                          .read(dioProvider)
                                          .post('/admin/accounts', data: {
                                        'email': email.text.trim(),
                                        'password': password.text,
                                        'role': role
                                      });
                                      created =
                                          response.data as Map<String, dynamic>;
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    } on DioException catch (e) {
                                      setDialogState(() {
                                        saving = false;
                                        error = _message(e,
                                            'Não foi possível criar o acesso. Confira os dados e tente novamente.');
                                      });
                                    }
                                  },
                            child: Text(
                                saving ? 'Criando...' : 'Criar e gerar TOTP'))
                      ]));
        });
    email.dispose();
    password.dispose();
    if (created == null || !mounted) return;
    await _showTotp(created!);
    await _refresh();
  }

  Future<void> _showTotp(Map<String, dynamic> data) => _showAdminDialog<void>(
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
      _showAdminDialog<bool>(
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
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(builder: (context, constraints) {
                final useSidebar = constraints.maxWidth >= 1020;
                return useSidebar
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            SizedBox(width: 248, child: _sidebar(scheme)),
                            const SizedBox(width: 20),
                            Expanded(child: _workspace(scheme))
                          ])
                    : Column(children: [
                        _compactHeader(scheme),
                        const SizedBox(height: 16),
                        Expanded(child: _workspace(scheme, compact: true))
                      ]);
              })))
    ]));
  }

  List<_AdminSection> get _availableSections => [
        _AdminSection.people,
        _AdminSection.reports,
        _AdminSection.stickers,
        _AdminSection.tags,
        if (_superAdmin) _AdminSection.accounts
      ];

  Widget _sidebar(ColorScheme scheme) => NeoCard(
      color: scheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: NeoBrutal.decoration(
                  color: scheme.secondary,
                  borderColor: scheme.ink,
                  offset: NeoBrutal.shadowOffsetSmall),
              child: const Text('VJ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('ADMIN',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('VJ//OPS', style: _systemText(scheme))
              ]))
        ]),
        const SizedBox(height: 24),
        Text('ÁREAS DO PAINEL', style: _systemText(scheme)),
        const SizedBox(height: 10),
        ..._availableSections.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _navButton(item, scheme))),
        const Spacer(),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.ink, width: 2)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SESSÃO ATIVA', style: _systemText(scheme)),
              const SizedBox(height: 4),
              Text(_roleLabel(widget.role),
                  style: const TextStyle(fontWeight: FontWeight.w900))
            ])),
        const SizedBox(height: 12),
        NeoOutlineButton(
            height: 44,
            icon: const Icon(Icons.key_outlined),
            onPressed: _changePassword,
            child: const Text('MINHA SENHA'))
      ]));

  Widget _compactHeader(ColorScheme scheme) => NeoCard(
      color: scheme.surface,
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('PAINEL ADMINISTRATIVO',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('VJ//COMMUNITY_OPERATIONS • ${widget.role}',
                    style: _systemText(scheme))
              ])),
          IconButton(
              tooltip: 'Alterar minha senha',
              onPressed: _changePassword,
              icon: const Icon(Icons.key_outlined))
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: _availableSections
                    .map((item) => Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: SizedBox(
                            width: 178, child: _navButton(item, scheme))))
                    .toList()))
      ]));

  Widget _navButton(_AdminSection item, ColorScheme scheme) {
    final meta = _sectionMeta(item);
    final selected = item == _section;
    return NeoButton(
        height: 46,
        color: selected ? scheme.secondary : scheme.surface,
        foregroundColor: selected ? Colors.white : scheme.ink,
        icon: Icon(meta.icon),
        trailing: Text('${meta.count}',
            style: TextStyle(
                color: selected ? Colors.white : scheme.onSurfaceVariant,
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w700)),
        onPressed: () => setState(() => _section = item),
        child: Text(meta.shortTitle));
  }

  Widget _workspace(ColorScheme scheme, {bool compact = false}) {
    final meta = _sectionMeta(_section);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meta.code, style: _systemText(scheme)),
          const SizedBox(height: 4),
          Text(meta.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: compact ? 25 : 31)),
          const SizedBox(height: 6),
          Text(meta.description,
              style: TextStyle(color: scheme.onSurfaceVariant))
        ])),
        if (_sectionAction() case final action?) ...[
          const SizedBox(width: 16),
          SizedBox(width: compact ? 156 : 190, child: action)
        ],
        const SizedBox(width: 12),
        SizedBox(
            width: 52,
            child: NeoOutlineButton(
                height: 48,
                onPressed: _loading ? null : _refresh,
                child: const Icon(Icons.refresh)))
      ]),
      if (_section == _AdminSection.people) ...[
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _searchUsers(),
                  decoration: const InputDecoration(
                      hintText: 'Buscar por nome ou e-mail',
                      prefixIcon: Icon(Icons.search)))),
          const SizedBox(width: 12),
          SizedBox(
              width: 132,
              child: NeoButton(
                  onPressed: _loading ? null : _searchUsers,
                  child: const Text('BUSCAR')))
        ])
      ],
      if (_error != null) ...[const SizedBox(height: 12), _inlineError(scheme)],
      const SizedBox(height: 18),
      Expanded(
          child: NeoCard(
              color: scheme.surface,
              padding: EdgeInsets.zero,
              child: Column(children: [
                Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                    decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        border: Border(
                            bottom: BorderSide(
                                color: scheme.ink,
                                width: NeoBrutal.borderWidth))),
                    child: Row(children: [
                      Expanded(
                          child: Text('${meta.count} ${meta.countLabel}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .2))),
                      Container(
                          width: 8,
                          height: 8,
                          color: _loading ? scheme.primary : NeoBrutal.lime),
                      const SizedBox(width: 8),
                      Text(_loading ? 'SINCRONIZANDO' : 'ATUALIZADO',
                          style: _systemText(scheme))
                    ])),
                Expanded(
                    child: _loading && meta.count == 0
                        ? const Center(
                            child: NeoLoadingIndicator(
                                label: 'CARREGANDO REGISTROS'))
                        : _sectionList(scheme))
              ])))
    ]);
  }

  Widget? _sectionAction() {
    final canManage = _superAdmin || widget.role == 'ADMIN';
    return switch (_section) {
      _AdminSection.stickers when canManage => NeoButton(
          height: 48,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          onPressed: _createStickerWithAsset,
          child: const Text('NOVA FIGURINHA')),
      _AdminSection.tags when canManage => NeoButton(
          height: 48,
          icon: const Icon(Icons.add),
          onPressed: _createTagWithFile,
          child: const Text('NOVA TAG')),
      _AdminSection.accounts when _superAdmin => NeoButton(
          height: 48,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          onPressed: _createAdmin,
          child: const Text('NOVO ACESSO')),
      _ => null
    };
  }

  Widget _sectionList(ColorScheme scheme) {
    final items = switch (_section) {
      _AdminSection.people => _users,
      _AdminSection.reports => _reports,
      _AdminSection.stickers => _stickers,
      _AdminSection.tags => _tags,
      _AdminSection.accounts => _accounts
    };
    if (items.isEmpty) return _emptyState(scheme);
    return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) => _recordRow(scheme, items[index] as Map));
  }

  Widget _recordRow(ColorScheme scheme, Map item) => switch (_section) {
        _AdminSection.people => _adminRow(scheme,
            icon: Icons.person_outline,
            title: item['fullName']?.toString() ?? 'Sem nome',
            subtitle: item['email']?.toString() ?? '',
            status: _humanStatus(item['verificationStatus']?.toString()),
            onTap: () => _personActions(item)),
        _AdminSection.reports => _adminRow(scheme,
            icon: Icons.gpp_maybe_outlined,
            title: 'Denúncia ${item['id'] != null ? '#${item['id']}' : ''}',
            subtitle:
                '${item['evidenceCount'] ?? 0} evidência(s) selecionada(s)',
            status: _humanStatus(item['status']?.toString())),
        _AdminSection.stickers => _adminRow(scheme,
            icon: Icons.emoji_emotions_outlined,
            title: item['label']?.toString() ?? 'Sem nome',
            subtitle: item['code']?.toString() ?? '',
            status: item['active'] == true ? 'ATIVA' : 'INATIVA'),
        _AdminSection.tags => _adminRow(scheme,
            leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: _tagColor(item['color']?.toString()),
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.ink, width: 2))),
            title: item['name']?.toString() ?? 'Sem nome',
            subtitle: item['color']?.toString() ?? '',
            status: 'EM USO'),
        _AdminSection.accounts => _adminRow(scheme,
            icon: Icons.admin_panel_settings_outlined,
            title: item['email']?.toString() ?? '',
            subtitle: _roleLabel(item['role']?.toString() ?? ''),
            status: item['active'] == true ? 'ATIVO' : 'INATIVO')
      };

  Widget _adminRow(ColorScheme scheme,
          {IconData? icon,
          Widget? leading,
          required String title,
          required String subtitle,
          required String status,
          VoidCallback? onTap}) =>
      Material(
          color: scheme.surface,
          child: InkWell(
              onTap: onTap,
              child: Container(
                  constraints: const BoxConstraints(minHeight: 66),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      border: Border.all(color: scheme.ink, width: 2)),
                  child: Row(children: [
                    leading ??
                        Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            color: scheme.secondary.withValues(alpha: .14),
                            child: Icon(icon, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: scheme.onSurfaceVariant, fontSize: 12))
                        ])),
                    const SizedBox(width: 12),
                    _statusPill(scheme, status),
                    if (onTap != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18)
                    ]
                  ]))));

  Widget _statusPill(ColorScheme scheme, String label) {
    final positive = label == 'ATIVO' ||
        label == 'ATIVA' ||
        label == 'VERIFICADO' ||
        label == 'RESOLVIDA';
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: positive ? NeoBrutal.lime : scheme.surfaceContainerHighest,
            border: Border.all(color: scheme.ink, width: 2),
            borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: TextStyle(
                color: NeoBrutal.inkLight,
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w700,
                fontSize: 9)));
  }

  Widget _emptyState(ColorScheme scheme) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.route_outlined, size: 36, color: scheme.tertiary),
            const SizedBox(height: 12),
            const Text('NENHUM REGISTRO AQUI',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 6),
            Text('Quando houver novidades, elas aparecerão nesta área.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant))
          ])));

  Widget _inlineError(ColorScheme scheme) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: scheme.error.withValues(alpha: .1),
          border:
              Border.all(color: scheme.error, width: NeoBrutal.borderWidth)),
      child: Row(children: [
        Icon(Icons.error_outline, color: scheme.error),
        const SizedBox(width: 10),
        Expanded(
            child: Text(_error!,
                style: TextStyle(
                    color: scheme.error, fontWeight: FontWeight.w700)))
      ]));

  _AdminSectionMeta _sectionMeta(_AdminSection section) => switch (section) {
        _AdminSection.people => _AdminSectionMeta(
            'PESSOAS',
            'PESSOAS DA COMUNIDADE',
            'VJ//PEOPLE_DIRECTORY',
            'Encontre perfis e acesse comunicação, tags e histórico.',
            'pessoas',
            Icons.people_alt_outlined,
            _users.length),
        _AdminSection.reports => _AdminSectionMeta(
            'DENÚNCIAS',
            'CENTRAL DE DENÚNCIAS',
            'VJ//TRUST_AND_SAFETY',
            'Acompanhe ocorrências e evidências enviadas pela comunidade.',
            'denúncias',
            Icons.gpp_maybe_outlined,
            _reports.length),
        _AdminSection.stickers => _AdminSectionMeta(
            'FIGURINHAS',
            'BIBLIOTECA DE FIGURINHAS',
            'VJ//CHAT_ASSETS',
            'Gerencie as reações visuais disponíveis nas conversas.',
            'figurinhas',
            Icons.emoji_emotions_outlined,
            _stickers.length),
        _AdminSection.tags => _AdminSectionMeta(
            'TAGS',
            'TAGS DE PESSOAS',
            'VJ//PROFILE_LABELS',
            'Organize identificadores visuais usados nos perfis.',
            'tags',
            Icons.sell_outlined,
            _tags.length),
        _AdminSection.accounts => _AdminSectionMeta(
            'ACESSOS',
            'ACESSOS ADMINISTRATIVOS',
            'VJ//ACCESS_CONTROL',
            'Controle quem pode operar as ferramentas administrativas.',
            'acessos',
            Icons.admin_panel_settings_outlined,
            _accounts.length)
      };

  TextStyle _systemText(ColorScheme scheme) => TextStyle(
      color: scheme.tertiary,
      fontFamily: 'IBMPlexMono',
      fontWeight: FontWeight.w700,
      letterSpacing: .7,
      fontSize: 10);

  String _humanStatus(String? value) =>
      (value ?? 'SEM STATUS').replaceAll('_', ' ').toUpperCase();

  String _roleLabel(String role) => switch (role) {
        'SUPER_ADMIN' => 'Super administrador',
        'ADMIN' => 'Administrador',
        'MODERATOR' => 'Moderador',
        _ => role
      };
}

class _AdminSectionMeta {
  const _AdminSectionMeta(this.shortTitle, this.title, this.code,
      this.description, this.countLabel, this.icon, this.count);
  final String shortTitle;
  final String title;
  final String code;
  final String description;
  final String countLabel;
  final IconData icon;
  final int count;
}

class _AdminRouteLine extends StatelessWidget {
  const _AdminRouteLine({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
        _node(),
        Expanded(child: _line()),
        _node(),
        Expanded(child: _line()),
        _node()
      ]);

  Widget _node() => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: NeoBrutal.inkLight, width: 2)));

  Widget _line() => Container(height: 2, color: color.withValues(alpha: .65));
}

Future<T?> _showAdminDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final dialogTheme = theme.copyWith(
      dialogTheme: DialogThemeData(
          backgroundColor: scheme.surface,
          elevation: 0,
          shadowColor: scheme.ink,
          titleTextStyle: theme.textTheme.titleLarge?.copyWith(
              color: scheme.ink, fontSize: 23, fontWeight: FontWeight.w900),
          contentTextStyle: theme.textTheme.bodyMedium,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
              side:
                  BorderSide(color: scheme.ink, width: NeoBrutal.borderWidth))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: scheme.ink,
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w900, letterSpacing: .5),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(NeoBrutal.borderRadius)))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w900, letterSpacing: .5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
                  side: BorderSide(
                      color: scheme.ink, width: NeoBrutal.borderWidth)))));
  return showDialog<T>(
      context: context,
      barrierColor: NeoBrutal.inkLight.withValues(alpha: .68),
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => Theme(
          data: dialogTheme,
          child: Stack(children: [
            Positioned.fill(
                child: IgnorePointer(
                    child: CustomPaint(
                        painter: _AdminDialogBackdropPainter(
                            color: scheme.tertiary)))),
            builder(dialogContext)
          ])));
}

class _AdminDialogBackdropPainter extends CustomPainter {
  const _AdminDialogBackdropPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .18)
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdminDialogBackdropPainter oldDelegate) =>
      oldDelegate.color != color;
}

String _message(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map && data['message'] is String)
    return data['message'] as String;
  return fallback;
}

Color _tagColor(String? value) =>
    Color(int.parse((value ?? '#666666').replaceFirst('#', 'FF'), radix: 16));
