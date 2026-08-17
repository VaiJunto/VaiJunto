import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_datetime.dart';
import '../../../core/ui/newsletter_embed.dart';

/// Leitura de uma newsletter administrativa. O conteúdo mora no servidor e é
/// buscado por id: a notificação carrega só o ponteiro, então uma newsletter
/// enviada para mil pessoas não vira mil cópias do corpo.
///
/// Não é respondível de propósito — para falar com a equipe existe o canal
/// administrativo, que é conversa de verdade.
class NewsletterScreen extends ConsumerStatefulWidget {
  const NewsletterScreen({super.key, required this.newsletterId});
  final String newsletterId;

  @override
  ConsumerState<NewsletterScreen> createState() => _NewsletterScreenState();
}

class _NewsletterScreenState extends ConsumerState<NewsletterScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final response =
        await ref.read(dioProvider).get('/newsletters/${widget.newsletterId}');
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('MENSAGEM')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              final message = error is DioException &&
                      error.response?.data is Map &&
                      (error.response!.data as Map)['message'] is String
                  ? (error.response!.data as Map)['message'] as String
                  : 'Não foi possível abrir esta mensagem.';
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(message, textAlign: TextAlign.center)));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: NewsletterEmbed(
                title: data['title']?.toString() ?? '',
                components: ((data['components'] as List?) ?? const [])
                    .map((item) => Map<String, dynamic>.from(item as Map))
                    .toList(),
                settings:
                    Map<String, dynamic>.from((data['settings'] as Map?) ?? const {}),
                sentAt: data['sentAt'] == null
                    ? null
                    : parseApiDateTime(data['sentAt']),
              ),
            );
          },
        ),
      );
}
