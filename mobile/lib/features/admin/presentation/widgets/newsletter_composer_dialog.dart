import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/newsletter_embed.dart';
import 'newsletter_audience_dialog.dart';

/// Compositor de newsletter: título obrigatório, configurações do embed atrás
/// da engrenagem e uma lista de componentes que começa vazia. Enviar só libera
/// com título e pelo menos um componente — a mesma regra que o backend cobra.
///
/// O painel roda na web, então o upload de anexo manda os bytes para o backend
/// (`POST /admin/media`) em vez de falar direto com o R2.
Future<bool?> showNewsletterComposer({
  required BuildContext context,
  required Dio dio,
  required List<dynamic> tags,
  Map<String, dynamic>? user,
}) =>
    showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            _NewsletterComposer(dio: dio, tags: tags, preselected: user));

class _NewsletterComposer extends StatefulWidget {
  const _NewsletterComposer({required this.dio, required this.tags, this.preselected});
  final Dio dio;
  final List<dynamic> tags;
  final Map<String, dynamic>? preselected;

  @override
  State<_NewsletterComposer> createState() => _NewsletterComposerState();
}

class _NewsletterComposerState extends State<_NewsletterComposer> {
  final _title = TextEditingController();
  final _footer = TextEditingController();
  final _components = <Map<String, dynamic>>[];
  final _controllers = <String, TextEditingController>{};

  final _settings = <String, dynamic>{
    'backgroundColor': '#FFFFFF',
    'accentColor': '#D91568',
    'footer': '',
    'showDateTime': true,
    'font': 'PLEX_SANS',
  };
  late Map<String, dynamic> _audience;
  var _showSettings = false;
  var _sending = false;
  var _uploading = false;
  String? _error;
  DateTime? _scheduledFor;
  int? _reach;

  @override
  void initState() {
    super.initState();
    final user = widget.preselected;
    _audience = {
      'everyone': false,
      'profileTypes': <String>[],
      'affiliations': <String>[],
      'courses': <String>[],
      'tagIds': <String>[],
      'userIds': user == null ? <String>[] : <String>[user['id'].toString()],
      'adminRoles': <String>[],
      // Só para exibir; o backend ignora.
      'userLabels': user == null
          ? <String, String>{}
          : {user['id'].toString(): (user['fullName'] ?? user['name'] ?? '').toString()},
    };
    if (user != null) _refreshReach();
  }

  @override
  void dispose() {
    _title.dispose();
    _footer.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canSend =>
      _title.text.trim().isNotEmpty && _components.isNotEmpty && !_sending && !_uploading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final narrow = MediaQuery.sizeOf(context).width < 1080;
    return AlertDialog(
      title: Row(children: [
        Icon(Icons.campaign_outlined, color: scheme.secondary),
        const SizedBox(width: 10),
        const Expanded(
            child: Text('NOVA NEWSLETTER',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5))),
        const Text('VJ//NEWSLETTER_COMPOSER',
            style: TextStyle(
                fontFamily: 'IBMPlexMono', fontSize: 9, fontWeight: FontWeight.w700)),
      ]),
      content: SizedBox(
        width: narrow ? 760 : 1120,
        height: 660,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 5, child: _editor(scheme)),
          const SizedBox(width: 18),
          Expanded(flex: 4, child: _sidebar(scheme)),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context, false),
            child: const Text('CANCELAR')),
        FilledButton.icon(
            onPressed: _canSend ? _send : null,
            icon: Icon(_scheduledFor == null ? Icons.send : Icons.schedule),
            label: Text(_scheduledFor == null ? 'ENVIAR AGORA' : 'AGENDAR')),
      ],
    );
  }

  // ------------------------------------------------------------------ editor

  Widget _editor(ColorScheme scheme) => Column(children: [
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      labelText: 'Título da newsletter *',
                      hintText: 'Aparece no topo do embed e na notificação'))),
          const SizedBox(width: 10),
          IconButton.filledTonal(
              tooltip: 'Configurações da mensagem',
              isSelected: _showSettings,
              onPressed: () => setState(() => _showSettings = !_showSettings),
              icon: const Icon(Icons.settings_outlined)),
        ]),
        if (_showSettings) ...[const SizedBox(height: 12), _settingsPanel(scheme)],
        const SizedBox(height: 14),
        Expanded(
            child: _components.isEmpty
                ? _emptyComponents(scheme)
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: _components.length,
                    // Flutter de produção (3.35) ainda usa esta API.
                    // ignore: deprecated_member_use
                    onReorder: _reorder,
                    itemBuilder: (context, index) =>
                        _componentCard(scheme, index, key: ValueKey(_components[index]['key'])),
                  )),
        const SizedBox(height: 10),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: _uploading ? null : _addComponent,
                icon: _uploading
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: Text(_uploading ? 'ENVIANDO ANEXO...' : 'ADICIONAR COMPONENTE'))),
      ]);

  Widget _emptyComponents(ColorScheme scheme) => Container(
      width: double.infinity,
      decoration: BoxDecoration(
          border: Border.all(color: scheme.ink.withValues(alpha: .35), width: 2),
          borderRadius: BorderRadius.circular(NeoBrutal.borderRadius)),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.dashboard_customize_outlined,
            size: 34, color: scheme.ink.withValues(alpha: .4)),
        const SizedBox(height: 10),
        const Text('NENHUM COMPONENTE AINDA',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 4),
        Text('A newsletter precisa de pelo menos um.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
      ])));

  Widget _componentCard(ColorScheme scheme, int index, {required Key key}) {
    final component = _components[index];
    final type = component['type'].toString();
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(6, 8, 10, 10),
      decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.ink, width: 2),
          borderRadius: BorderRadius.circular(NeoBrutal.borderRadius)),
      child: Column(children: [
        Row(children: [
          ReorderableDragStartListener(
              index: index,
              child: const MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.drag_indicator, size: 20)))),
          Text(_label(type),
              style: const TextStyle(
                  fontFamily: 'IBMPlexMono', fontSize: 10, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
              tooltip: 'Remover',
              iconSize: 18,
              onPressed: () => setState(() => _components.removeAt(index)),
              icon: const Icon(Icons.delete_outline)),
        ]),
        _componentEditor(component, type),
      ]),
    );
  }

  Widget _componentEditor(Map<String, dynamic> component, String type) {
    switch (type) {
      case 'HEADING':
      case 'TEXT':
        return TextField(
            controller: _controller(component, 'text'),
            minLines: type == 'TEXT' ? 3 : 1,
            maxLines: type == 'TEXT' ? 8 : 2,
            onChanged: (value) => setState(() => component['text'] = value),
            decoration: InputDecoration(
                isDense: true,
                hintText: type == 'TEXT' ? 'Texto do parágrafo' : 'Texto do título'));
      case 'DIVIDER':
        return const Align(
            alignment: Alignment.centerLeft,
            child: Text('Linha separadora na cor de acento.',
                style: TextStyle(fontSize: 12)));
      case 'BUTTON':
        return Column(children: [
          TextField(
              controller: _controller(component, 'label'),
              onChanged: (value) => setState(() => component['label'] = value),
              decoration: const InputDecoration(isDense: true, hintText: 'Texto do botão')),
          const SizedBox(height: 8),
          TextField(
              controller: _controller(component, 'link'),
              onChanged: (value) => setState(() => component['link'] = value),
              decoration: const InputDecoration(
                  isDense: true, hintText: 'Link (https:// ou vaijunto://)')),
        ]);
      default:
        return Row(children: [
          const Icon(Icons.attachment, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(component['fileName']?.toString() ?? 'anexo',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          const Text('PERMANENTE',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', fontSize: 9, fontWeight: FontWeight.w700)),
        ]);
    }
  }

  Widget _settingsPanel(ColorScheme scheme) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            border: Border.all(color: scheme.ink, width: 2),
            borderRadius: BorderRadius.circular(NeoBrutal.borderRadius)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CONFIGURAÇÕES DA MENSAGEM',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _colorRow('Fundo', 'backgroundColor'),
          const SizedBox(height: 8),
          _colorRow('Linha do embed', 'accentColor'),
          const SizedBox(height: 10),
          TextField(
              controller: _footer,
              onChanged: (value) => setState(() => _settings['footer'] = value),
              decoration: const InputDecoration(
                  isDense: true, labelText: 'Mensagem de rodapé (opcional)')),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
                child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Mostrar data e hora', style: TextStyle(fontSize: 13)),
                    value: _settings['showDateTime'] == true,
                    onChanged: (value) => setState(() => _settings['showDateTime'] = value))),
            const SizedBox(width: 12),
            DropdownButton<String>(
                value: _settings['font'].toString(),
                onChanged: (value) => setState(() => _settings['font'] = value),
                items: const [
                  DropdownMenuItem(value: 'PLEX_SANS', child: Text('Plex Sans')),
                  DropdownMenuItem(value: 'PLEX_MONO', child: Text('Plex Mono')),
                  DropdownMenuItem(value: 'SYSTEM', child: Text('Sistema')),
                ]),
          ]),
        ]),
      );

  /// Paleta fixa do design system + hex livre. Deixar só color picker aberto
  /// convida a newsletter ilegível no tema escuro.
  Widget _colorRow(String label, String field) {
    const palette = [
      '#FFFFFF', '#F3F0E8', '#0E0D14', '#D91568', '#5146D8', '#00B8D9', '#B6FF3B'
    ];
    final current = _settings[field].toString();
    return Row(children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13))),
      ...palette.map((hex) => GestureDetector(
            onTap: () => setState(() => _settings[field] = hex),
            child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                    color: Color(0xFF000000 | int.parse(hex.substring(1), radix: 16)),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.ink,
                        width: current.toUpperCase() == hex ? 3 : 1))),
          )),
      Expanded(
          child: TextField(
              controller: _controllers.putIfAbsent(
                  field, () => TextEditingController(text: current)),
              onChanged: (value) {
                if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
                  setState(() => _settings[field] = value.toUpperCase());
                }
              },
              decoration: const InputDecoration(isDense: true, hintText: '#RRGGBB'))),
    ]);
  }

  // ----------------------------------------------------------------- lateral

  Widget _sidebar(ColorScheme scheme) => Column(children: [
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('PREVIEW',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono', fontSize: 10, fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        Expanded(
            child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.ink.withValues(alpha: .35), width: 2),
              borderRadius: BorderRadius.circular(NeoBrutal.borderRadius)),
          child: SingleChildScrollView(
              child: NewsletterEmbed(
                  title: _title.text.trim().isEmpty ? 'SEM TÍTULO' : _title.text.trim(),
                  components: _components,
                  settings: _settings,
                  sentAt: _scheduledFor ?? DateTime.now())),
        )),
        const SizedBox(height: 12),
        _audienceSummary(scheme),
        const SizedBox(height: 8),
        _scheduleRow(scheme),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: .12),
                  border: Border.all(color: scheme.error, width: 2)),
              child: Text(_error!,
                  style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700))),
        ],
      ]);

  Widget _audienceSummary(ColorScheme scheme) => InkWell(
        onTap: _pickAudience,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: scheme.ink, width: 2),
              borderRadius: BorderRadius.circular(NeoBrutal.borderRadius)),
          child: Row(children: [
            Icon(Icons.groups_outlined, color: scheme.secondary),
            const SizedBox(width: 10),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DESTINATÁRIOS',
                  style: TextStyle(
                      fontFamily: 'IBMPlexMono', fontSize: 9, fontWeight: FontWeight.w700)),
              Text(describeAudience(_audience, widget.tags),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              if (_reach != null)
                Text('$_reach ${_reach == 1 ? 'pessoa' : 'pessoas'} vão receber',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right),
          ]),
        ),
      );

  Widget _scheduleRow(ColorScheme scheme) => Row(children: [
        Expanded(
            child: Text(
                _scheduledFor == null
                    ? 'Envio imediato'
                    : 'Agendada para ${_formatDateTime(_scheduledFor!)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        if (_scheduledFor != null)
          TextButton(
              onPressed: () => setState(() => _scheduledFor = null),
              child: const Text('AGORA')),
        TextButton.icon(
            onPressed: _pickSchedule,
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('AGENDAR')),
      ]);

  // ------------------------------------------------------------------ ações

  /// `onReorder` entrega o índice de destino contando o item que ainda não foi
  /// removido, por isso o desconto. Existe `onReorderItem`, que já vem
  /// ajustado, mas só a partir do Flutter 3.41 — o build de produção roda na
  /// 3.35.7 (ver mobile/Dockerfile).
  void _reorder(int oldIndex, int newIndex) => setState(() {
        final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
        _components.insert(target, _components.removeAt(oldIndex));
      });

  Future<void> _addComponent() async {
    final type = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
                title: const Text('ADICIONAR COMPONENTE',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                children: [
                  _option(context, 'HEADING', Icons.title, 'Título',
                      'Uma linha de destaque dentro da mensagem.'),
                  _option(context, 'TEXT', Icons.notes, 'Texto',
                      'Um parágrafo. Pode ter vários.'),
                  _option(context, 'IMAGE', Icons.image_outlined, 'Imagem',
                      'Fica permanente, não expira em 30 dias.'),
                  _option(context, 'AUDIO', Icons.graphic_eq, 'Áudio', 'Até 10 MB.'),
                  _option(context, 'VIDEO', Icons.movie_outlined, 'Vídeo', 'Até 40 MB.'),
                  _option(context, 'DIVIDER', Icons.horizontal_rule, 'Divisor',
                      'Linha para separar assuntos.'),
                  _option(context, 'BUTTON', Icons.smart_button_outlined, 'Botão',
                      'Leva para um link ou uma tela do app.'),
                ]));
    if (type == null || !mounted) return;
    if (const {'IMAGE', 'AUDIO', 'VIDEO'}.contains(type)) {
      await _attachMedia(type);
      return;
    }
    setState(() => _components.add({
          'key': UniqueKey().toString(),
          'type': type,
          if (type == 'HEADING' || type == 'TEXT') 'text': '',
          if (type == 'BUTTON') ...{'label': '', 'link': ''},
        }));
  }

  Widget _option(BuildContext context, String value, IconData icon, String title,
          String subtitle) =>
      ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          onTap: () => Navigator.pop(context, value));

  Future<void> _attachMedia(String type) async {
    final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: switch (type) {
          'IMAGE' => FileType.image,
          'AUDIO' => FileType.audio,
          _ => FileType.video,
        });
    final files = result?.files ?? const <PlatformFile>[];
    final file = files.isEmpty ? null : files.first;
    if (file?.bytes == null || !mounted) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final form = FormData.fromMap({
        'category': 'NEWSLETTER',
        'file': MultipartFile.fromBytes(file!.bytes!, filename: file.name),
      });
      final response = await widget.dio.post('/admin/media', data: form);
      setState(() => _components.add({
            'key': UniqueKey().toString(),
            'type': type,
            'mediaId': response.data['mediaId'].toString(),
            // Só para o preview; o backend recalcula a URL na entrega.
            'url': response.data['url']?.toString(),
            'fileName': file.name,
          }));
    } on DioException catch (error) {
      setState(() => _error = _messageOf(error, 'Não foi possível enviar o anexo.'));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickAudience() async {
    final updated = await showNewsletterAudienceDialog(
        context: context, dio: widget.dio, tags: widget.tags, audience: _audience);
    if (updated == null || !mounted) return;
    setState(() => _audience = updated);
    await _refreshReach();
  }

  Future<void> _refreshReach() async {
    try {
      final response =
          await widget.dio.post('/admin/newsletters/audience', data: _payloadAudience());
      if (!mounted) return;
      setState(() => _reach = (response.data['userCount'] as num).toInt() +
          (response.data['adminCount'] as num).toInt());
    } on DioException {
      if (mounted) setState(() => _reach = null);
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: _scheduledFor ?? now.add(const Duration(hours: 1)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledFor ?? now.add(const Duration(hours: 1))));
    if (time == null || !mounted) return;
    setState(() => _scheduledFor =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.dio.post('/admin/newsletters', data: {
        'title': _title.text.trim(),
        // 'key', 'url' e 'fileName' são só do editor: a URL assinada expira e é
        // recalculada na entrega, então não faz sentido gravar.
        'components': _components
            .map((component) => Map<String, dynamic>.from(component)
              ..remove('key')
              ..remove('url')
              ..remove('fileName'))
            .toList(),
        'settings': _settings,
        'audience': _payloadAudience(),
        if (_scheduledFor != null) 'scheduledFor': _scheduledFor!.toUtc().toIso8601String(),
      });
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (error) {
      setState(() => _error = _messageOf(error, 'Não foi possível enviar a newsletter.'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Map<String, dynamic> _payloadAudience() =>
      Map<String, dynamic>.from(_audience)..remove('userLabels');

  TextEditingController _controller(Map<String, dynamic> component, String field) =>
      _controllers.putIfAbsent('${component['key']}.$field',
          () => TextEditingController(text: component[field]?.toString() ?? ''));

  static String _label(String type) => switch (type) {
        'HEADING' => 'TÍTULO',
        'TEXT' => 'TEXTO',
        'IMAGE' => 'IMAGEM',
        'AUDIO' => 'ÁUDIO',
        'VIDEO' => 'VÍDEO',
        'DIVIDER' => 'DIVISOR',
        _ => 'BOTÃO',
      };
}

String _formatDateTime(DateTime when) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(when.day)}/${two(when.month)} às ${two(when.hour)}:${two(when.minute)}';
}

String _messageOf(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map && data['message'] is String) return data['message'] as String;
  return fallback;
}
