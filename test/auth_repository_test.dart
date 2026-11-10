import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/core/network/api_client.dart';
import 'package:revela/features/auth/data/auth_repository.dart';
import 'package:revela/features/auth/domain/auth_session.dart';

void main() {
  test('Envía el contrato real sin modificar la contraseña y lee el rol del JWT', () async {
    final jwt =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'usuario': 'demo', 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'Gestor'}))).replaceAll('=', '')}.signature';
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/Sesion');
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'usuario': 'demo',
          'clave': ' clave ',
        });
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          jsonEncode({
            'accessToken': jwt,
            'tokenType': 'bearer',
            'expiresIn': 3600,
            'empresaId': 1,
            'empresaNombre': 'Prueba',
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final session = await AuthRepository(api)
        .login(username: ' demo ', password: ' clave ');
    expect(session.role, 'Gestor');
    expect(session.username, 'demo');
    expect(session.isExpired, isFalse);
  });

  for (final code in [400, 401, 403, 429, 500]) {
    test('Traduce el error HTTP $code sin exponer datos de la API', () async {
      final api = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
        client: MockClient((_) async => http.Response('detalle interno', code)),
      );
      addTearDown(api.close);
      await expectLater(
        AuthRepository(api).login(username: 'demo', password: 'prueba'),
        throwsA(isA<AuthException>()),
      );
    });
  }

  test('Maneja timeout, errores de red y JSON inesperado', () async {
    for (final error in [
      TimeoutException(''),
      http.ClientException(''),
      const FormatException(''),
    ]) {
      final api = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
        client: MockClient((_) async => throw error),
      );
      addTearDown(api.close);
      await expectLater(
        AuthRepository(api).login(username: 'demo', password: 'prueba'),
        throwsA(isA<AuthException>()),
      );
    }
  });

  test('Rechaza respuesta vacía, token vacío y sesión ya vencida', () {
    expect(() => AuthSession.fromJson({}), throwsFormatException);
    final now = DateTime.utc(2026);
    final token =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'exp': now.subtract(const Duration(seconds: 1)).millisecondsSinceEpoch ~/ 1000})))}.signature';
    expect(
      () => AuthSession.fromJson({
        'accessToken': token,
        'tokenType': 'bearer',
        'expiresIn': 3600,
        'empresaId': 1,
        'empresaNombre': 'Prueba',
      }, now: now),
      throwsFormatException,
    );
  });
}
