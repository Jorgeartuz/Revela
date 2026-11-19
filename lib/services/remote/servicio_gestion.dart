import 'package:revela/models/reservas/horario_disponible.dart';

import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/valores_registro.dart';
import 'package:revela/models/inicio/reserva.dart';

class ErrorGestion implements Exception {
  const ErrorGestion(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ErrorClienteExistente extends ErrorGestion {
  const ErrorClienteExistente(this.cliente)
    : super(
        'Ya existe un cliente con este documento. Puedes consultar su ficha en lugar de registrarlo de nuevo.',
        statusCode: 409,
      );
  final Map<String, dynamic> cliente;
}

class ServicioGestion {
  ServicioGestion({
    required this.api,
    required this.sesion,
    this.alNoEstarAutorizado,
  });
  final ClienteApi api;
  final SesionUsuario sesion;
  final void Function()? alNoEstarAutorizado;
  void Function()? alIrAlInicio;
  void Function()? alCerrarSesion;
  void Function(int)? alCambiarPestanaProfesional;
  Map<String, int> get diasSemana => codigosDiasSemana();
  Map<String, int> get motivosInasistencia => codigosMotivosInasistencia();
  EstadosReserva get estadosReserva => EstadosReserva.configurados;

  Future<Object?> _solicitar(String method, String path, {Object? body}) async {
    if (sesion.estaVencida) {
      scheduleMicrotask(() => alNoEstarAutorizado?.call());
      throw const ErrorGestion('Tu sesión ha vencido. Inicia sesión de nuevo.');
    }
    try {
      final Object? response = await switch (method) {
        'POST' => api.post(path, body: body, token: sesion.tokenAcceso),
        'PUT' => api.put(path, body: body, token: sesion.tokenAcceso),
        'DELETE' => api.delete(path, body: body, token: sesion.tokenAcceso),
        _ => api.get(path, token: sesion.tokenAcceso),
      };
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] != true) {
          final mensaje = response['message'];
          throw ErrorGestion(
            (mensaje is String ? mensajeApiParaUsuario(mensaje) : null) ?? 'No se pudo completar la operación. Revisa los datos e inténtalo de nuevo.',
          );
        }
        return response['data'];
      }
      return response;
    } on ErrorApi catch (e) {
      if (e.statusCode == 401) {
        scheduleMicrotask(() => alNoEstarAutorizado?.call());
      }
      throw ErrorGestion(switch (e.statusCode) {
        401 => 'Tu sesión ha vencido. Inicia sesión de nuevo.',
        403 => 'Tu cuenta no tiene permiso para realizar esta operación.',
        409 =>
          e.message ??
              'Ya existe un registro con esos datos o el horario está ocupado.',
        400 || 422 =>
          e.message ?? 'Revisa los datos. El servicio no aceptó la solicitud.',
        _ => 'No se pudo completar la operación. Inténtalo nuevamente.',
      }, statusCode: e.statusCode);
    } on TimeoutException {
      throw const ErrorGestion(
        'La conexión tardó demasiado. Reintenta cuando vuelva a estar disponible.',
      );
    } on http.ClientException {
      throw const ErrorGestion(
        'No se pudo conectar. Revisa tu conexión a internet.',
      );
    } on FormatException {
      throw const ErrorGestion('No se pudo leer la respuesta del servicio.');
    }
  }

  Future<List<Map<String, dynamic>>> listar(
    ModuloGestion modulo, {
    Map<String, String> filtros = const {},
  }) async {
    final query = {...filtros};
    if (modulo == ModuloGestion.profesionales) {
      query.putIfAbsent('soloActivos', () => 'false');
    }
    final path = Uri(
      path: modulo.path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    final data = await _solicitar('GET', path);
    if (data is! List) {
      throw const ErrorGestion('El servicio no devolvió un listado válido.');
    }
    final registros = data.map((r) {
      if (r is! Map<String, dynamic>) {
        throw const ErrorGestion('El servicio devolvió un registro inválido.');
      }
      return r;
    }).toList();
    return filtrarRegistros(modulo, registros, filtros);
  }

  Future<Map<String, dynamic>?> obtenerProfesional(int id) async {
    final data = await _solicitar('GET', 'api/Profesionales/$id');
    if (data is! Map<String, dynamic> || data['id'] != id) {
      throw const ErrorGestion('No se pudo cargar el perfil del profesional.');
    }
    return data;
  }

  Future<Map<String, dynamic>?> guardar(
    ModuloGestion modulo,
    Map<String, dynamic> body, {
    int? id,
  }) async {
    final path = id == null
        ? (modulo == ModuloGestion.inasistencias
              ? '${modulo.path}/masivo'
              : modulo.path)
        : '${modulo.path}/$id';
    try {
      final data = await _solicitar(
        id == null ? 'POST' : 'PUT',
        path,
        body: body,
      );
      return data is Map<String, dynamic> ? data : null;
    } on ErrorGestion catch (error) {
      if (modulo == ModuloGestion.clientes &&
          id == null &&
          (error.statusCode == 400 ||
              error.statusCode == 409 ||
              error.statusCode == 422)) {
        final document = body['documento']?.toString().trim();
        if (document != null && document.isNotEmpty) {
          final existing = await _clienteExistente(document);
          if (existing != null) throw ErrorClienteExistente(existing);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _clienteExistente(String document) async {
    try {
      final data = await _solicitar(
        'GET',
        'api/Clientes/${Uri.encodeComponent(document)}',
      );
      final candidates = data is Map<String, dynamic>
          ? [data]
          : data is List
          ? data.whereType<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      return candidates
          .where(
            (r) =>
                r['id'] is int && r['documento']?.toString().trim() == document,
          )
          .firstOrNull;
    } on ErrorGestion {
      return null;
    }
  }

  Future<void> eliminar(
    ModuloGestion modulo,
    int id, {
    Map<String, dynamic>? body,
  }) async {
    await _solicitar('DELETE', '${modulo.path}/$id', body: body);
  }

  Future<List<Map<String, dynamic>>> serviciosDeComision(int id) async {
    final data = await _solicitar('GET', 'api/Comisiones/$id/servicios');
    if (data is! List) {
      throw const ErrorGestion('No se pudo cargar el detalle de comisión.');
    }
    return data.map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  Future<List<HorarioDisponible>> consultarDisponibilidad({
    required int serviceId,
    required DateTime date,
    int? idProfesional,
  }) async {
    final path = Uri(
      path: 'api/agenda',
      queryParameters: {
        'fecha': date.toIso8601String().split('T').first,
        'servicioId': '$serviceId',
        if (idProfesional != null) 'profesionalId': '$idProfesional',
      },
    ).toString();
    final datos = await _solicitar('GET', path);
    if (datos is! List) {
      throw const ErrorGestion('No se pudieron leer los horarios disponibles.');
    }
    try {
      final horarios =
          datos
              .map((dato) {
                if (dato is! Map<String, dynamic>) {
                  throw const FormatException();
                }
                return HorarioDisponible.fromJson(dato);
              })
              .where((horario) => horario.fecha.isAfter(DateTime.now()))
              .toList()
            ..sort((a, b) => a.fecha.compareTo(b.fecha));
      final fechas = <DateTime>{};
      return horarios.where((horario) => fechas.add(horario.fecha)).toList();
    } on FormatException {
      throw const ErrorGestion(
        'El centro devolvió un horario que no se pudo interpretar.',
      );
    }
  }
}
