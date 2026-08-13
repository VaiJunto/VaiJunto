import '../models/location_model.dart';

/// Câmpus fixo para o MVP: todo pedido de carona ou rota publicada tem a
/// Fatec como origem ou destino (nunca as duas coisas ao mesmo tempo).
///
/// Coordenadas geocodificadas via Nominatim a partir do endereço oficial
/// (Av. Cesare Monsueto Giulio Lattes, 1350, Eugênio de Melo, São José dos
/// Campos - SP). Quando o app precisar suportar mais de um câmpus, isto vira
/// uma consulta à tabela `universities` (hoje vazia) em vez de uma constante.
const String kFatecName = 'FATEC São José dos Campos - Prof. Jessen Vidal';

final LocationModel kFatecLocation = LocationModel(
  latitude: -23.1623356,
  longitude: -45.7954102,
);
