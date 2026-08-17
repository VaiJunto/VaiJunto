import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/app_version.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/ui/neo_geometry_run_backdrop.dart';
import '../../../../core/ui/neo_loading_indicator.dart';
import '../../../../core/ui/neo_street_backdrop.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/newsletter_composer_dialog.dart';

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
                                              fontSize: 11)),
                                      const SizedBox(height: 8),
                                      _AdminBuildStamp(scheme: scheme)
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

enum _AdminSection { people, reports, newsletters, stickers, tags, accounts }

class _AdminBuildStamp extends StatelessWidget {
  const _AdminBuildStamp({required this.scheme, this.compact = false});

  final ColorScheme scheme;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: scheme.tertiary.withValues(alpha: .12),
          border: Border.all(color: scheme.tertiary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_done_outlined,
                size: compact ? 13 : 15, color: scheme.tertiary),
            const SizedBox(width: 6),
            Text(
              'BUILD $kBuildLabel',
              style: TextStyle(
                color: scheme.tertiary,
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
                fontSize: compact ? 9 : 10,
              ),
            ),
          ],
        ),
      );
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
      _accounts = [],
      _newsletters = [];
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
        dio.get('/admin/newsletters'),
        if (_superAdmin) dio.get('/admin/accounts')
      ]);
      if (mounted)
        setState(() {
          _users = responses[0].data as List<dynamic>;
          _reports = responses[1].data as List<dynamic>;
          _stickers = responses[2].data as List<dynamic>;
          _tags = responses[3].data as List<dynamic>;
          _newsletters = responses[4].data as List<dynamic>;
          _accounts = _superAdmin ? responses[5].data as List<dynamic> : [];
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
    String? fileError;
    final ok = await _showAdminDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                    title: const _AdminDialogTitle(
                        icon: Icons.emoji_emotions_outlined,
                        code: 'VJ//NEW_CHAT_ASSET',
                        title: 'CADASTRAR FIGURINHA'),
                    content: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 540, maxHeight: 610),
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: .14),
                                      border: Border.all(
                                          color:
                                              Theme.of(context).colorScheme.ink,
                                          width: 2)),
                                  child: const Row(children: [
                                    Icon(Icons.chat_bubble_outline, size: 19),
                                    SizedBox(width: 10),
                                    Expanded(
                                        child: Text(
                                            'Crie uma reação visual curta para as conversas do VaiJunto.'))
                                  ])),
                              const SizedBox(height: 18),
                              TextField(
                                  controller: label,
                                  onChanged: (_) => setDialog(() {}),
                                  decoration: const InputDecoration(
                                      labelText: 'Nome da figurinha',
                                      hintText: 'Ex.: Comemorando',
                                      prefixIcon: Icon(Icons.title_outlined))),
                              const SizedBox(height: 12),
                              TextField(
                                  controller: code,
                                  onChanged: (_) => setDialog(() {}),
                                  decoration: const InputDecoration(
                                      labelText: 'Código interno',
                                      hintText: 'Ex.: comemorando_01',
                                      helperText:
                                          'Use letras minúsculas, números e underline.',
                                      prefixIcon: Icon(Icons.code))),
                              const SizedBox(height: 18),
                              Text('ARQUIVO DA FIGURINHA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                          fontSize: 10)),
                              const SizedBox(height: 8),
                              _AdminFilePickerButton(
                                label: asset == null
                                    ? 'ESCOLHER ARQUIVO'
                                    : 'TROCAR ARQUIVO',
                                helper:
                                    'PNG • JPG • WEBP • GIF ANIMADO • ATÉ 2 MB',
                                fileName: asset?.name,
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
                                  if (result == null) return;
                                  final selected = result.files.single;
                                  setDialog(() {
                                    if (selected.size > 2 * 1024 * 1024) {
                                      asset = null;
                                      fileError =
                                          'O arquivo excede o limite de 2 MB.';
                                    } else {
                                      asset = selected;
                                      fileError = null;
                                    }
                                  });
                                },
                              ),
                              if (fileError != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(fileError!,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            fontWeight: FontWeight.w700))),
                              if (asset != null)
                                Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 14),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .ink,
                                            width: 2)),
                                    child: Row(children: [
                                      if (asset!.bytes != null)
                                        Container(
                                            width: 72,
                                            height: 72,
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .ink,
                                                    width: 2)),
                                            child: Image.memory(asset!.bytes!,
                                                fit: BoxFit.contain)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            const Text('PRÉVIA DO ASSET',
                                                style: TextStyle(
                                                    fontFamily: 'IBMPlexMono',
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 9)),
                                            const SizedBox(height: 5),
                                            Text(asset!.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w900)),
                                            const SizedBox(height: 3),
                                            Text(
                                                '${(asset!.size / 1024).toStringAsFixed(0)} KB • PRONTO PARA ENVIAR',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary,
                                                    fontFamily: 'IBMPlexMono',
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.w700))
                                          ]))
                                    ]))
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCELAR')),
                      FilledButton(
                          onPressed: asset == null ||
                                  label.text.trim().isEmpty ||
                                  code.text.trim().isEmpty
                              ? null
                              : () => Navigator.pop(context, true),
                          child: const Text('CADASTRAR FIGURINHA'))
                    ])));
    if (ok != true || asset?.bytes == null) {
      await _disposeControllersAfterDialog([code, label]);
      return;
    }
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
      await _disposeControllersAfterDialog([code, label]);
    }
  }

  Future<void> _createTagWithFile() async {
    final name = TextEditingController();
    Color color = NeoBrutal.cyan;
    PlatformFile? icon;
    final ok = await _showAdminDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                    title: const _AdminDialogTitle(
                        icon: Icons.new_label_outlined,
                        code: 'VJ//NEW_PROFILE_TAG',
                        title: 'CRIAR TAG DE PESSOA'),
                    content: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 520, maxHeight: 620),
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              TextField(
                                  controller: name,
                                  onChanged: (_) => setDialog(() {}),
                                  decoration: const InputDecoration(
                                      labelText: 'Nome da tag',
                                      hintText: 'Ex.: Motorista parceiro',
                                      prefixIcon: Icon(Icons.sell_outlined))),
                              const SizedBox(height: 20),
                              _AdminColorPicker(
                                  initialColor: color,
                                  onChanged: (next) => color = next),
                              const SizedBox(height: 20),
                              Text('ÍCONE DA TAG',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                          fontSize: 10)),
                              const SizedBox(height: 8),
                              _AdminFilePickerButton(
                                  fileName: icon?.name,
                                  helper: 'ARQUIVO SVG • VETOR • ATÉ 256 KB',
                                  onPressed: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: const ['svg'],
                                            withData: true);
                                    if (result != null) {
                                      setDialog(
                                          () => icon = result.files.single);
                                    }
                                  },
                                  label: icon == null
                                      ? 'ANEXAR ÍCONE SVG'
                                      : 'TROCAR ÍCONE SVG')
                            ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCELAR')),
                      FilledButton(
                          onPressed: icon == null || name.text.trim().isEmpty
                              ? null
                              : () => Navigator.pop(context, true),
                          child: const Text('CRIAR TAG'))
                    ])));
    if (ok != true || icon?.bytes == null) {
      await _disposeControllersAfterDialog([name]);
      return;
    }
    try {
      final svg = String.fromCharCodes(icon!.bytes!);
      await ref.read(dioProvider).post('/admin/tags', data: {
        'name': name.text.trim(),
        'color': _hexColor(color),
        'iconSvg': svg.trim()
      });
      await _refresh();
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível criar a tag.'));
    } finally {
      await _disposeControllersAfterDialog([name]);
    }
  }

  /// Abre o compositor de newsletter. [user] apenas pré-seleciona o
  /// destinatário — o público continua editável lá dentro (grupos, curso, tag,
  /// equipe administrativa).
  Future<void> _sendNewsletter([Map? user]) async {
    final sent = await showNewsletterComposer(
        context: context,
        dio: ref.read(dioProvider),
        tags: _tags,
        user: user == null ? null : Map<String, dynamic>.from(user));
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Newsletter enviada.')));
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
                  title: _AdminDialogTitle(
                      icon: Icons.sell_outlined,
                      code: 'VJ//PROFILE_LABELS',
                      title:
                          'TAGS • ${(user['fullName'] ?? 'PESSOA').toString().toUpperCase()}'),
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
                                      secondary: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                              color: _tagColor(
                                                  tag['color']?.toString()),
                                              border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .ink,
                                                  width: 2))),
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

  Future<void> _adminChatDialog3(Map user, String conversationId) async {
    final message = TextEditingController();
    // Anexos já enviados ao R2 e ainda não presos a uma mensagem.
    final attachments = <Map<String, dynamic>>[];
    var refresh = 0;
    var sending = false;
    String? sendError;
    await _showAdminDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                    title: _AdminDialogTitle(
                        icon: Icons.forum_outlined,
                        code: 'VJ//ADMIN_CHANNEL',
                        title:
                            'CHAT • ${(user['fullName'] ?? 'PESSOA').toString().toUpperCase()}'),
                    content: SizedBox(
                        width: 620,
                        height: 510,
                        child: Column(children: [
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: .14),
                                  border: Border.all(
                                      color: Theme.of(context).colorScheme.ink,
                                      width: 2)),
                              child: Row(children: [
                                Icon(Icons.shield_outlined,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    size: 19),
                                const SizedBox(width: 10),
                                const Expanded(
                                    child: Text(
                                        'CANAL OFICIAL • MENSAGENS PERMANENTES • HISTÓRICO AUDITÁVEL',
                                        style: TextStyle(
                                            fontFamily: 'IBMPlexMono',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9)))
                              ])),
                          const SizedBox(height: 12),
                          Expanded(
                              child: FutureBuilder<List<dynamic>>(
                                  key: ValueKey(refresh),
                                  future: _loadAdminMessages(conversationId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              'Não foi possível carregar o histórico.',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                  fontWeight:
                                                      FontWeight.w700)));
                                    }
                                    if (!snapshot.hasData) {
                                      return const Center(
                                          child: NeoLoadingIndicator(
                                              label: 'CARREGANDO CONVERSA'));
                                    }
                                    if (snapshot.data!.isEmpty) {
                                      return const _AdminChatEmptyState();
                                    }
                                    return ListView(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        children: snapshot.data!
                                            .map(_adminChatBubble)
                                            .toList());
                                  })),
                          if (sendError != null)
                            Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withValues(alpha: .12),
                                    border: Border.all(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        width: 2)),
                                child: Text(sendError!,
                                    style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.w700))),
                          if (attachments.isNotEmpty)
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                    spacing: 8,
                                    children: attachments
                                        .map((attachment) => InputChip(
                                            avatar: const Icon(
                                                Icons.attachment,
                                                size: 16),
                                            label: Text(
                                                attachment['fileName']
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 11)),
                                            onDeleted: () => setDialogState(
                                                () => attachments
                                                    .remove(attachment))))
                                        .toList())),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child: TextField(
                                    controller: message,
                                    enabled: !sending,
                                    decoration: const InputDecoration(
                                        labelText: 'Mensagem administrativa',
                                        hintText:
                                            'Escreva uma orientação clara',
                                        prefixIcon:
                                            Icon(Icons.chat_bubble_outline)))),
                            const SizedBox(width: 10),
                            _AdminSquareButton(
                                icon: Icons.attach_file,
                                tooltip: 'Anexar arquivo',
                                onPressed: sending
                                    ? null
                                    : () async {
                                        final attachment =
                                            await _uploadAdminAttachment();
                                        if (attachment == null) return;
                                        setDialogState(
                                            () => attachments.add(attachment));
                                      }),
                            const SizedBox(width: 10),
                            _AdminSquareButton(
                                icon: Icons.send,
                                tooltip: 'Enviar mensagem',
                                primary: true,
                                loading: sending,
                                onPressed: sending
                                    ? null
                                    : () async {
                                        if (message.text.trim().isEmpty &&
                                            attachments.isEmpty) {
                                          setDialogState(() => sendError =
                                              'Escreva uma mensagem antes de enviar.');
                                          return;
                                        }
                                        setDialogState(() {
                                          sending = true;
                                          sendError = null;
                                        });
                                        try {
                                          await ref.read(dioProvider).post(
                                              '/admin/conversations/$conversationId/messages',
                                              data: {
                                                'body': message.text.trim(),
                                                'mediaIds': attachments
                                                    .map((attachment) =>
                                                        attachment['mediaId'])
                                                    .toList()
                                              });
                                          message.clear();
                                          setDialogState(() {
                                            attachments.clear();
                                            refresh++;
                                          });
                                        } on DioException catch (e) {
                                          setDialogState(() => sendError = _message(
                                              e,
                                              'Não foi possível enviar a mensagem.'));
                                        } finally {
                                          if (context.mounted) {
                                            setDialogState(
                                                () => sending = false);
                                          }
                                        }
                                      })
                          ])
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('FECHAR'))
                    ])));
    await _disposeControllersAfterDialog([message]);
  }

  /// Sobe o arquivo já no envio da mensagem: o backend guarda como mídia
  /// administrativa permanente e só prende à mensagem quando ela é enviada.
  Future<Map<String, dynamic>?> _uploadAdminAttachment() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return null;
    try {
      final response = await ref.read(dioProvider).post('/admin/media',
          data: FormData.fromMap({
            'category': 'ADMIN_MESSAGE',
            'file':
                MultipartFile.fromBytes(file!.bytes!, filename: file.name)
          }));
      return {
        'mediaId': response.data['mediaId'].toString(),
        'fileName': file.name
      };
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível enviar o anexo.'));
      return null;
    }
  }

  Widget _adminChatBubble(dynamic m) {
    final fromAdmin = m['fromAdmin'] == true;
    final scheme = Theme.of(context).colorScheme;
    final media = (m['media'] as List?) ?? const [];
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
              if ((m['body']?.toString() ?? '').isNotEmpty)
                Text(m['body'].toString()),
              for (final attachment in media) ...[
                const SizedBox(height: 6),
                _chatAttachment(attachment as Map, scheme)
              ]
            ])));
  }

  Widget _chatAttachment(Map attachment, ColorScheme scheme) {
    final contentType = attachment['contentType']?.toString() ?? '';
    final url = attachment['url']?.toString() ?? '';
    if (contentType.startsWith('image/') && url.isNotEmpty) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
          child: Image.network(url, height: 160, fit: BoxFit.cover));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
          contentType.startsWith('audio/')
              ? Icons.graphic_eq
              : contentType.startsWith('video/')
                  ? Icons.movie_outlined
                  : Icons.attachment,
          size: 16,
          color: scheme.tertiary),
      const SizedBox(width: 6),
      Text(contentType.isEmpty ? 'anexo' : contentType,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))
    ]);
  }

  Future<List<dynamic>> _loadAdminMessages(String conversationId) async =>
      (await ref
              .read(dioProvider)
              .get('/admin/conversations/$conversationId/messages'))
          .data as List<dynamic>;

  Future<void> _personActions(Map user) async => _showAdminDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title:
                  _AdminDialogTitle(
                      icon: Icons.person_outline,
                      code: 'VJ//PERSON_ACTIONS',
                      title: user['fullName']?.toString().toUpperCase() ??
                          'PESSOA'),
              content: SizedBox(
                  width: 500,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            border: Border.all(
                                color: Theme.of(context).colorScheme.ink,
                                width: 2)),
                        child: Row(children: [
                          Icon(Icons.alternate_email,
                              color: Theme.of(context).colorScheme.tertiary,
                              size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(user['email']?.toString() ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)))
                        ])),
                    const SizedBox(height: 12),
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
                    if (user['deleted'] == true)
                      _personActionButton(
                          Icons.restore_from_trash_outlined,
                          'Restaurar conta',
                          'Devolve o acesso desta pessoa ao VaiJunto.', () {
                        Navigator.pop(context);
                        _setUserDeleted(user, delete: false);
                      })
                    else
                      _personActionButton(
                          Icons.person_remove_outlined,
                          'Excluir conta',
                          'Exclusão lógica: a pessoa perde o acesso, o histórico é preservado.',
                          () {
                        Navigator.pop(context);
                        _setUserDeleted(user, delete: true);
                      }, destructive: true),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('FECHAR'))
              ]));

  Widget _personActionButton(
          IconData icon, String title, String description, VoidCallback onTap,
          {bool destructive = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: InkWell(
                  onTap: onTap,
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: destructive
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.ink,
                              width: 2),
                          borderRadius:
                              BorderRadius.circular(NeoBrutal.borderRadius)),
                      child: Row(children: [
                        Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            color: destructive
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            child: Icon(icon, color: Colors.white, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(title.toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13)),
                              const SizedBox(height: 3),
                              Text(description,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 12))
                            ])),
                        const Icon(Icons.arrow_forward, size: 18)
                      ])))));

  /// Exclusão lógica da conta de uma pessoa da comunidade (e o desfazer dela).
  ///
  /// Nada é apagado no banco: a conta perde o login e fica marcada como
  /// excluída, porque caronas, denúncias e mensagens antigas continuam
  /// apontando para ela.
  Future<void> _setUserDeleted(Map user, {required bool delete}) async {
    final reason = TextEditingController();
    final name = user['fullName']?.toString() ?? 'esta pessoa';
    final confirmed = await _confirmDialog(
        icon: delete
            ? Icons.person_remove_outlined
            : Icons.restore_from_trash_outlined,
        code: delete ? 'VJ//ACCOUNT_SOFT_DELETE' : 'VJ//ACCOUNT_RESTORE',
        title: delete ? 'EXCLUIR CONTA' : 'RESTAURAR CONTA',
        message: delete
            ? '$name perde o acesso ao VaiJunto imediatamente. O histórico é preservado e a conta pode ser restaurada depois.'
            : '$name volta a conseguir entrar no VaiJunto.',
        confirmLabel: delete ? 'EXCLUIR CONTA' : 'RESTAURAR',
        destructive: delete,
        reason: delete ? reason : null);
    if (confirmed != true) {
      await _disposeControllersAfterDialog([reason]);
      return;
    }
    try {
      final response = await ref
          .read(dioProvider)
          .post('/admin/users/${user['id']}/deletion', data: {
        'action': delete ? 'DELETE' : 'RESTORE',
        'reason': reason.text.trim()
      });
      if (mounted) {
        final updated = response.data as Map;
        setState(() => user.addAll(updated));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(delete
                ? 'Conta de $name excluída.'
                : 'Conta de $name restaurada.')));
      }
      await _refresh();
    } on DioException catch (e) {
      _showError(_message(
          e,
          delete
              ? 'Não foi possível excluir a conta.'
              : 'Não foi possível restaurar a conta.'));
    } finally {
      await _disposeControllersAfterDialog([reason]);
    }
  }

  /// Exclusão lógica de um acesso administrativo: a linha continua no banco
  /// porque a auditoria aponta para ela, mas o login deixa de funcionar.
  Future<void> _accountActions(Map account) async {
    final active = account['active'] == true;
    final address = account['email']?.toString() ?? '';
    await _showAdminDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: _AdminDialogTitle(
                    icon: Icons.admin_panel_settings_outlined,
                    code: 'VJ//ACCESS_CONTROL',
                    title: address.toUpperCase()),
                content: SizedBox(
                    width: 500,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.ink,
                                  width: 2)),
                          child: Row(children: [
                            Icon(Icons.shield_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.tertiary),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    '${_roleLabel(account['role']?.toString() ?? '')} • ${active ? 'ativo' : 'excluído'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)))
                          ])),
                      const SizedBox(height: 16),
                      if (active)
                        _personActionButton(
                            Icons.person_remove_outlined,
                            'Excluir acesso',
                            'Exclusão lógica: o login para de funcionar e a auditoria é preservada.',
                            () {
                          Navigator.pop(context);
                          _setAccountActive(account, active: false);
                        }, destructive: true)
                      else
                        _personActionButton(
                            Icons.restore_from_trash_outlined,
                            'Restaurar acesso',
                            'Devolve a este e-mail a entrada no painel administrativo.',
                            () {
                          Navigator.pop(context);
                          _setAccountActive(account, active: true);
                        })
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('FECHAR'))
                ]));
  }

  Future<void> _setAccountActive(Map account, {required bool active}) async {
    final address = account['email']?.toString() ?? 'este acesso';
    final confirmed = await _confirmDialog(
        icon: active
            ? Icons.restore_from_trash_outlined
            : Icons.person_remove_outlined,
        code: 'VJ//ACCESS_CONTROL',
        title: active ? 'RESTAURAR ACESSO' : 'EXCLUIR ACESSO',
        message: active
            ? '$address volta a conseguir entrar no painel administrativo.'
            : '$address perde o acesso ao painel imediatamente. O registro e a auditoria são preservados.',
        confirmLabel: active ? 'RESTAURAR' : 'EXCLUIR ACESSO',
        destructive: !active);
    if (confirmed != true) return;
    try {
      final dio = ref.read(dioProvider);
      final id = account['id'];
      if (active) {
        await dio.post('/admin/accounts/$id/restore');
      } else {
        await dio.delete('/admin/accounts/$id');
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(active
                ? 'Acesso de $address restaurado.'
                : 'Acesso de $address excluído.')));
      await _refresh();
    } on DioException catch (e) {
      _showError(_message(
          e,
          active
              ? 'Não foi possível restaurar o acesso.'
              : 'Não foi possível excluir o acesso.'));
    }
  }

  /// Confirmação de ação sensível, com motivo obrigatório quando o backend pede.
  Future<bool?> _confirmDialog(
          {required IconData icon,
          required String code,
          required String title,
          required String message,
          required String confirmLabel,
          bool destructive = false,
          TextEditingController? reason}) =>
      _showAdminDialog<bool>(
          context: context,
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                        title: _AdminDialogTitle(
                            icon: icon, code: code, title: title),
                        content: SizedBox(
                            width: 460,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: (destructive
                                                  ? scheme.error
                                                  : scheme.secondary)
                                              .withValues(alpha: .12),
                                          border: Border.all(
                                              color: destructive
                                                  ? scheme.error
                                                  : scheme.ink,
                                              width: 2)),
                                      child: Text(message)),
                                  if (reason != null) ...[
                                    const SizedBox(height: 16),
                                    TextField(
                                        controller: reason,
                                        autofocus: true,
                                        minLines: 2,
                                        maxLines: 4,
                                        onChanged: (_) => setDialogState(() {}),
                                        decoration: const InputDecoration(
                                            labelText: 'Motivo da decisão',
                                            helperText:
                                                'Fica registrado no histórico administrativo.'))
                                  ]
                                ])),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('CANCELAR')),
                          FilledButton(
                              style: destructive
                                  ? FilledButton.styleFrom(
                                      backgroundColor: scheme.error,
                                      foregroundColor: Colors.white)
                                  : null,
                              onPressed:
                                  reason != null && reason.text.trim().isEmpty
                                      ? null
                                      : () => Navigator.pop(context, true),
                              child: Text(confirmLabel))
                        ]));
          });

  /// Criação de acesso administrativo em duas etapas.
  ///
  /// A conta **não** é gravada no passo do formulário: o backend só devolve um
  /// segredo TOTP de rascunho (`/admin/accounts/preview`). Ela passa a existir
  /// quando quem está criando digita um código válido lido do autenticador — sem
  /// isso, sairíamos daqui com um acesso que ninguém consegue usar para logar.
  Future<void> _createAdmin() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final totp = TextEditingController();
    var createdEmail = '';
    await _showAdminDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          String role = 'ADMIN';
          String? error;
          bool busy = false;
          Map<String, dynamic>? draft;
          return StatefulBuilder(builder: (context, setDialogState) {
            final scheme = Theme.of(context).colorScheme;

            Future<void> requestDraft() async {
              if (email.text.trim().isEmpty || password.text.length < 12) {
                setDialogState(() =>
                    error = 'Revise os campos destacados antes de gerar o QR.');
                return;
              }
              setDialogState(() {
                busy = true;
                error = null;
              });
              try {
                final response = await ref
                    .read(dioProvider)
                    .post('/admin/accounts/preview', data: {
                  'email': email.text.trim(),
                  'password': password.text,
                  'role': role
                });
                setDialogState(() {
                  draft = response.data as Map<String, dynamic>;
                  busy = false;
                });
              } on DioException catch (e) {
                setDialogState(() {
                  busy = false;
                  error = _message(e,
                      'Não foi possível preparar o acesso. Confira os dados e tente novamente.');
                });
              }
            }

            Future<void> confirmAndCreate() async {
              if (totp.text.trim().length != 6) {
                setDialogState(() => error =
                    'Digite os 6 dígitos que aparecem no autenticador.');
                return;
              }
              setDialogState(() {
                busy = true;
                error = null;
              });
              try {
                await ref.read(dioProvider).post('/admin/accounts', data: {
                  'email': email.text.trim(),
                  'password': password.text,
                  'role': role,
                  'totpSecret': draft!['totpSecret'],
                  'totpCode': totp.text.trim()
                });
                createdEmail = email.text.trim();
                if (context.mounted) Navigator.pop(context);
              } on DioException catch (e) {
                setDialogState(() {
                  busy = false;
                  error = _message(e,
                      'Não foi possível confirmar o código. A conta ainda não foi criada.');
                });
              }
            }

            return AlertDialog(
                title: _AdminDialogTitle(
                    icon: draft == null
                        ? Icons.person_add_alt_1_outlined
                        : Icons.qr_code_2_outlined,
                    code: draft == null
                        ? 'VJ//NEW_ADMIN_ACCESS'
                        : 'VJ//AUTHENTICATOR_HANDSHAKE',
                    title: draft == null
                        ? 'CRIAR ACESSO ADMINISTRATIVO'
                        : 'CONFIRMAR AUTENTICADOR'),
                content: SizedBox(
                    width: 480,
                    child: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          _adminStepTrail(scheme, draft == null ? 0 : 1),
                          const SizedBox(height: 16),
                          if (draft == null)
                            ..._createAdminForm(
                                scheme: scheme,
                                email: email,
                                password: password,
                                role: role,
                                busy: busy,
                                showErrors: error != null,
                                onRole: (value) => setDialogState(() {
                                      role = value;
                                      error = null;
                                    }))
                          else
                            ..._createAdminConfirmation(
                                scheme: scheme,
                                draft: draft!,
                                totp: totp,
                                busy: busy,
                                onChanged: () => setDialogState(() {})),
                          if (error != null)
                            Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 14),
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                    color: scheme.error.withValues(alpha: .12),
                                    border: Border.all(
                                        color: scheme.error, width: 2)),
                                child: Row(children: [
                                  Icon(Icons.error_outline,
                                      color: scheme.error, size: 19),
                                  const SizedBox(width: 9),
                                  Expanded(
                                      child: Text(error!,
                                          style: TextStyle(
                                              color: scheme.error,
                                              fontWeight: FontWeight.w700)))
                                ]))
                        ]))),
                actions: [
                  TextButton(
                      onPressed: busy
                          ? null
                          : draft == null
                              ? () => Navigator.pop(context)
                              : () => setDialogState(() {
                                    draft = null;
                                    totp.clear();
                                    error = null;
                                  }),
                      child: Text(draft == null ? 'CANCELAR' : 'VOLTAR')),
                  FilledButton(
                      onPressed: busy
                          ? null
                          : draft == null
                              ? requestDraft
                              : confirmAndCreate,
                      child: Text(busy
                          ? 'AGUARDE...'
                          : draft == null
                              ? 'GERAR QR'
                              : 'CONFIRMAR E CRIAR'))
                ]);
          });
        });
    await _disposeControllersAfterDialog([email, password, totp]);
    if (createdEmail.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Acesso de $createdEmail criado e validado.')));
    await _refresh();
  }

  List<Widget> _createAdminForm(
          {required ColorScheme scheme,
          required TextEditingController email,
          required TextEditingController password,
          required String role,
          required bool busy,
          required bool showErrors,
          required ValueChanged<String> onRole}) =>
      [
        const Text(
            'A pessoa receberá um acesso protegido por senha e autenticador. Escolha somente o nível necessário.'),
        const SizedBox(height: 16),
        TextField(
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                labelText: 'E-mail do responsável',
                prefixIcon: const Icon(Icons.alternate_email),
                errorText: showErrors && email.text.trim().isEmpty
                    ? 'Informe o e-mail.'
                    : null)),
        const SizedBox(height: 12),
        TextField(
            controller: password,
            enabled: !busy,
            obscureText: true,
            decoration: InputDecoration(
                labelText: 'Senha inicial',
                prefixIcon: const Icon(Icons.key_outlined),
                helperText: 'Use pelo menos 12 caracteres.',
                errorText: showErrors && password.text.length < 12
                    ? 'A senha precisa ter 12 caracteres.'
                    : null)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
            initialValue: role,
            items: const [
              DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
              DropdownMenuItem(value: 'MODERATOR', child: Text('Moderador'))
            ],
            onChanged: busy ? null : (value) => onRole(value!),
            decoration: const InputDecoration(
                labelText: 'Nível de acesso',
                prefixIcon: Icon(Icons.shield_outlined))),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.ink, width: 2)),
            child: Row(children: [
              Icon(Icons.info_outline, size: 19, color: scheme.tertiary),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(role == 'ADMIN'
                      ? 'Administrador: gerencia pessoas, tags, comunicações, figurinhas e contas administrativas. Não pode criar Super Admin.'
                      : 'Moderador: cuida de denúncias e da segurança das pessoas. Não cria contas, tags ou configurações do sistema.'))
            ]))
      ];

  List<Widget> _createAdminConfirmation(
          {required ColorScheme scheme,
          required Map<String, dynamic> draft,
          required TextEditingController totp,
          required bool busy,
          required VoidCallback onChanged}) =>
      [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: .14),
                border: Border.all(color: scheme.ink, width: 2)),
            child: Row(children: [
              Icon(Icons.pending_outlined, size: 19, color: scheme.secondary),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text(
                      'A conta ainda NÃO foi criada. Escaneie o QR, digite o código gerado e só então o acesso passa a existir.'))
            ])),
        const SizedBox(height: 16),
        Center(child: _AdminQrCard(uri: draft['totpUri'] as String)),
        const SizedBox(height: 14),
        Text('CHAVE MANUAL',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.tertiary, fontSize: 9)),
        const SizedBox(height: 6),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.ink, width: 2)),
            child: SelectableText(draft['totpSecret'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1.2))),
        const SizedBox(height: 6),
        Center(
            child: Text(draft['email'] as String,
                style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700))),
        const SizedBox(height: 16),
        TextField(
            controller: totp,
            enabled: !busy,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
                labelText: 'Código do autenticador',
                counterText: '',
                helperText: 'Seis dígitos, válidos por 30 segundos.',
                prefixIcon: Icon(Icons.pin_outlined)))
      ];

  /// Trilha "01 → 02" das duas etapas, no mesmo vocabulário de nós de rota do app.
  Widget _adminStepTrail(ColorScheme scheme, int current) {
    Widget step(int index, String label) {
      final active = index <= current;
      return Expanded(
          child: Row(children: [
        Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: active ? scheme.secondary : scheme.surface,
                border: Border.all(color: scheme.ink, width: 2)),
            child: Text('0${index + 1}',
                style: TextStyle(
                    color: active ? Colors.white : scheme.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontWeight: FontWeight.w700,
                    fontSize: 10))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: active ? scheme.ink : scheme.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontWeight: FontWeight.w700,
                    fontSize: 9)))
      ]));
    }

    return Row(children: [
      step(0, 'DADOS'),
      Container(width: 22, height: 2, color: scheme.tertiary),
      const SizedBox(width: 8),
      step(1, 'AUTENTICADOR')
    ]);
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final totp = TextEditingController();
    final ok = await _formDialog(
        'Alterar minha senha',
        [
          TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Senha atual',
                  prefixIcon: Icon(Icons.lock_outline))),
          TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Nova senha (mín. 12 caracteres)',
                  prefixIcon: Icon(Icons.key_outlined))),
          TextField(
              controller: totp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Código TOTP',
                  prefixIcon: Icon(Icons.pin_outlined)))
        ],
        icon: Icons.password_outlined,
        code: 'VJ//CREDENTIAL_ROTATION');
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

  Future<bool?> _formDialog(String title, List<Widget> fields,
          {IconData icon = Icons.edit_note_outlined,
          String code = 'VJ//ADMIN_FORM'}) =>
      _showAdminDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: _AdminDialogTitle(
                      icon: icon, code: code, title: title.toUpperCase()),
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
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              _AdminBuildStamp(scheme: scheme, compact: true)
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
                    style: _systemText(scheme)),
                const SizedBox(height: 5),
                _AdminBuildStamp(scheme: scheme, compact: true)
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
        icon: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: selected ? Colors.white : scheme.secondary,
                border: Border.all(color: scheme.ink, width: 2)),
            child: Icon(meta.icon,
                color: selected ? scheme.secondary : Colors.white, size: 17)),
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
        _AdminSquareButton(
            icon: Icons.refresh,
            tooltip: 'Atualizar dados',
            onPressed: _loading ? null : _refresh)
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
                // A corrida geométrica fica atrás da lista: preenche o vazio
                // quando há poucos registros e some sob as linhas (opacas)
                // quando a lista enche. O título da seção está fora do card,
                // então continua sobre fundo limpo.
                Expanded(
                    child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(3)),
                        child: Stack(children: [
                          const Positioned.fill(
                              child: NeoGeometryRunBackdrop()),
                          Positioned.fill(
                              child: _loading && meta.count == 0
                                  ? const Center(
                                      child: NeoLoadingIndicator(
                                          label: 'CARREGANDO REGISTROS'))
                                  : _sectionList(scheme))
                        ])))
              ])))
    ]);
  }

  Widget? _sectionAction() {
    final canManage = _superAdmin || widget.role == 'ADMIN';
    return switch (_section) {
      _AdminSection.stickers when canManage => NeoButton(
          height: 48,
          icon:
              const _AdminActionIcon(icon: Icons.add_photo_alternate_outlined),
          onPressed: _createStickerWithAsset,
          child: const Text('NOVA FIGURINHA')),
      _AdminSection.tags when canManage => NeoButton(
          height: 48,
          icon: const _AdminActionIcon(icon: Icons.add),
          onPressed: _createTagWithFile,
          child: const Text('NOVA TAG')),
      _AdminSection.newsletters => NeoButton(
          height: 48,
          icon: const _AdminActionIcon(icon: Icons.campaign_outlined),
          onPressed: () => _sendNewsletter(),
          child: const Text('NOVA NEWSLETTER')),
      _AdminSection.accounts when _superAdmin => NeoButton(
          height: 48,
          icon: const _AdminActionIcon(icon: Icons.person_add_alt_1_outlined),
          onPressed: _createAdmin,
          child: const Text('NOVO ACESSO')),
      _ => null
    };
  }

  Widget _sectionList(ColorScheme scheme) {
    final items = switch (_section) {
      _AdminSection.people => _users,
      _AdminSection.reports => _reports,
      _AdminSection.newsletters => _newsletters,
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
            icon: item['deleted'] == true
                ? Icons.person_off_outlined
                : Icons.person_outline,
            title: item['fullName']?.toString() ?? 'Sem nome',
            subtitle: item['email']?.toString() ?? '',
            status: item['deleted'] == true
                ? 'EXCLUÍDA'
                : _humanStatus(item['verificationStatus']?.toString()),
            onTap: () => _personActions(item)),
        _AdminSection.reports => _adminRow(scheme,
            icon: Icons.gpp_maybe_outlined,
            title: 'Denúncia ${item['id'] != null ? '#${item['id']}' : ''}',
            subtitle:
                '${item['evidenceCount'] ?? 0} evidência(s) selecionada(s)',
            status: _humanStatus(item['status']?.toString())),
        _AdminSection.newsletters => _adminRow(scheme,
            icon: Icons.campaign_outlined,
            title: item['title']?.toString() ?? 'Sem título',
            subtitle: _newsletterSubtitle(item),
            status: _humanStatus(item['status']?.toString()),
            onTap: item['status'] == 'SCHEDULED'
                ? () => _cancelNewsletter(item)
                : null),
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
            icon: item['active'] == true
                ? Icons.admin_panel_settings_outlined
                : Icons.person_off_outlined,
            title: item['email']?.toString() ?? '',
            subtitle: _roleLabel(item['role']?.toString() ?? ''),
            status: item['active'] == true ? 'ATIVO' : 'EXCLUÍDO',
            onTap: _superAdmin ? () => _accountActions(item) : null)
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
                            decoration: BoxDecoration(
                                color: scheme.secondary,
                                border:
                                    Border.all(color: scheme.ink, width: 2)),
                            child: Icon(icon, size: 20, color: Colors.white)),
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
                color: positive ? NeoBrutal.inkLight : scheme.ink,
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
        _AdminSection.newsletters => _AdminSectionMeta(
            'NEWSLETTERS',
            'NEWSLETTERS',
            'VJ//BROADCAST',
            'Monte comunicações em embed e escolha quem recebe.',
            'newsletters',
            Icons.campaign_outlined,
            _newsletters.length),
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

  String _newsletterSubtitle(Map item) {
    final recipients = item['recipientCount'] ?? 0;
    if (item['status'] == 'SCHEDULED') {
      final when = DateTime.tryParse(item['scheduledFor']?.toString() ?? '');
      return when == null
          ? 'Agendada'
          : 'Agendada para ${when.toLocal()}'.split('.').first;
    }
    if (item['status'] == 'FAILED') {
      return item['failureReason']?.toString() ?? 'Falhou no envio.';
    }
    return '$recipients destinatário(s) • ${item['readCount'] ?? 0} leram';
  }

  Future<void> _cancelNewsletter(Map item) async {
    final confirmed = await _confirmDialog(
        icon: Icons.campaign_outlined,
        code: 'VJ//BROADCAST_CANCEL',
        title: 'CANCELAR ENVIO AGENDADO?',
        message: 'A newsletter "${item['title']}" não será enviada.',
        confirmLabel: 'CANCELAR ENVIO',
        destructive: true);
    if (confirmed != true) return;
    try {
      await ref.read(dioProvider).post('/admin/newsletters/${item['id']}/cancel');
      await _refresh();
    } on DioException catch (e) {
      _showError(_message(e, 'Não foi possível cancelar a newsletter.'));
    }
  }

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

class _AdminActionIcon extends StatelessWidget {
  const _AdminActionIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      color: Colors.white,
      child:
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18));
}

/// QR sempre sobre papel branco com módulos pretos.
///
/// O `QrImageView` nasce com fundo transparente, então no tema escuro o código
/// ficava preto sobre superfície escura — ilegível para a câmera do celular. A
/// leitura depende do contraste, não do tema do painel.
class _AdminQrCard extends StatelessWidget {
  const _AdminQrCard({required this.uri});
  final String uri;

  @override
  Widget build(BuildContext context) => Container(
      decoration: NeoBrutal.decoration(
          color: Colors.white,
          borderColor: Theme.of(context).colorScheme.ink,
          offset: NeoBrutal.shadowOffsetSmall),
      padding: const EdgeInsets.all(10),
      child: QrImageView(
          data: uri,
          size: 200,
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
          eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square, color: NeoBrutal.inkLight),
          dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: NeoBrutal.inkLight)));
}

class _AdminSquareButton extends StatefulWidget {
  const _AdminSquareButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.primary = false,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool primary;
  final bool loading;

  @override
  State<_AdminSquareButton> createState() => _AdminSquareButtonState();
}

class _AdminSquareButtonState extends State<_AdminSquareButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final background = widget.primary ? scheme.primary : scheme.surface;
    final foreground = widget.primary ? Colors.white : scheme.ink;
    return Tooltip(
        message: widget.tooltip,
        child: Semantics(
            button: true,
            label: widget.tooltip,
            enabled: enabled,
            child: GestureDetector(
                onTapDown:
                    enabled ? (_) => setState(() => _pressed = true) : null,
                onTapUp:
                    enabled ? (_) => setState(() => _pressed = false) : null,
                onTapCancel:
                    enabled ? () => setState(() => _pressed = false) : null,
                onTap: widget.onPressed,
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 70),
                    width: 52,
                    height: 48,
                    margin: EdgeInsets.only(
                        left: _pressed ? NeoBrutal.shadowOffset.dx : 0,
                        top: _pressed ? NeoBrutal.shadowOffset.dy : 0),
                    decoration: NeoBrutal.decoration(
                        color: enabled
                            ? background
                            : background.withValues(alpha: .45),
                        borderColor: scheme.ink,
                        pressed: _pressed),
                    child: Icon(widget.loading ? Icons.more_horiz : widget.icon,
                        color: foreground, size: 22)))));
  }
}

class _AdminDialogTitle extends StatelessWidget {
  const _AdminDialogTitle(
      {required this.icon, required this.code, required this.title});

  final IconData icon;
  final String code;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: scheme.secondary,
              border: Border.all(color: scheme.ink, width: 2)),
          child: Icon(icon, color: Colors.white, size: 23)),
      const SizedBox(width: 14),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(code,
            style: TextStyle(
                color: scheme.tertiary,
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: .7)),
        const SizedBox(height: 4),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontSize: 21, fontWeight: FontWeight.w900))
      ]))
    ]);
  }
}

class _AdminFilePickerButton extends StatelessWidget {
  const _AdminFilePickerButton({
    required this.label,
    required this.helper,
    required this.onPressed,
    this.fileName,
  });

  final String label;
  final String helper;
  final String? fileName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: onPressed,
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: NeoBrutal.decoration(
                    color: scheme.surfaceContainerHighest,
                    borderColor: scheme.ink,
                    offset: NeoBrutal.shadowOffsetSmall),
                child: Row(children: [
                  Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      color: scheme.primary,
                      child: const Icon(Icons.upload_file_outlined,
                          color: Colors.white, size: 23)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(fileName ?? helper,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: fileName == null
                                    ? scheme.onSurfaceVariant
                                    : scheme.tertiary,
                                fontFamily: 'IBMPlexMono',
                                fontWeight: FontWeight.w700,
                                fontSize: 9))
                      ])),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 19)
                ]))));
  }
}

class _AdminColorPicker extends StatefulWidget {
  const _AdminColorPicker(
      {required this.initialColor, required this.onChanged});
  final Color initialColor;
  final ValueChanged<Color> onChanged;

  @override
  State<_AdminColorPicker> createState() => _AdminColorPickerState();
}

class _AdminColorPickerState extends State<_AdminColorPicker> {
  static const _presets = [
    Color(0xFF00B8D9),
    Color(0xFFD91568),
    Color(0xFF9C27B0),
    Color(0xFF5146D8),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFFF3B3B),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF111827),
  ];

  late Color _selected = widget.initialColor;
  late final TextEditingController _hex =
      TextEditingController(text: _hexColor(widget.initialColor));
  bool _showCustom = false;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _select(Color color, {bool syncText = true}) {
    setState(() {
      _selected = color;
      if (syncText) _hex.text = _hexColor(color);
    });
    widget.onChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('COR DA TAG',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: scheme.tertiary, fontSize: 10)),
      const SizedBox(height: 4),
      Text('Escolha uma cor pronta ou crie a sua.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
      const SizedBox(height: 10),
      Wrap(spacing: 9, runSpacing: 9, children: [
        ..._presets.map((color) => _colorTile(color)),
        Tooltip(
            message: 'Criar cor personalizada',
            child: InkWell(
                onTap: () => setState(() => _showCustom = !_showCustom),
                child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _showCustom ? scheme.primary : scheme.surface,
                        border: Border.all(color: scheme.ink, width: 2)),
                    child: Icon(Icons.add,
                        color: _showCustom ? Colors.white : scheme.ink,
                        size: 21))))
      ]),
      if (_showCustom) ...[
        const SizedBox(height: 14),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: scheme.ink, width: 2)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('COR PERSONALIZADA',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: scheme.tertiary, fontSize: 9)),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        color: _selected,
                        border: Border.all(color: scheme.ink, width: 3))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        controller: _hex,
                        maxLength: 7,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                            labelText: 'Código hexadecimal',
                            hintText: '#00B8D9',
                            counterText: '',
                            prefixIcon: Icon(Icons.tag)),
                        onChanged: (value) {
                          final parsed = _tryParseHex(value);
                          if (parsed != null) _select(parsed, syncText: false);
                        }))
              ]),
              const SizedBox(height: 12),
              Text('SELETOR VISUAL',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: scheme.tertiary, fontSize: 9)),
              const SizedBox(height: 4),
              Text('Arraste no quadro para o tom e na faixa para a matiz.',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
              const SizedBox(height: 8),
              _NeoColorField(
                  color: _selected,
                  onChanged: (next) => _select(next, syncText: true))
            ]))
      ]
    ]);
  }

  Widget _colorTile(Color color) {
    final scheme = Theme.of(context).colorScheme;
    final selected = color.toARGB32() == _selected.toARGB32();
    return Semantics(
        button: true,
        selected: selected,
        label: 'Cor ${_hexColor(color)}',
        child: InkWell(
            onTap: () => _select(color),
            child: Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: selected ? scheme.ink : Colors.transparent,
                    border: Border.all(color: scheme.ink, width: 2)),
                child: Container(
                    decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                            color: selected ? Colors.white : color,
                            width: 2))))));
  }
}

/// Seletor contínuo de cor: quadro de saturação/brilho + faixa de matiz, ambos
/// de arrastar. Substitui a grade de amostras fixas, que só alcançava 36 cores.
class _NeoColorField extends StatefulWidget {
  const _NeoColorField({required this.color, required this.onChanged});
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_NeoColorField> createState() => _NeoColorFieldState();
}

class _NeoColorFieldState extends State<_NeoColorField> {
  late HSVColor _hsv = HSVColor.fromColor(widget.color);

  @override
  void didUpdateWidget(_NeoColorField old) {
    super.didUpdateWidget(old);
    // Só reposiciona os thumbs quando a cor chegou de fora (campo hexadecimal,
    // amostra pronta). Reagir ao nosso próprio arrasto faria a matiz saltar para
    // 0 sempre que o usuário passasse pelo branco ou pelo preto, onde o HSV da
    // cor não guarda mais o ângulo.
    if (widget.color.toARGB32() != _hsv.toColor().toARGB32()) {
      _hsv = HSVColor.fromColor(widget.color);
    }
  }

  void _emit(HSVColor next) {
    setState(() => _hsv = next);
    widget.onChanged(next.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hueColor = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 148.0;
        void pick(Offset position) => _emit(_hsv
            .withSaturation((position.dx / width).clamp(0.0, 1.0))
            .withValue((1 - position.dy / height).clamp(0.0, 1.0)));
        return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) => pick(details.localPosition),
            onPanUpdate: (details) => pick(details.localPosition),
            child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                    border: Border.all(color: scheme.ink, width: 2)),
                child: Stack(children: [
                  Positioned.fill(
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [Colors.white, hueColor])))),
                  const Positioned.fill(
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                        Colors.transparent,
                        Colors.black
                      ])))),
                  Positioned(
                      left: _hsv.saturation * width - 11,
                      top: (1 - _hsv.value) * height - 11,
                      child: _thumb(scheme, _hsv.toColor()))
                ])));
      }),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        void pick(Offset position) =>
            _emit(_hsv.withHue(((position.dx / width).clamp(0.0, 1.0)) * 360));
        return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) => pick(details.localPosition),
            onPanUpdate: (details) => pick(details.localPosition),
            child: Container(
                width: width,
                height: 30,
                decoration: BoxDecoration(
                    border: Border.all(color: scheme.ink, width: 2),
                    gradient: LinearGradient(
                        colors: List.generate(
                            13,
                            (index) =>
                                HSVColor.fromAHSV(1, index * 30.0 % 360, 1, 1)
                                    .toColor()))),
                child: Stack(children: [
                  Positioned(
                      left: (_hsv.hue / 360) * width - 11,
                      top: -1,
                      child: _thumb(scheme, hueColor))
                ])));
      })
    ]);
  }

  Widget _thumb(ColorScheme scheme, Color color) => Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: scheme.ink, offset: const Offset(1, 1))
          ]));
}

class _AdminChatEmptyState extends StatelessWidget {
  const _AdminChatEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          color: scheme.secondary,
          child: const Icon(Icons.mark_chat_unread_outlined,
              color: Colors.white, size: 25)),
      const SizedBox(height: 12),
      const Text('CONVERSA AINDA VAZIA',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 5),
      Text('Envie a primeira orientação para esta pessoa.',
          style: TextStyle(color: scheme.onSurfaceVariant))
    ]));
  }
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
      barrierColor: Colors.black.withValues(alpha: .82),
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) =>
          Theme(data: dialogTheme, child: builder(dialogContext)));
}

String _message(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map && data['message'] is String)
    return data['message'] as String;
  return fallback;
}

Color _tagColor(String? value) =>
    Color(int.parse((value ?? '#666666').replaceFirst('#', 'FF'), radix: 16));

String _hexColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

Color? _tryParseHex(String value) {
  final normalized = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(normalized)) return null;
  return Color(int.parse('FF$normalized', radix: 16));
}

Future<void> _disposeControllersAfterDialog(
    List<TextEditingController> controllers) async {
  await Future<void>.delayed(const Duration(milliseconds: 250));
  for (final controller in controllers) {
    controller.dispose();
  }
}
