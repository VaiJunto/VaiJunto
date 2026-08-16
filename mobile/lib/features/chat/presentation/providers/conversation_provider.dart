import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/media_repository.dart';

final conversationsProvider = FutureProvider<List<ConversationModel>>(
    (ref) => ref.watch(conversationRepositoryProvider).list());
final conversationMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>(
        (ref, id) => ref.watch(conversationRepositoryProvider).messages(id));
final mediaDownloadUrlProvider = FutureProvider.family<String, String>(
    (ref, id) => ref.watch(mediaRepositoryProvider).downloadUrl(id));
