import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ClienteApi {
  ClienteApi({required Uri urlBase, http.Client? client})
    : _urlBase = urlBase,
      _clienteHttp = client ?? http.Client() {
    if (!urlBase.hasAuthority ||
        !['http', 'https'].contains(urlBase.scheme) ||
        urlBase.hasQuery ||
        urlBase.hasFragment ||
        urlBase.userInfo.isNotEmpty) {
      throw ArgumentError(
        'La URL base debe ser HTTP o HTTPS sin credenciales, parámetros ni fragmentos.',
      );
    }
  }

  final Uri _urlBase;
  final http.Client _clienteHttp;

  Future<Object?> get(String ruta, {String? token}) =>
      _enviar('GET', ruta, token: token);

  Future<Object?> post(String ruta, {Object? body, String? token}) =>
      _enviar('POST', ruta, body: body, token: token);

  Future<Object?> put(String ruta, {Object? body, String? token}) =>
      _enviar('PUT', ruta, body: body, token: token);

  Future<Object?> delete(String ruta, {Object? body, String? token}) =>
      _enviar('DELETE', ruta, body: body, token: token);

  Future<Object?> _enviar(
    String metodo,
    String ruta, {
    Object? body,
    String? token,
  }) async {
    final rutaRelativa = Uri.parse(ruta);
    if (rutaRelativa.hasScheme ||
        rutaRelativa.hasAuthority ||
        ruta.startsWith('/') ||
        rutaRelativa.pathSegments.contains('..') ||
        ruta.contains('\\')) {
      throw ArgumentError('Usa una ruta relativa a la URL base.');
    }

    final base = _urlBase.replace(
      path: _urlBase.path.endsWith('/') ? _urlBase.path : '${_urlBase.path}/',
    );
    final solicitud = http.Request(metodo, base.resolveUri(rutaRelativa));
    solicitud.headers['Accept'] = 'application/json';

    if (token != null) solicitud.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      solicitud.headers['Content-Type'] = 'application/json';
      solicitud.body = jsonEncode(body);
    }

    final respuesta = await _enviarYLeer(solicitud)
        .timeout(const Duration(seconds: 20));

    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      String? mensaje;
      try {
        final error = jsonDecode(utf8.decode(respuesta.bodyBytes));
        if (error is Map && error['message'] is String) {
          mensaje = mensajeApiParaUsuario(error['message'] as String);
        }
      } catch (_) {}
      throw ErrorApi(respuesta.statusCode, message: mensaje);
    }

    if (respuesta.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(respuesta.bodyBytes));
  }

  Future<http.Response> _enviarYLeer(http.Request solicitud) async {
    final respuestaEnPartes = await _clienteHttp.send(solicitud);
    return http.Response.fromStream(respuestaEnPartes);
  }

  void close() => _clienteHttp.close();
}

String? mensajeApiParaUsuario(String texto) {
  final mensaje = texto.trim();
  final minusculas = mensaje.toLowerCase();
  if (minusculas.contains('could not save changes') ||
      minusculas.contains('configure your entity type') ||
      minusculas.contains(
        'an error occurred while saving the entity changes',
      )) {
    return 'El servidor no pudo guardar el registro. Si los datos son correctos, contacta al administrador del centro.';
  }
  if (mensaje.isEmpty ||
      mensaje.length >= 350 ||
      [
        'exception',
        'stack',
        'dbcontext',
        'entityframework',
        'sqlstate',
        'sql server',
      ].any(minusculas.contains)) {
    return null;
  }
  return mensaje;
}

class ErrorApi implements Exception {
  const ErrorApi(this.statusCode, {this.message});
  final int statusCode;
  final String? message;
  @override
  String toString() => 'La API respondió con el código $statusCode.';
}
