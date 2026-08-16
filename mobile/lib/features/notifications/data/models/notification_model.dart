import '../../../../core/network/api_datetime.dart';

class AppNotification {
  const AppNotification(
      {required this.id,
      required this.type,
      required this.title,
      required this.body,
      required this.isRead,
      required this.createdAt});
  final String id, type;
  final String? title, body;
  final bool isRead;
  final DateTime createdAt;
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
          id: json['id'] as String,
          type: json['type'] as String,
          title: json['title'] as String?,
          body: json['body'] as String?,
          isRead: json['isRead'] as bool? ?? false,
          createdAt: parseApiDateTime(json['createdAt']));
}
