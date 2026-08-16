import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final mediaRepositoryProvider =
    Provider((ref) => MediaRepository(ref.watch(dioProvider)));

class MediaRepository {
  MediaRepository(this._dio);
  final Dio _dio;
  Future<String> downloadUrl(String mediaId) async =>
      (await _dio.get('/media/$mediaId/download-url')).data['url'] as String;
  Future<String> uploadChatMedia(
      String conversationId, File file, String contentType,
      {int? durationSeconds}) async {
    final size = await file.length();
    final intent = await _dio.post('/media/upload-intents', data: {
      'category': 'CHAT',
      'conversationId': conversationId,
      'contentType': contentType,
      'sizeBytes': size,
      'durationSeconds': durationSeconds
    });
    final id = intent.data['id'] as String;
    final url = intent.data['uploadUrl'] as String;
    await Dio().put(url,
        data: file.openRead(),
        options: Options(
            headers: {'content-type': contentType, 'content-length': '$size'},
            contentType: contentType));
    await _dio.post('/media/$id/complete');
    return id;
  }

  Future<String> uploadChatImage(
          String conversationId, File file, String contentType) =>
      uploadChatMedia(conversationId, file, contentType);
}
