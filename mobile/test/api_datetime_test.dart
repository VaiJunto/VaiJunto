import 'package:flutter_test/flutter_test.dart';
import 'package:vaijunto/core/network/api_datetime.dart';

void main() {
  test('data local enviada à API sempre inclui offset UTC', () {
    final localDate = DateTime(2026, 8, 13, 12, 51, 27, 601);

    final serialized = formatApiDateTime(localDate);

    expect(serialized, endsWith('Z'));
    expect(DateTime.parse(serialized).isUtc, isTrue);
    expect(DateTime.parse(serialized), localDate.toUtc());
    expect(parseApiDateTime(serialized), localDate);
  });
}
