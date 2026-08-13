/// Serializa datas para o contrato HTTP do backend.
///
/// O Spring recebe `OffsetDateTime`, portanto a string precisa carregar um
/// offset. Um `DateTime` local usa ISO 8601 sem offset; converter para UTC
/// garante o sufixo `Z` e preserva o instante escolhido pelo usuário.
String formatApiDateTime(DateTime value) => value.toUtc().toIso8601String();

/// Converte o instante devolvido pela API para o fuso do aparelho antes de a
/// interface extrair hora e data.
DateTime parseApiDateTime(String value) => DateTime.parse(value).toLocal();
