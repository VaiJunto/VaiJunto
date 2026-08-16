import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider =
    Provider((ref) => NotificationRepository(ref.watch(dioProvider)));

class NotificationRepository {
  NotificationRepository(this._dio);
  final Dio _dio;
  Future<List<AppNotification>> list() async {
    final response = await _dio.get('/notifications');
    return (response.data as List)
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) => _dio.put('/notifications/$id/read');
  Future<NotificationPreferences> preferences() async =>
      NotificationPreferences.fromJson(
          (await _dio.get('/notifications/preferences')).data
              as Map<String, dynamic>);
  Future<NotificationPreferences> updatePreferences(
          {bool? hideContent, bool? muteChat}) async =>
      NotificationPreferences.fromJson((await _dio.put(
              '/notifications/preferences',
              data: {'hideContent': hideContent, 'muteChat': muteChat}))
          .data as Map<String, dynamic>);
}

class NotificationPreferences {
  const NotificationPreferences(
      {required this.hideContent, required this.muteChat});
  final bool hideContent, muteChat;
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
          hideContent: json['hideContent'] as bool? ?? false,
          muteChat: json['muteChat'] as bool? ?? false);
}
