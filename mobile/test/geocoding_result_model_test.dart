import 'package:flutter_test/flutter_test.dart';
import 'package:vaijunto/core/geocoding/geocoding_result_model.dart';

void main() {
  test('interpreta sugestão regional enriquecida pelo backend', () {
    final result = GeocodingResult.fromJson({
      'displayName': 'Rua das Flores, Jardim Satélite, São José dos Campos',
      'primaryText': 'Rua das Flores',
      'secondaryText': 'Jardim Satélite • São José dos Campos • SP',
      'latitude': -23.22,
      'longitude': -45.89,
      'distanceKm': 8.4,
    });

    expect(result.primaryText, 'Rua das Flores');
    expect(result.secondaryText, contains('São José dos Campos'));
    expect(result.distanceLabel, '8 km da Fatec');
  });

  test('mantém compatibilidade com resposta antiga do backend', () {
    final result = GeocodingResult.fromJson({
      'displayName': 'Rua das Flores, São José dos Campos',
      'latitude': -23.22,
      'longitude': -45.89,
    });

    expect(result.primaryText, result.displayName);
    expect(result.secondaryText, isEmpty);
  });
}
