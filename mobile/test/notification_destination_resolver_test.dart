import 'package:flutter_test/flutter_test.dart';
import 'package:vaijunto/features/notifications/presentation/notification_destination_resolver.dart';

void main() {
  test('decodifica destino completo da notificacao', () {
    final payload = NotificationDestinationResolver.decodePayload(
      '{"targetType":"CONVERSATION","conversationId":"abc"}',
    );
    expect(payload['targetType'], 'CONVERSATION');
    expect(payload['conversationId'], 'abc');
  });

  test('payload invalido nao derruba a navegacao', () {
    expect(NotificationDestinationResolver.decodePayload('{invalido'), isEmpty);
  });
}
