import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// No contiene rutas ni esquemas de autenticación supuestos.
/// Adaptar al contrato real de la API cuando esté disponible.
class ApiClient {
  ApiClient({required Uri baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client() {
    if (!baseUrl.hasAuthority ||
        !['http', 'https'].contains(baseUrl.scheme) ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment ||
        baseUrl.userInfo.isNotEmpty) {
      throw ArgumentError(
        'La URL base debe ser HTTP o HTTPS sin credenciales, parámetros ni fragmentos.',
      );
    }
  }

  final Uri _baseUrl;
  final http.Client _client;

  Future<Object?> get(String path, {String? token}) =>
      _send('GET', path, token: token);

  Future<Object?> post(String path, {Object? body, String? token}) =>
      _send('POST', path, body: body, token: token);

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final relative = Uri.parse(path);
    if (relative.hasScheme ||
        relative.hasAuthority ||
        path.startsWith('/') ||
        relative.pathSegments.contains('..') ||
        path.contains('\\')) {
      throw ArgumentError('Usa una ruta relativa a la URL base.');
    }
    final base = _baseUrl.replace(
      path: _baseUrl.path.endsWith('/') ? _baseUrl.path : '${_baseUrl.path}/',
    );
    final request = http.Request(method, base.resolveUri(relative));
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    // El tiempo límite abarca tanto cabeceras como cuerpo de respuesta.
    final response = await (() async => http.Response.fromStream(
      await _client.send(request),
    ))().timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode);
    }
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.statusCode);
  final int statusCode;
  @override
  String toString() => 'La API respondió con el código $statusCode.';
}
