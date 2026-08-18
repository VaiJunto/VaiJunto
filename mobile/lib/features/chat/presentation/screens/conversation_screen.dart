import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../providers/conversation_provider.dart';
import '../../data/services/offline_message_queue.dart';
import '../../data/repositories/media_repository.dart';
import '../../../tracking/data/services/stomp_client_service.dart';
import '../widgets/location_actions.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversation});
  final ConversationModel conversation;
  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _text = TextEditingController();
  final _mediaIds = <String>[];
  final _recorder = AudioRecorder();
  bool _sending = false;
  String? _replyToId;
  String? _replyPreview;
  bool _recording = false;
  bool _recordLocked = false;
  bool _recordCanceled = false;
  DateTime? _recordingStartedAt;
  bool _otherTyping = false;
  StreamSubscription<Position>? _liveLocationSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;
  StreamSubscription<LiveLocationEvent>? _incomingLocationSubscription;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  Timer? _fallbackPollTimer;
  Timer? _liveLocationTimer;
  DateTime? _liveLocationEndsAt;
  String? _otherLiveLocation;
  int _pendingOffline = 0;
  final _reportSelection = <String>{};
  bool _reportMode = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(offlineMessageQueueProvider).flush();
      _pendingOffline = await ref
          .read(offlineMessageQueueProvider)
          .pendingFor(widget.conversation.id);
      if (mounted) setState(() {});
      ref.invalidate(conversationMessagesProvider(widget.conversation.id));
      final socket = ref.read(stompClientProvider);
      _typingSubscription = socket.typingEvents.listen((event) {
        if (mounted && event.conversationId == widget.conversation.id) {
          setState(() => _otherTyping = event.typing);
        }
      });
      _incomingLocationSubscription = socket.liveLocationEvents.listen((event) {
        if (mounted && event.conversationId == widget.conversation.id) {
          setState(() =>
              _otherLiveLocation = '${event.latitude},${event.longitude}');
        }
      });
      _realtimeSubscription = socket.events.listen((event) {
        if (event.payload['conversationId']?.toString() ==
            widget.conversation.id) {
          ref.invalidate(conversationMessagesProvider(widget.conversation.id));
          ref.invalidate(conversationsProvider);
        }
      });
      await socket.connectChat(widget.conversation.id);
      _fallbackPollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        if (!socket.isConnected && mounted) {
          ref.invalidate(conversationMessagesProvider(widget.conversation.id));
        }
      });
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _liveLocationSubscription?.cancel();
    _typingSubscription?.cancel();
    _incomingLocationSubscription?.cancel();
    _realtimeSubscription?.cancel();
    _fallbackPollTimer?.cancel();
    _liveLocationTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if ((body.isEmpty && _mediaIds.isEmpty) ||
        _sending ||
        widget.conversation.readOnly) {
      return;
    }
    final draft = ChatMessageDraft(_uuid(), body,
        mediaIds: List.of(_mediaIds), replyToId: _replyToId);
    setState(() => _sending = true);
    try {
      await ref
          .read(conversationRepositoryProvider)
          .send(widget.conversation.id, draft);
      _text.clear();
      _mediaIds.clear();
      _replyToId = null;
      _replyPreview = null;
      ref.invalidate(conversationMessagesProvider(widget.conversation.id));
    } catch (_) {
      await ref
          .read(offlineMessageQueueProvider)
          .enqueue(widget.conversation.id, draft);
      _pendingOffline = await ref
          .read(offlineMessageQueueProvider)
          .pendingFor(widget.conversation.id);
      _text.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível enviar. TENTAR NOVAMENTE')));
      }
    }
    if (mounted) {
      setState(() => _sending = false);
    }
  }

  Future<void> _retryPending() async {
    await ref.read(offlineMessageQueueProvider).flush();
    final pending = await ref
        .read(offlineMessageQueueProvider)
        .pendingFor(widget.conversation.id);
    if (!mounted) return;
    setState(() => _pendingOffline = pending);
    if (pending == 0) {
      ref.invalidate(conversationMessagesProvider(widget.conversation.id));
    }
  }

  Future<void> _discardPending() async {
    await ref
        .read(offlineMessageQueueProvider)
        .discardFor(widget.conversation.id);
    if (mounted) setState(() => _pendingOffline = 0);
  }

  Future<void> _messageMenu(ChatMessage message, bool mine) async {
    final action = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: const Text('RESPONDER'),
                  onTap: () => Navigator.pop(context, 'reply')),
              ListTile(
                  title: const Text('DENUNCIAR / SELECIONAR'),
                  onTap: () => Navigator.pop(context, 'report')),
              if (mine &&
                  DateTime.now().difference(message.sentAt).inMinutes < 1) ...[
                ListTile(
                    title: const Text('EDITAR'),
                    onTap: () => Navigator.pop(context, 'edit')),
                ListTile(
                    title: const Text('APAGAR'),
                    onTap: () => Navigator.pop(context, 'delete'))
              ]
            ])));
    if (action == 'reply') {
      setState(() {
        _replyToId = message.id;
        _replyPreview = message.body ?? 'Mídia';
      });
      return;
    }
    if (action == 'report') {
      setState(() {
        _reportMode = true;
        _reportSelection.add(message.id);
      });
      return;
    }
    if (action == 'delete') {
      await ref
          .read(conversationRepositoryProvider)
          .delete(widget.conversation.id, message.id);
      ref.invalidate(conversationMessagesProvider(widget.conversation.id));
      return;
    }
    if (action == 'edit') {
      final controller = TextEditingController(text: message.body);
      if (!mounted) {
        return;
      }
      final value = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
                  title: const Text('Editar mensagem'),
                  content: TextField(controller: controller, autofocus: true),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCELAR')),
                    TextButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text),
                        child: const Text('SALVAR'))
                  ]));
      if (!mounted) {
        return;
      }
      if (value != null && value.trim().isNotEmpty) {
        await ref
            .read(conversationRepositoryProvider)
            .edit(widget.conversation.id, message.id, value.trim());
        ref.invalidate(conversationMessagesProvider(widget.conversation.id));
      }
    }
  }

  Future<void> _submitReport() async {
    if (_reportSelection.isEmpty) return;
    try {
      await ref
          .read(conversationRepositoryProvider)
          .report(widget.conversation.id, _reportSelection.toList());
      if (!mounted) return;
      setState(() {
        _reportMode = false;
        _reportSelection.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DENÚNCIA ENVIADA PARA ANÁLISE')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível enviar. TENTAR NOVAMENTE')));
      }
    }
  }

  Future<void> _officialAction(String action) async {
    try {
      await ref
          .read(conversationRepositoryProvider)
          .officialAction(widget.conversation.id, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AÇÃO OFICIAL REGISTRADA')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível registrar. TENTAR NOVAMENTE')));
      }
    }
  }

  Future<void> _pickSticker() async {
    final stickers = await ref.read(conversationRepositoryProvider).stickers();
    if (!mounted) return;
    final selected = await showModalBottomSheet<ChatSticker>(
        context: context,
        builder: (_) => SafeArea(
            child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                children: stickers
                    .map((sticker) => InkWell(
                        onTap: () => Navigator.pop(context, sticker),
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.network(
                                '${ApiClient.baseUrl}${sticker.assetPath}',
                                fit: BoxFit.contain,
                                semanticLabel: sticker.label))))
                    .toList())));
    if (selected == null) return;
    _text.text = 'STICKER:${selected.id}';
    await _send();
  }

  String _uuid() {
    final bytes = List.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> _pickPhoto() async {
    final source = await _chooseMediaSource('FOTO');
    if (source == null) return;
    final image = await ImagePicker().pickImage(
        source: source, imageQuality: 82, maxWidth: 1280, maxHeight: 1280);
    if (image == null) return;
    if (await image.length() > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('A foto precisa ter no máximo 5 MB.')));
      }
      return;
    }
    try {
      final mediaId = await ref.read(mediaRepositoryProvider).uploadChatImage(
          widget.conversation.id, image, image.mimeType ?? 'image/jpeg');
      _mediaIds.add(mediaId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('FOTO ENVIADA')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível enviar a foto. TENTAR NOVAMENTE')));
      }
    }
  }

  Future<void> _pickVideo() async {
    final source = await _chooseMediaSource('VÍDEO');
    if (source == null) return;
    final video = await ImagePicker()
        .pickVideo(source: source, maxDuration: const Duration(seconds: 20));
    if (video == null) return;
    if (kIsWeb) {
      if (await video.length() > 15 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vídeo deve ter no máximo 15 MB.')));
        }
        return;
      }
      try {
        final id = await ref.read(mediaRepositoryProvider).uploadChatMedia(
            widget.conversation.id, video, video.mimeType ?? 'video/mp4',
            durationSeconds: 20);
        _mediaIds.add(id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Não foi possível enviar o vídeo.')));
        }
      }
      return;
    }
    final compressed = await VideoCompress.compressVideo(video.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true);
    if (compressed?.file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível compactar o vídeo.')));
      }
      return;
    }
    final file = compressed!.file!;
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      if (duration > 20 || await file.length() > 15 * 1024 * 1024) {
        throw StateError('limit');
      }
      final id = await ref.read(mediaRepositoryProvider).uploadChatMedia(
          widget.conversation.id, XFile(file.path), 'video/mp4',
          durationSeconds: duration);
      _mediaIds.add(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('VÍDEO PRONTO PARA ENVIAR')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vídeo deve ter no máximo 20 s e 15 MB.')));
      }
    } finally {
      controller.dispose();
    }
  }

  Future<ImageSource?> _chooseMediaSource(String label) =>
      showModalBottomSheet<ImageSource>(
          context: context,
          builder: (_) => SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: Text('TIRAR $label'),
                    onTap: () => Navigator.pop(context, ImageSource.camera)),
                ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('ESCOLHER DA GALERIA'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery))
              ])));

  Future<void> _sendFixedLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ative a localização para compartilhar.')));
      }
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      await ref.read(conversationRepositoryProvider).send(
          widget.conversation.id,
          ChatMessageDraft(_uuid(), '',
              kind: 'LOCATION',
              locationJson: jsonEncode({
                'latitude': position.latitude,
                'longitude': position.longitude,
                'mode': 'FIXED'
              })));
      ref.invalidate(conversationMessagesProvider(widget.conversation.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível compartilhar a localização.')));
      }
    }
  }

  Future<void> _chooseLocation() async {
    final minutes = await showModalBottomSheet<int>(
        context: context,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: const Text('LOCALIZAÇÃO FIXA'),
                  onTap: () => Navigator.pop(context, 0)),
              for (final value in [15, 30, 60])
                ListTile(
                    title: Text('AO VIVO POR $value MIN'),
                    onTap: () => Navigator.pop(context, value))
            ])));
    if (minutes == null) return;
    if (minutes == 0) return _sendFixedLocation();
    await _startLiveLocation(minutes);
  }

  Future<void> _startLiveLocation(int minutes) async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    await _liveLocationSubscription?.cancel();
    _liveLocationTimer?.cancel();
    final endsAt = DateTime.now().add(Duration(minutes: minutes));
    setState(() => _liveLocationEndsAt = endsAt);
    await ref.read(conversationRepositoryProvider).send(
        widget.conversation.id,
        ChatMessageDraft(_uuid(), '',
            kind: 'LOCATION',
            locationJson: jsonEncode(
                {'mode': 'LIVE', 'expiresAt': endsAt.toIso8601String()})));
    _liveLocationSubscription =
        Geolocator.getPositionStream().listen((position) {
      ref.read(stompClientProvider).sendLiveLocation(widget.conversation.id,
          position.latitude, position.longitude, endsAt);
    });
    _liveLocationTimer = Timer(Duration(minutes: minutes), _stopLiveLocation);
  }

  void _stopLiveLocation() {
    _liveLocationSubscription?.cancel();
    _liveLocationSubscription = null;
    _liveLocationTimer?.cancel();
    if (mounted) setState(() => _liveLocationEndsAt = null);
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: '${dir.path}/chat-${DateTime.now().millisecondsSinceEpoch}.m4a');
    if (mounted) {
      setState(() {
        _recording = true;
        _recordLocked = false;
        _recordCanceled = false;
        _recordingStartedAt = DateTime.now();
      });
    }
  }

  Future<void> _stopRecording({bool discard = false}) async {
    if (!_recording) return;
    final path = await _recorder.stop();
    final seconds = DateTime.now().difference(_recordingStartedAt!).inSeconds;
    if (mounted) {
      setState(() {
        _recording = false;
        _recordLocked = false;
        _recordingStartedAt = null;
      });
    }
    if (path == null || seconds > 120 || discard || _recordCanceled) {
      if (path != null && !kIsWeb) {
        await File(path).delete().catchError((_) => File(path));
      }
      return;
    }
    final file = XFile(path);
    if (await file.length() > 3 * 1024 * 1024) return;
    try {
      final id = await ref.read(mediaRepositoryProvider).uploadChatMedia(
          widget.conversation.id, file, 'audio/mp4',
          durationSeconds: seconds);
      _mediaIds.add(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ÁUDIO PRONTO PARA ENVIAR')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível enviar o áudio.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final me = ref.watch(authStateProvider).valueOrNull?.id;
    final messages =
        ref.watch(conversationMessagesProvider(widget.conversation.id));
    final historyStale = ref
        .read(conversationRepositoryProvider)
        .isHistoryStale(widget.conversation.id);
    return Scaffold(
        appBar: AppBar(
            actions: _reportMode
                ? [
                    IconButton(
                        tooltip: 'Cancelar seleção',
                        onPressed: () => setState(() {
                              _reportMode = false;
                              _reportSelection.clear();
                            }),
                        icon: const Icon(Icons.close)),
                    IconButton(
                        tooltip: 'Enviar denúncia',
                        onPressed:
                            _reportSelection.isEmpty ? null : _submitReport,
                        icon: const Icon(Icons.flag_outlined))
                  ]
                : widget.conversation.type == 'RIDE' &&
                        widget.conversation.otherUserId != null
                    ? [
                        IconButton(
                            tooltip: 'Bloquear usuário',
                            icon: const Icon(Icons.block_rounded),
                            onPressed: () async {
                              await ref.read(dioProvider).post(
                                  '/blocks/${widget.conversation.otherUserId}');
                              if (context.mounted) Navigator.of(context).pop();
                            })
                      ]
                    : null,
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.conversation.title.toUpperCase()),
              Text(
                  widget.conversation.type == 'OFFICIAL'
                      ? 'VJ//OFICIAL'
                      : 'VJ//RIDE_CHAT',
                  style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      color: scheme.tertiary))
            ])),
        body: Column(children: [
          if (widget.conversation.readOnly)
            Container(
                width: double.infinity,
                color: scheme.secondary,
                padding: const EdgeInsets.all(8),
                child: const Text('CONVERSA ENCERRADA • SOMENTE LEITURA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10))),
          if (widget.conversation.type == 'OFFICIAL')
            Wrap(spacing: 4, children: [
              TextButton(
                  onPressed: () => _officialAction('JUSTIFICAR'),
                  child: const Text('JUSTIFICAR')),
              TextButton(
                  onPressed: () => _officialAction('VER_CARONA'),
                  child: const Text('VER CARONA')),
              TextButton(
                  onPressed: () => _officialAction('AINDA_NAO_CHEGUEI'),
                  child: const Text('AINDA NÃO CHEGUEI')),
            ]),
          if (_otherTyping)
            const Padding(
                padding: EdgeInsets.all(8),
                child: Text('digitando...',
                    style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10))),
          if (_otherLiveLocation != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LOCALIZAÇÃO AO VIVO RECEBIDA',
                          style: TextStyle(
                              color: scheme.secondary,
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10)),
                      LocationActions(
                          json: jsonEncode({
                            'latitude': double.parse(
                                _otherLiveLocation!.split(',').first),
                            'longitude': double.parse(
                                _otherLiveLocation!.split(',').last)
                          }),
                          color: scheme.secondary)
                    ])),
          if (_liveLocationEndsAt != null)
            TextButton.icon(
                onPressed: _stopLiveLocation,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('ENCERRAR LOCALIZAÇÃO AO VIVO')),
          if (_pendingOffline > 0)
            Container(
                width: double.infinity,
                color: scheme.surface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  const Text('◉', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                          '$_pendingOffline mensagem(ns) aguardando conexão',
                          style: const TextStyle(
                              fontFamily: 'IBMPlexMono', fontSize: 10))),
                  TextButton(
                      onPressed: _retryPending,
                      child: const Text('TENTAR NOVAMENTE')),
                  IconButton(
                      tooltip: 'Apagar pendentes',
                      onPressed: _discardPending,
                      icon: const Icon(Icons.delete_outline, size: 18))
                ])),
          if (historyStale)
            const Padding(
                padding: EdgeInsets.all(6),
                child: Text('MOSTRANDO ÚLTIMO CONTEÚDO CARREGADO',
                    style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9))),
          Expanded(
              child: messages.when(
                  data: (items) => ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final message = items[i];
                        final mine = message.senderId == me;
                        final firstMedia =
                            message.media.isEmpty ? null : message.media.first;
                        final mediaUrl = firstMedia == null
                            ? null
                            : ref
                                .watch(mediaDownloadUrlProvider(firstMedia.id));
                        return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                                onTap: _reportMode
                                    ? () => setState(() {
                                          if (!_reportSelection
                                              .add(message.id)) {
                                            _reportSelection.remove(message.id);
                                          }
                                        })
                                    : null,
                                onHorizontalDragEnd: (details) {
                                  if (_reportMode ||
                                      details.primaryVelocity == null ||
                                      details.primaryVelocity! < 300) {
                                    return;
                                  }
                                  setState(() {
                                    _replyToId = message.id;
                                    _replyPreview = message.body ?? 'Mídia';
                                  });
                                },
                                onLongPress: () => _messageMenu(message, mine),
                                child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    constraints:
                                        const BoxConstraints(maxWidth: 300),
                                    decoration: NeoBrutal.decoration(
                                        color: mine
                                            ? scheme.primary
                                            : scheme.surface,
                                        borderColor: _reportSelection
                                                .contains(message.id)
                                            ? scheme.error
                                            : scheme.ink,
                                        radius: 3,
                                        offset: NeoBrutal.shadowOffsetSmall),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (message.adminSenderName != null)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4),
                                                child: Text(
                                                    'ADMIN • ${message.adminSenderName}',
                                                    style: TextStyle(
                                                        color: mine
                                                            ? Colors.white
                                                            : scheme.secondary,
                                                        fontFamily:
                                                            'IBMPlexMono',
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800))),
                                          if (!message.deleted &&
                                              (message.body ?? '')
                                                  .startsWith('STICKER:'))
                                            Image.network(
                                                '${ApiClient.baseUrl}/stickers/${message.body!.substring('STICKER:'.length)}/asset',
                                                width: 160,
                                                height: 160,
                                                fit: BoxFit.contain)
                                          else
                                            Text(
                                                message.deleted
                                                    ? 'MENSAGEM APAGADA'
                                                    : (message.body ??
                                                        'LOCALIZAÇÃO'),
                                                style: TextStyle(
                                                    color: mine
                                                        ? Colors.white
                                                        : scheme.ink)),
                                          if (!message.deleted &&
                                              message.editedAt != null)
                                            Text('EDITADA',
                                                style: TextStyle(
                                                    color: mine
                                                        ? Colors.white70
                                                        : scheme.secondary,
                                                    fontFamily: 'IBMPlexMono',
                                                    fontSize: 9)),
                                          if (message.kind == 'LOCATION' &&
                                              message.locationJson != null) ...[
                                            const SizedBox(height: 8),
                                            LocationActions(
                                                json: message.locationJson!,
                                                color: mine
                                                    ? Colors.white
                                                    : scheme.secondary)
                                          ],
                                          if (message.mediaIds.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            if (firstMedia != null &&
                                                firstMedia.isImage)
                                              mediaUrl!.when(
                                                  data: (url) => ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              3),
                                                      child: Image.network(url,
                                                          fit: BoxFit.cover,
                                                          height: 150,
                                                          width: 230,
                                                          errorBuilder: (_, __, ___) => SizedBox(
                                                              height: 150,
                                                              width: 230,
                                                              child: Center(
                                                                  child: TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              ref.invalidate(mediaDownloadUrlProvider(firstMedia.id)),
                                                                      child: const Text('RECARREGAR FOTO')))))),
                                                  loading: () => const SizedBox(height: 48, child: Center(child: Text('CARREGANDO FOTO...'))),
                                                  error: (_, __) => TextButton(onPressed: () => ref.invalidate(mediaDownloadUrlProvider(firstMedia.id)), child: const Text('TENTAR FOTO NOVAMENTE'))),
                                            if (firstMedia != null &&
                                                !firstMedia.isImage)
                                              InkWell(
                                                  onTap: () => mediaUrl?.whenData(
                                                      (url) => launchUrl(
                                                          Uri.parse(url),
                                                          mode: LaunchMode
                                                              .externalApplication)),
                                                  child: Row(children: [
                                                    Icon(
                                                        firstMedia.isVideo
                                                            ? Icons
                                                                .play_circle_outline
                                                            : Icons.mic_none,
                                                        color: mine
                                                            ? Colors.white
                                                            : scheme.secondary),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                        firstMedia.isVideo
                                                            ? 'VÍDEO ANEXADO'
                                                            : 'ÁUDIO ANEXADO',
                                                        style: TextStyle(
                                                            color: mine
                                                                ? Colors.white
                                                                : scheme
                                                                    .secondary,
                                                            fontFamily:
                                                                'IBMPlexMono',
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800))
                                                  ])),
                                            const SizedBox(height: 8),
                                            Text(
                                                '${message.mediaIds.length} ANEXO${message.mediaIds.length == 1 ? '' : 'S'}',
                                                style: TextStyle(
                                                    color: mine
                                                        ? Colors.white
                                                        : scheme.secondary,
                                                    fontFamily: 'IBMPlexMono',
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w800))
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                              _deliveryIndicator(message, mine),
                                              style: TextStyle(
                                                  color: mine
                                                      ? Colors.white
                                                      : scheme.secondary,
                                                  fontSize: 10))
                                        ]))));
                      }),
                  loading: () =>
                      const Center(child: Text('CARREGANDO MENSAGENS...')),
                  error: (_, __) => const Center(
                      child:
                          Text('Histórico indisponível. TENTAR NOVAMENTE')))),
          if (!widget.conversation.readOnly)
            SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      if (_replyToId != null)
                        Expanded(
                            child: Text('Respondendo: $_replyPreview',
                                maxLines: 1))
                      else
                        const SizedBox.shrink(),
                      IconButton(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.add_rounded)),
                      IconButton(
                          tooltip: 'Enviar vídeo',
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.video_library_outlined)),
                      IconButton(
                          tooltip: 'Figurinhas',
                          onPressed: _pickSticker,
                          icon: const Icon(Icons.emoji_emotions_outlined)),
                      IconButton(
                          tooltip: 'Enviar localização',
                          onPressed: _chooseLocation,
                          icon: const Icon(Icons.my_location_rounded)),
                      GestureDetector(
                          onLongPressStart: (_) => _startRecording(),
                          onLongPressMoveUpdate: (details) {
                            if (!_recording) return;
                            if (details.offsetFromOrigin.dy < -56) {
                              setState(() => _recordLocked = true);
                            }
                            if (details.offsetFromOrigin.dx < -80) {
                              setState(() => _recordCanceled = true);
                            }
                          },
                          onLongPressEnd: (_) {
                            if (!_recordLocked) {
                              _stopRecording(discard: _recordCanceled);
                            }
                          },
                          child: Icon(_recording
                              ? (_recordLocked ? Icons.lock : Icons.mic)
                              : Icons.mic_none)),
                      if (_recording && _recordLocked)
                        IconButton(
                            tooltip: 'Concluir áudio',
                            onPressed: _stopRecording,
                            icon: const Icon(Icons.send_rounded)),
                      Expanded(
                          child: TextField(
                              controller: _text,
                              maxLength: 4000,
                              onChanged: (value) => ref
                                  .read(stompClientProvider)
                                  .sendTyping(
                                      widget.conversation.id, value.isNotEmpty),
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: 'Escreva uma mensagem'))),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 92,
                          child: NeoButton(
                              onPressed: _sending ? null : _send,
                              child: Text(_sending ? '◉' : 'ENVIAR')))
                    ])))
        ]));
  }

  String _deliveryIndicator(ChatMessage message, bool mine) {
    if (!mine) return '○';
    if (message.readAt != null) return '●';
    if (message.deliveredAt != null) return '✓';
    return '◉';
  }
}
