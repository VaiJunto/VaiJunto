import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage.dart';
import '../repositories/conversation_repository.dart';

final offlineMessageQueueProvider = Provider((ref) => OfflineMessageQueue(
    ref.watch(secureStorageProvider),
    ref.watch(conversationRepositoryProvider)));

class OfflineMessageQueue {
  OfflineMessageQueue(this._storage, this._repository);
  final SecureStorage _storage;
  final ConversationRepository _repository;
  static const _key = 'pending_chat_messages_v1';

  Future<void> enqueue(String conversationId, ChatMessageDraft draft) async {
    final items = await _read();
    items.add({'conversationId': conversationId, ...draft.toJson()});
    await _storage.writePrivate(_key, jsonEncode(items));
  }

  Future<void> flush() async {
    final remaining = <Map<String, dynamic>>[];
    for (final item in await _read()) {
      try {
        await _repository.send(
          item['conversationId'] as String,
          ChatMessageDraft(
            item['clientId'] as String,
            item['body'] as String,
            kind: item['kind'] as String? ?? 'TEXT',
            mediaIds: List<String>.from(item['mediaIds'] as List? ?? const []),
            locationJson: item['locationJson'] as String?,
            replyToId: item['replyToId'] as String?,
          ),
        );
      } catch (_) {
        remaining.add(item);
      }
    }
    await _storage.writePrivate(_key, jsonEncode(remaining));
  }

  Future<int> pendingFor(String conversationId) async => (await _read())
      .where((item) => item['conversationId'] == conversationId)
      .length;

  Future<void> discardFor(String conversationId) async {
    final remaining = (await _read())
        .where((item) => item['conversationId'] != conversationId)
        .toList();
    await _storage.writePrivate(_key, jsonEncode(remaining));
  }

  Future<List<Map<String, dynamic>>> _read() async {
    final raw = await _storage.readPrivate(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
