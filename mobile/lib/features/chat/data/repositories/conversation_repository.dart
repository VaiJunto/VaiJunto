import 'package:dio/dio.dart'; import 'package:flutter_riverpod/flutter_riverpod.dart'; import '../../../../core/network/api_client.dart'; import '../models/conversation_model.dart';
final conversationRepositoryProvider=Provider((ref)=>ConversationRepository(ref.watch(dioProvider)));
class ConversationRepository { ConversationRepository(this._dio); final Dio _dio; Future<List<ConversationModel>> list() async {final r=await _dio.get('/conversations');return (r.data as List).map((e)=>ConversationModel.fromJson(e as Map<String,dynamic>)).toList();}}
