import '../../../../core/network/api_datetime.dart';

class ConversationModel {
  const ConversationModel(
      {required this.id,
      required this.type,
      required this.title,
      this.otherUserId,
      required this.archived,
      required this.readOnly,
      required this.lastActivityAt});
  final String id, type, title;
  final String? otherUserId;
  final bool archived, readOnly;
  final DateTime lastActivityAt;
  factory ConversationModel.fromJson(Map<String, dynamic> j) =>
      ConversationModel(
          id: j['id'] as String,
          type: j['type'] as String,
          title: j['title'] as String,
          otherUserId: j['otherUserId'] as String?,
          archived: j['archived'] as bool? ?? false,
          readOnly: j['readOnly'] as bool? ?? false,
          lastActivityAt: parseApiDateTime(j['lastActivityAt']));
}
