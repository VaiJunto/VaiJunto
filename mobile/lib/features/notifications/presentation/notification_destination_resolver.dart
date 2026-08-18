import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/app_snackbar.dart';
import '../../chat/data/repositories/conversation_repository.dart';
import '../../chat/presentation/screens/conversation_screen.dart';
import '../../demands/data/repositories/demand_repository.dart';
import '../../trips/data/repositories/trip_repository.dart';
import '../data/models/notification_model.dart';
import 'newsletter_screen.dart';

class NotificationDestinationResolver {
  const NotificationDestinationResolver._();

  static Map<String, dynamic> decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<bool> navigateNotification(
      BuildContext context, WidgetRef ref, AppNotification notification) {
    return navigate(context, ref, <String, dynamic>{
      ...decodePayload(notification.payload),
      'type': notification.type,
    });
  }

  static Future<bool> navigate(
      BuildContext context, WidgetRef ref, Map<String, dynamic> data) async {
    final target = data['targetType']?.toString() ?? _inferTarget(data);
    try {
      switch (target) {
        case 'CONVERSATION':
          final id = data['conversationId']?.toString();
          if (id == null) return _invalid(context);
          final conversations =
              await ref.read(conversationRepositoryProvider).list();
          if (!context.mounted) return true;
          final matches = conversations.where((item) => item.id == id);
          if (matches.isEmpty) {
            return _unavailable(
                context, 'Esta conversa não está mais disponível.');
          }
          if (context.mounted) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ConversationScreen(conversation: matches.first),
            ));
          }
          return true;
        case 'NEWSLETTER':
          final id = data['newsletterId']?.toString();
          if (id == null) return _invalid(context);
          if (context.mounted) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => NewsletterScreen(newsletterId: id),
            ));
          }
          return true;
        case 'TRIP':
          final id = data['tripId']?.toString();
          if (id == null) return _invalid(context);
          final trips = await ref.read(tripRepositoryProvider).mine();
          if (!context.mounted) return true;
          final matches = trips.where((trip) => trip.id == id);
          if (matches.isEmpty) {
            return _unavailable(
                context, 'Esta carona não está mais disponível.');
          }
          if (context.mounted) {
            await showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                      title: const Text('DETALHES DA CARONA'),
                      content: Text(
                          '${matches.first.status}\n${matches.first.scheduledDeparture}'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('FECHAR'))
                      ],
                    ));
          }
          return true;
        case 'DEMAND':
          final id = data['demandId']?.toString();
          if (id == null) {
            return _unavailable(
                context, 'Abra Minhas caronas para acompanhar seus pedidos.');
          }
          final demands =
              await ref.read(demandRepositoryProvider).getMyDemands();
          if (!context.mounted) return true;
          final matches = demands.where((demand) => demand.id == id);
          if (matches.isEmpty) {
            return _unavailable(
                context, 'Este pedido não está mais disponível.');
          }
          if (context.mounted) {
            await showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                      title: const Text('PEDIDO DE CARONA'),
                      content: Text(
                          '${matches.first.originName} → ${matches.first.destinationName}\n${matches.first.status}'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('FECHAR'))
                      ],
                    ));
          }
          return true;
        case 'SETTINGS':
        case 'HOME':
          return _unavailable(
              context, 'Confira esta atualização no aplicativo.');
        default:
          return _invalid(context);
      }
    } catch (_) {
      if (!context.mounted) return false;
      return _unavailable(
          context, 'Não foi possível abrir este conteúdo. Tente novamente.');
    }
  }

  static String _inferTarget(Map<String, dynamic> data) {
    if (data['conversationId'] != null) return 'CONVERSATION';
    if (data['tripId'] != null) return 'TRIP';
    if (data['demandId'] != null) return 'DEMAND';
    if (data['newsletterId'] != null) return 'NEWSLETTER';
    return 'HOME';
  }

  static bool _invalid(BuildContext context) {
    if (context.mounted) {
      AppSnackbar.info(
          context, 'Esta notificação não possui um destino válido.');
    }
    return false;
  }

  static bool _unavailable(BuildContext context, String message) {
    if (context.mounted) AppSnackbar.info(context, message);
    return true;
  }
}
