import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(const FlutterSecureStorage());
});

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage(this._storage);

  static const String _tokenKey = 'jwt_token';
  static const String _adminTokenKey = 'admin_jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _deviceIdKey = 'device_id';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveAdminToken(String token) async =>
      _storage.write(key: _adminTokenKey, value: token);

  Future<String?> getAdminToken() async => _storage.read(key: _adminTokenKey);

  Future<void> deleteAdminToken() async => _storage.delete(key: _adminTokenKey);

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> writePrivate(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> readPrivate(String key) => _storage.read(key: key);

  /// Limpa a sessão (token/userId) no logout, mas preserva o [deviceId] —
  /// ele identifica o aparelho, não a sessão. Se ele fosse apagado aqui, todo
  /// logout/login de novo pareceria "primeiro acesso" e pediria o código de
  /// e-mail (MFA de device) de novo, mesmo sendo o mesmo celular.
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  /// Identificador estável deste device, gerado uma vez e reaproveitado em
  /// todo login subsequente — é o que o backend usa para saber se este é um
  /// device já conhecido daquele usuário ou se precisa do desafio por e-mail.
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _generateUuidV4();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // versão 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variante RFC 4122

    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20, 32)}';
  }
}
