import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _api.post(
        'api/Sesion',
        body: {'usuario': username.trim(), 'clave': password},
      );
      if (result is! Map<String, dynamic>) {
        throw const FormatException('Respuesta de sesión inválida.');
      }
      return AuthSession.fromJson(result);
    } on ApiException catch (error) {
      final message = switch (error.statusCode) {
        400 || 401 => 'El usuario o la contraseña no son correctos.',
        403 => 'Tu cuenta no tiene acceso. Consulta con el administrador.',
        429 =>
          'Hay demasiados intentos. Espera un momento y vuelve a intentar.',
        >= 500 => 'El servicio no está disponible. Inténtalo más tarde.',
        _ => 'No se pudo iniciar sesión. Inténtalo nuevamente.',
      };
      throw AuthException(message);
    } on TimeoutException {
      throw const AuthException(
        'La conexión tardó demasiado. Vuelve a intentar.',
      );
    } on http.ClientException {
      throw const AuthException(
        'No se pudo conectar. Revisa tu conexión a internet.',
      );
    } on FormatException {
      throw const AuthException(
        'No se pudo validar la respuesta del servicio. Inténtalo más tarde.',
      );
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
