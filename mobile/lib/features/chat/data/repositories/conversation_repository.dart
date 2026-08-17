import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/conversation_model.dart';

final conversationRepositoryProvider = Provider((ref) => ConversationRepository(
    ref.watch(dioProvider), ref.watch(secureStorageProvider)));

class ConversationRepository {
  ConversationRepository(this._dio, this._storage);
  final Dio _dio;
  final SecureStorage _storage;
  final _historyCache = <String, List<ChatMessage>>{};
  final _staleHistories = <String>{};
  Future<List<ConversationModel>> list() async {
    final r = await _dio.get('/conversations');
    return (r.data as List)
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> messages(String id) async {
    try {
      final r = await _dio.get('/conversations/$id/messages');
      final result = (r.data as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      _historyCache[id] = result;
      await _storage.writePrivate('chat-history-$id', jsonEncode(r.data));
      _staleHistories.remove(id);
      return result;
    } catch (_) {
      final cached = _historyCache[id];
      if (cached != null) {
        _staleHistories.add(id);
        return cached;
      }
      final raw = await _storage.readPrivate('chat-history-$id');
      if (raw != null && raw.isNotEmpty) {
        final persisted = (jsonDecode(raw) as List)
            .map((item) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        _historyCache[id] = persisted;
        _staleHistories.add(id);
        return persisted;
      }
      rethrow;
    }
  }

  bool isHistoryStale(String conversationId) =>
      _staleHistories.contains(conversationId);

  Future<ChatMessage> send(String id, ChatMessageDraft draft) async {
    final r =
        await _dio.post('/conversations/$id/messages', data: draft.toJson());
    return ChatMessage.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ChatMessage> edit(
      String conversationId, String messageId, String body) async {
    final r = await _dio.patch(
        '/conversations/$conversationId/messages/$messageId',
        data: {'body': body});
    return ChatMessage.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String conversationId, String messageId) =>
      _dio.delete('/conversations/$conversationId/messages/$messageId');

  Future<String> report(String conversationId, List<String> messageIds) async {
    final response = await _dio.post('/conversations/$conversationId/reports',
        data: {'messageIds': messageIds});
    return response.data['id'] as String;
  }

  Future<void> officialAction(String conversationId, String action) =>
      _dio.post('/conversations/$conversationId/official-actions',
          data: {'action': action});

  Future<List<ChatSticker>> stickers() async =>
      ((await _dio.get('/stickers')).data as List)
          .map((item) => ChatSticker.fromJson(item as Map<String, dynamic>))
          .toList();
}

class ChatMessage {
  const ChatMessage(
      {required this.id,
      required this.clientId,
      required this.senderId,
      required this.kind,
      this.adminSenderName,
      this.body,
      this.locationJson,
      this.mediaIds = const [],
      this.media = const [],
      this.deliveredAt,
      this.readAt,
      this.editedAt,
      required this.sentAt,
      required this.deleted});
  final String id, clientId, kind;
  final String? senderId;
  final String? adminSenderName;
  final List<String> mediaIds;
  final List<ChatMedia> media;
  final String? body;
  final String? locationJson;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? editedAt;
  final DateTime sentAt;
  final bool deleted;
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
      id: j['id'] as String,
      clientId: j['clientId'] as String,
      senderId: j['senderId'] as String?,
      adminSenderName: j['adminSenderName'] as String?,
      kind: j['kind'] as String,
      body: j['body'] as String?,
      locationJson: j['locationJson'] as String?,
      mediaIds: (j['mediaIds'] as List? ?? const []).cast<String>(),
      media: (j['media'] as List? ?? const [])
          .map((media) => ChatMedia.fromJson(media as Map<String, dynamic>))
          .toList(),
      deliveredAt: j['deliveredAt'] == null
          ? null
          : DateTime.parse(j['deliveredAt'] as String),
      readAt:
          j['readAt'] == null ? null : DateTime.parse(j['readAt'] as String),
      editedAt: j['editedAt'] == null
          ? null
          : DateTime.parse(j['editedAt'] as String),
      sentAt: DateTime.parse(j['sentAt'] as String),
      deleted: j['deleted'] as bool? ?? false);
}

class ChatMedia {
  const ChatMedia({required this.id, required this.contentType});

  final String id;
  final String contentType;

  factory ChatMedia.fromJson(Map<String, dynamic> json) => ChatMedia(
        id: json['id'] as String,
        contentType: json['contentType'] as String,
      );

  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');
  bool get isAudio => contentType.startsWith('audio/');
}

class ChatSticker {
  const ChatSticker({required this.code, required this.label});
  final String code, label;
  factory ChatSticker.fromJson(Map<String, dynamic> json) =>
      ChatSticker(code: json['code'] as String, label: json['label'] as String);
}

class ChatMessageDraft {
  ChatMessageDraft(this.clientId, this.body,
      {this.mediaIds = const [],
      this.kind = 'TEXT',
      this.locationJson,
      this.replyToId});
  final String clientId, body, kind;
  final List<String> mediaIds;
  final String? locationJson;
  final String? replyToId;
  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'kind': kind,
        'body': body,
        'mediaIds': mediaIds,
        'locationJson': locationJson,
        'replyToId': replyToId
      };
}
