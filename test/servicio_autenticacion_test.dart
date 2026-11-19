import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/services/remote/servicio_autenticacion.dart';
import 'package:revela/models/login/sesion_usuario.dart';

void main() {
  test('Envía el contrato real sin modificar la contraseña y lee el rol del JWT', () async {
    final jwt =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'usuario': 'demo', 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'Gestor'}))).replaceAll('=', '')}.signature';
    final api = ClienteApi(
      urlBase: Uri.parse('https://example.com'),
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
    final sesion = await ServicioAutenticacion(api)
        .iniciarSesion(usuario: ' demo ', contrasena: ' clave ');
    expect(sesion.rol, 'Gestor');
    expect(sesion.usuario, 'demo');
    expect(sesion.estaVencida, isFalse);
  });

  for (final code in [400, 401, 403, 429, 500]) {
    test('Traduce el error HTTP $code sin exponer datos de la API', () async {
      final api = ClienteApi(
        urlBase: Uri.parse('https://example.com'),
        client: MockClient((_) async => http.Response('detalle interno', code)),
      );
      addTearDown(api.close);
      await expectLater(
        ServicioAutenticacion(api)
            .iniciarSesion(usuario: 'demo', contrasena: 'prueba'),
        throwsA(isA<ErrorAutenticacion>()),
      );
    });
  }

  test('Maneja timeout, errores de red y JSON inesperado', () async {
    for (final error in [
      TimeoutException(''),
      http.ClientException(''),
      const FormatException(''),
    ]) {
      final api = ClienteApi(
        urlBase: Uri.parse('https://example.com'),
        client: MockClient((_) async => throw error),
      );
      addTearDown(api.close);
      await expectLater(
        ServicioAutenticacion(api)
            .iniciarSesion(usuario: 'demo', contrasena: 'prueba'),
        throwsA(isA<ErrorAutenticacion>()),
      );
    }
  });

  test('Rechaza respuesta vacía, token vacío y sesión ya vencida', () {
    expect(() => SesionUsuario.fromJson({}), throwsFormatException);
    final now = DateTime.utc(2026);
    final token =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'exp': now.subtract(const Duration(seconds: 1)).millisecondsSinceEpoch ~/ 1000})))}.signature';
    expect(
      () => SesionUsuario.fromJson({
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
