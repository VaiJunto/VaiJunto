import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';

final mediaRepositoryProvider =
    Provider((ref) => MediaRepository(ref.watch(dioProvider)));

class MediaRepository {
  MediaRepository(this._dio);
  final Dio _dio;
  Future<MediaDownloadLink> downloadUrl(String mediaId) async {
    final data = (await _dio.get('/media/$mediaId/download-url')).data as Map;
    return MediaDownloadLink(
      data['url'] as String,
      DateTime.parse(data['expiresAt'] as String).toLocal(),
    );
  }

  Future<String> uploadChatMedia(
      String conversationId, XFile file, String contentType,
      {int? durationSeconds}) async {
    return _uploadChatMedia(conversationId, file, contentType,
        durationSeconds: durationSeconds, retries: 1);
  }

  Future<String> _uploadChatMedia(
      String conversationId, XFile file, String contentType,
      {int? durationSeconds, required int retries}) async {
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
    try {
      final put = await Dio().put(url,
          data: file.openRead(),
          options: Options(
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 300,
              headers: {'content-type': contentType, 'content-length': '$size'},
              contentType: contentType));
      if (put.statusCode == null ||
          put.statusCode! < 200 ||
          put.statusCode! >= 300) {
        throw DioException.badResponse(
            statusCode: put.statusCode ?? 500,
            requestOptions: put.requestOptions,
            response: put);
      }
      await _dio.post('/media/$id/complete');
      return id;
    } on DioException {
      if (retries <= 0) rethrow;
      return _uploadChatMedia(conversationId, file, contentType,
          durationSeconds: durationSeconds, retries: retries - 1);
    }
  }

  Future<String> uploadChatImage(
          String conversationId, XFile file, String contentType) =>
      uploadChatMedia(conversationId, file, contentType);
}

class MediaDownloadLink {
  const MediaDownloadLink(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;
}
