import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/media_repository.dart';

final conversationsProvider = FutureProvider<List<ConversationModel>>(
    (ref) => ref.watch(conversationRepositoryProvider).list());
final conversationMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>(
        (ref, id) => ref.watch(conversationRepositoryProvider).messages(id));
final mediaDownloadUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, id) async {
  final link = await ref.watch(mediaRepositoryProvider).downloadUrl(id);
  final refreshIn = link.expiresAt
      .subtract(const Duration(minutes: 5))
      .difference(DateTime.now());
  final timer = Timer(refreshIn.isNegative ? Duration.zero : refreshIn,
      () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return link.url;
});
