import 'package:revela/models/login/solicitud_inicio_sesion.dart';

import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/models/login/sesion_usuario.dart';

class ServicioAutenticacion {
  ServicioAutenticacion(this._clienteApi);
  final ClienteApi _clienteApi;

  Future<SesionUsuario> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    try {
      final respuesta = await _clienteApi.post(
        'api/Sesion',
        body: SolicitudInicioSesion(
          usuario: usuario,
          contrasena: contrasena,
        ).toJson(),
      );
      if (respuesta is! Map<String, dynamic>) {
        throw const FormatException('Respuesta de sesión inválida.');
      }
      return SesionUsuario.fromJson(respuesta);
    } on ErrorApi catch (error) {
      final mensaje = switch (error.statusCode) {
        400 || 401 => 'El usuario o la contraseña no son correctos.',
        403 => 'Tu cuenta no tiene acceso. Consulta con el administrador.',
        429 =>
          'Hay demasiados intentos. Espera un momento y vuelve a intentar.',
        >= 500 => 'El servicio no está disponible. Inténtalo más tarde.',
        _ => 'No se pudo iniciar sesión. Inténtalo nuevamente.',
      };
      throw ErrorAutenticacion(mensaje);
    } on TimeoutException {
      throw const ErrorAutenticacion(
        'La conexión tardó demasiado. Vuelve a intentar.',
      );
    } on http.ClientException {
      throw const ErrorAutenticacion(
        'No se pudo conectar. Revisa tu conexión a internet.',
      );
    } on FormatException {
      throw const ErrorAutenticacion(
        'No se pudo validar la respuesta del servicio. Inténtalo más tarde.',
      );
    }
  }
}

class ErrorAutenticacion implements Exception {
  const ErrorAutenticacion(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}
