import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/models/inicio/reserva.dart';

class ErrorInicio implements Exception {
  const ErrorInicio(this.message);
  final String message;
  @override
  String toString() => message;
}

class ServicioInicio {
  ServicioInicio(this.api, this.sesion, {this.alNoEstarAutorizado});
  final ClienteApi api;
  final SesionUsuario sesion;
  final void Function()? alNoEstarAutorizado;

  Future<List<Map<String, dynamic>>> _consultarListado(String path) async {
    if (sesion.estaVencida) {
      scheduleMicrotask(() => alNoEstarAutorizado?.call());
      throw const ErrorInicio('Tu sesión ha vencido.');
    }
    try {
      final result = await api.get(path, token: sesion.tokenAcceso);
      if (result is! Map<String, dynamic> ||
          result['success'] != true ||
          result['data'] is! List) {
        throw const FormatException('Respuesta de listado inválida.');
      }
      return (result['data'] as List).map((registro) {
        if (registro is! Map<String, dynamic>) {
          throw const FormatException('Registro inválido.');
        }
        return registro;
      }).toList();
    } on ErrorApi catch (error) {
      if (error.statusCode == 401) {
        alNoEstarAutorizado?.call();
      }
      throw ErrorInicio(
        error.statusCode == 403
            ? 'Tu cuenta no tiene acceso a esta información.'
            : error.statusCode == 401
            ? 'Tu sesión ha vencido.'
            : 'No se pudo cargar la información. Vuelve a intentar.',
      );
    } on TimeoutException {
      throw const ErrorInicio(
        'La conexión tardó demasiado. Vuelve a intentar.',
      );
    } on http.ClientException {
      throw const ErrorInicio(
        'Revisa tu conexión a internet e inténtalo de nuevo.',
      );
    } on FormatException {
      throw const ErrorInicio('No se pudo leer la información del servicio.');
    }
  }

  Future<ResumenDiario> cargarDia(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));
    final path = Uri(
      path: 'api/Reservas',
      queryParameters: {
        'FechaInicio': start.toIso8601String(),
        'FechaFin': end.toIso8601String(),
      },
    ).toString();
    final registros = await _consultarListado(path);
    try {
      return ResumenDiario(registros.map(Reserva.fromJson), start);
    } on FormatException {
      throw const ErrorInicio('No se pudieron leer las reservas.');
    } on TypeError {
      throw const ErrorInicio('No se pudieron leer las reservas.');
    }
  }
}
